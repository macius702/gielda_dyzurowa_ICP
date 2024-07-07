use std::cmp::Reverse;
use std::collections::HashMap;

use crate::{assign_duty_slot_by_id, delete_user_internal, get_all_usernames_internal, give_consent_to_duty_slot_by_id, revoke_assignment_from_duty_slot_by_id, TokenData, UserRole};
use crate::{
    delete_duty_slot_by_id, get_duty_slot_by_id, get_user_by_id, jwt::JWT, USED_TOKENS_HEAP,
    USED_TOKENS_MAP,
};
use candid;
use candid::de::IDLDeserialize;
use candid::ser::IDLBuilder;
use candid::{CandidType, Deserialize};
use cookie::{Cookie, SameSite};
use ic_cdk::println;
use pluto::{
    http::{HttpRequest, HttpResponse, HttpServe},
    router::Router,
};
use serde_json::{json, Value};
use time::macros::format_description;
use time::{OffsetDateTime, PrimitiveDateTime, UtcOffset};

// for display private HeaderField fields
#[derive(CandidType, Deserialize, Clone, Debug)]
pub struct MyHeaderField(pub String, pub String);

use crate::specialties::SPECIALTIES_STRINGS;
use crate::types::PublishDutySlotRequest;
use crate::DutySlot;
use crate::DutyStatus;
use crate::User;
use crate::{
    find_user_by_username, get_all_duty_slots_internal, get_all_users_internal,
    insert_duty_slot_internal, insert_user_internal,
};

//define  a global u32 constant
pub const TODO_SESSION_USER_ID: u32 = 1;

use ring::digest;
use ring::pbkdf2;

static PBKDF2_ALG: pbkdf2::Algorithm = pbkdf2::PBKDF2_HMAC_SHA256;
const CREDENTIAL_LEN: usize = digest::SHA256_OUTPUT_LEN;
type Credential = [u8; CREDENTIAL_LEN];

fn hash_password_with_pbkdf2(password: &str, salt: &[u8]) -> Credential {
    let mut credential = [0u8; CREDENTIAL_LEN];
    pbkdf2::derive(
        PBKDF2_ALG,
        std::num::NonZeroU32::new(10000).unwrap(),
        salt,
        password.as_bytes(),
        &mut credential,
    );
    credential
}

pub(crate) fn setup() -> Router {
    let mut router = Router::new();

    router.put("/:value", true, |req: HttpRequest| async move {
        println!("Hello World from PUT {:?}", req.params.get("value"));

        Ok(HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: json!({
                "statusCode": 200,
                "message": "Hello World from PUT",
                "paramValue": req.params.get("value")
            })
            .into(),
        })
    });
    router.post("/", true, |req: HttpRequest| async move {
        ic_cdk::println!("println from POST {:?}", req.params.get("value"));

        let received_body: Result<String, HttpResponse> = String::from_utf8(req.body)
            .map_err(|_| HttpServe::internal_server_error().unwrap_err());
        Ok(HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: json!({
                "statusCode": 200,
                "message": "Hello World from POST",
                "receivedBody": received_body?
            })
            .into(),
        })
    });

    router.get("/duty/slots/json", false, |_: HttpRequest| async move {
        println!("Hello World from GET /duty/slots/json");
        println!("Duty slots: {:?}", get_all_duty_slots_internal());

        //respond with json using duty_slots
        Ok(HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: json!(crate::get_all_duty_slots_for_display()).into(),
        })
    });

    router.post("/duty/publish", true, |req: HttpRequest| async move {
        let user_info = match get_authorized_user_info(&req) {
            Ok(user_info) => user_info,
            Err(response) => return Ok(response),
        };
        let (userid, userrole, username) = user_info;
        if userrole != "hospital" {
            return Ok(HttpResponse {
                status_code: 403,
                headers: HashMap::new(),
                body: json!({
                    "statusCode": 403,
                    "message": "Only hospitals can publish duty slots"
                })
                .into(),
            });
        }
        assert_eq!(userrole, "hospital");

        let body_string = String::from_utf8(req.body.clone()).unwrap();
        println!("Received body: {}", body_string);
        let publish_duty_slot_request: PublishDutySlotRequest =
            serde_json::from_str(&body_string).unwrap();
        println!("Deserialized request: {:?}", publish_duty_slot_request);

        let start_date_time_str = format!(
            "{} {}",
            publish_duty_slot_request.startDate, publish_duty_slot_request.startTime
        );
        println!("1 Start date time: {}", start_date_time_str);
        let start_date_time = convert_to_unix_timestamp(&start_date_time_str);
        println!("2 Start date time: {}", start_date_time);

        let end_date_time = format!(
            "{} {}",
            publish_duty_slot_request.endDate, publish_duty_slot_request.endTime
        );
        println!("1 End date time: {}", end_date_time);
        let end_date_time = convert_to_unix_timestamp(&end_date_time);
        println!("2 End date time: {}", end_date_time);

        let duty_slot = DutySlot {
            required_specialty: publish_duty_slot_request
                .requiredSpecialty
                ._id
                .parse::<u16>()
                .unwrap(),
            hospital_id: userid,
            start_date_time: start_date_time,
            end_date_time: end_date_time,
            price_from: publish_duty_slot_request.priceFrom,
            price_to: publish_duty_slot_request.priceTo,
            currency: publish_duty_slot_request.currency,
            status: DutyStatus::open,
            assigned_doctor_id: None,
        };

        let key = insert_duty_slot_internal(duty_slot);

        Ok(HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: json!({
                "statusCode": 200,
                "message": "Duty slot published",
                "key": key
            })
            .into(),
        })
    });

    router.post("/duty/remove", true, |req: HttpRequest| async move {
        let user_info = match get_authorized_user_info(&req) {
            Ok(user_info) => user_info,
            Err(response) => return Ok(response),
        };
        let (userid, userrole, username) = user_info;
        if userrole != "hospital" {
            return Ok(HttpResponse {
                status_code: 403,
                headers: HashMap::new(),
                body: json!({
                    "statusCode": 403,
                    "message": "Only hospitals can remove duty slots"
                })
                .into(),
            });
        }
        assert_eq!(userrole, "hospital");

        let body_string = String::from_utf8(req.body.clone()).unwrap();
        println!("Received body: {}", body_string);

        let data: serde_json::Value = serde_json::from_str(&body_string).unwrap();
        println!("Parsed data: {:?}", data);

        let duty_slot_id = match data["_id"].as_str() {
            Some(id_str) => match id_str.parse::<u32>() {
                Ok(id) => id,
                Err(_) => {
                    let response = HttpResponse {
                        status_code: 400,
                        headers: HashMap::new(),
                        body: json!({
                            "statusCode": 400,
                            "message": "Cannot parse _id to u32"
                        })
                        .into(),
                    };
                    return Ok(response);
                }
            },
            None => {
                let response = HttpResponse {
                    status_code: 400,
                    headers: HashMap::new(),
                    body: json!({
                        "statusCode": 400,
                        "message": "_id does not exist or is not a string"
                    })
                    .into(),
                };
                return Ok(response);
            }
        };

        let duty_slot = get_duty_slot_by_id(duty_slot_id);

        // handle duty slot not found with match
        let duty_slot = match duty_slot {
            Some(duty_slot) => duty_slot,
            None => {
                return Ok(HttpResponse {
                    status_code: 404,
                    headers: HashMap::new(),
                    body: json!({
                        "statusCode": 404,
                        "message": "Duty slot not found"
                    })
                    .into(),
                });
            }
        };

        if duty_slot.hospital_id != userid {
            return Ok(HttpResponse {
                status_code: 403,
                headers: HashMap::new(),
                body: json!({
                    "statusCode": 403,
                    "message": "Hospital can only remove its own duty slots"
                })
                .into(),
            });
        }

        // take the duty slot id and remove it from the duty slots
        let removed_duty_slot = delete_duty_slot_by_id(duty_slot_id);
        println!("Removed duty slot: {:?}", removed_duty_slot);

        Ok(HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: json!({}).into(),
        })
    });

    async fn change_duty_slot_status(req: HttpRequest, user_role: &str, action: fn(u32, u32)) -> Result<HttpResponse, HttpResponse> {
        let user_info = match get_authorized_user_info(&req) {
            Ok(user_info) => user_info,
            Err(response) => return Err(response),
        };
        let (userid, userrole, username) = user_info;
        if userrole != user_role {
            return Err(HttpResponse {
                status_code: 403,
                headers: HashMap::new(),
                body: json!({
                    "statusCode": 403,
                    "message": "Only hospitals can remove duty slots"
                })
                .into(),
            });
        }
        assert_eq!(userrole, user_role);

        let body_string = String::from_utf8(req.body.clone()).unwrap();
        println!("Received body: {}", body_string);

        let data: serde_json::Value = serde_json::from_str(&body_string).unwrap();
        println!("Parsed data: {:?}", data);

        let duty_slot_id = match data["_id"].as_str() {
            Some(id_str) => match id_str.parse::<u32>() {
                Ok(id) => id,
                Err(_) => {
                    let response = HttpResponse {
                        status_code: 400,
                        headers: HashMap::new(),
                        body: json!({
                            "statusCode": 400,
                            "message": "Cannot parse _id to u32"
                        })
                        .into(),
                    };
                    return Err(response);
                }
            },
            None => {
                let response = HttpResponse {
                    status_code: 400,
                    headers: HashMap::new(),
                    body: json!({
                        "statusCode": 400,
                        "message": "_id does not exist or is not a string"
                    })
                    .into(),
                };
                return Err(response);
            }
        };

        let duty_slot = get_duty_slot_by_id(duty_slot_id);

        // handle duty slot not found with match
        let duty_slot = match duty_slot {
            Some(duty_slot) => duty_slot,
            None => {
                return Err(HttpResponse {
                    status_code: 404,
                    headers: HashMap::new(),
                    body: json!({
                        "statusCode": 404,
                        "message": "Duty slot not found"
                    })
                    .into(),
                });
            }
        };

        // take the duty slot id and change its status to accepted
        action(duty_slot_id, userid);
        print!(
            "Accepted duty slot: {:?} for doctor with id: {}",
            duty_slot, userid
        );

        Ok(HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: json!({}).into(),
        })
    }

    router.post("/assign-duty-slot", true, |req: HttpRequest| async move {
        change_duty_slot_status(req, "doctor", assign_duty_slot_by_id).await
    });

    router.post("/give-consent", true, |req: HttpRequest| async move {
        change_duty_slot_status(req, "hospital", give_consent_to_duty_slot_by_id).await
    });

    router.post("/revoke-assignment", true, |req: HttpRequest| async move {
        change_duty_slot_status(req, "doctor", revoke_assignment_from_duty_slot_by_id).await
    });
    


    router.options("/auth/register", true, |_req: HttpRequest| async move {
        Ok(HttpResponse {
            status_code: 200,
            headers: {
                let mut headers = HashMap::new();
                headers.insert(
                    String::from("Access-Control-Allow-Origin"),
                    String::from("*"),
                );
                headers.insert(
                    String::from("Access-Control-Allow-Methods"),
                    String::from("POST, OPTIONS"),
                );
                headers.insert(
                    String::from("Access-Control-Allow-Headers"),
                    String::from("Content-Type"),
                );
                headers
            },
            body: "".to_string().into(),
        })
    });
    
    router.post("/auth/register", true, |req: HttpRequest| async move {
        // req body has fields : username, password, role, specialty, localization
        let body_string = String::from_utf8(req.body.clone()).unwrap();
        println!("Received body: {}", body_string); // Debug print
        #[derive(serde::Deserialize, Debug)]
        struct UserDeserialize {
            username: String,
            password: String,
            role: String,
            specialty: Option<String>,
            localization: Option<String>,
            email: Option<String>,
            phone_number: Option<String>,
        }
        let user_deserialize: UserDeserialize = serde_json::from_str(&body_string).unwrap();
        println!("Deserialized user: {:?}", user_deserialize); // Debug print
        let mut user = User {
            username: user_deserialize.username,
            password: user_deserialize.password,
            role: user_deserialize.role.parse().unwrap_or(UserRole::doctor),
            localization: user_deserialize.localization,
            specialty: user_deserialize
                .specialty
                .as_ref()
                .and_then(|s| s.parse::<u16>().ok()),
            email: user_deserialize.email,
            phone_number: user_deserialize.phone_number,
        };

        // hash the passworf using pbkdf2
        println!("Before hashing password");

        let salt_string = "your_salt_string";
        let hashed_password = hex::encode(hash_password_with_pbkdf2(
            &user.password,
            salt_string.as_bytes(),
        ));
        println!("After hashing password: {}", hashed_password);
        user.password = hashed_password;
        println!("Parsed user: {:?}", user); // Debug print
        let key = insert_user_internal(user);
        println!("Inserted user with key: {:?}", key); // Debug print

        if key == 0 {
            return Ok(HttpResponse {
                status_code: 400,
                headers: {
                    let mut headers = HashMap::new();
                    headers.insert(
                        String::from("Access-Control-Allow-Origin"),
                        String::from("*"),
                    );
                    headers
                },
                body: json!({
                    "statusCode": 400,
                    "message": "Cannot register a new user, the user already exists"
                })
                .into(),
            });
        }

        Ok(HttpResponse {
            status_code: 200,
            headers: {
                let mut headers = HashMap::new();
                headers.insert(
                    String::from("Access-Control-Allow-Origin"),
                    String::from("*"),
                );
                //headers.insert(String::from("Access-Control-Allow-Origin"), String::from("http://example.com"));
                headers.insert(
                    String::from("Access-Control-Allow-Methods"),
                    String::from("POST, OPTIONS"),
                );
                headers.insert(
                    String::from("Access-Control-Allow-Headers"),
                    String::from("Content-Type"),
                );
                headers
            },
            body: json!({
                "statusCode": 200,
                "message": "User registered",
                "key": key
            })
            .into(),
        })
    });

    router.post("/auth/delete_user", true, |req: HttpRequest| async move {
        let user_info = match get_authorized_user_info(&req) {
            Ok(user_info) => user_info,
            Err(response) => return Ok(response),
        };
        let (userid, _, _) = user_info;

        delete_user_internal(userid);

        Ok(HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: json!({}).into(),
        })
    });



router.options("/auth/login", true, |_req: HttpRequest| async move {
    Ok(HttpResponse {
        status_code: 200,
        headers: {
            let mut headers = HashMap::new();
            headers.insert(String::from("Access-Control-Allow-Origin"), String::from("*"));
            headers.insert(String::from("Access-Control-Allow-Methods"), String::from("POST, OPTIONS"));
            headers.insert(String::from("Access-Control-Allow-Headers"), String::from("Content-Type"));
            headers
        },
        body: "".to_string().into(),
    })
});    
    router.post("/auth/login", true, move |req: HttpRequest| async move {
        // Log the full incoming request
        println!(
            "Incoming Request: method = {}, url = {}",
            req.method, req.url
        );
        // Parse the request body
        let body_string = String::from_utf8(req.body.clone()).unwrap();

        println!("Incoming Request Body: {}", body_string);

        let data: serde_json::Value = serde_json::from_str(&body_string).unwrap();
        let username = data["username"].as_str().unwrap();
        let password = data["password"].as_str().unwrap();

        println!("Parsed Username: {}", username);
        println!("Parsed Password: {}", password);

        // Find the user
        let user_result = find_user_by_username(username);

        match user_result {
            None => {
                println!("Login attempt: User not found");
                // Send response with status 400
                Ok(HttpResponse {
                    status_code: 400,
                    headers: HashMap::new(),
                    body: json!({
                        "statusCode": 400,
                        "message": "Invalid username or password"
                    })
                    .into(),
                })
            }
            Some((id, user)) => {
                // Check the password
                let hashed_password = hex::encode(hash_password_with_pbkdf2(
                    password,
                    "your_salt_string".as_bytes(),
                ));

            if user.password == hashed_password {
                    println!("User logged in: {}", user.username);

                    let payload =
                        json!({ "userId": id, "role": user.role, "username": user.username });
                    let secret = user.password;
                    let token = JWT::sign(payload, &secret, 3600);

                    let mut token_cookie = Cookie::new("token", token);
                    let mut userid_cookie = Cookie::new("userid", id.to_string());

                    let token_cookie_string = token_cookie.to_string();
                    let userid_cookie_string = userid_cookie.to_string();

                    let cookies = format!("{}, {}", userid_cookie_string, token_cookie_string);

                    let mut response = HttpResponse {
                        status_code: 200,
                        headers: HashMap::new(),
                        body: json!({
                            "statusCode": 200,
                            "message": "User logged in",
                            "username": user.username // TODO - is it needed?
                        })
                        .into(),
                    };

                    response.add_raw_header("Set-Cookie", cookies);
                    response.add_raw_header("Access-Control-Allow-Origin", String::from("*"));
                    response.add_raw_header("Access-Control-Allow-Methods", String::from("POST, OPTIONS"));
                    response.add_raw_header("Access-Control-Allow-Headers", String::from("Content-Type"));
            

                    Ok(response)
                } else {
                    println!("Login attempt failed for user: {}", username);
                    // Send response with status 400
                    Ok(HttpResponse {
                        status_code: 400,
                        headers: HashMap::new(),
                        body: json!({
                            "statusCode": 400,
                            "message": "Invalid username or password"
                        })
                        .into(),
                    })
                }
            }
        }
    });

    router.get("/auth/logout", true, |req: HttpRequest| async move {
        let user_info = match get_authorized_user_info(&req) {
            Ok(user_info) => user_info,
            Err(response) => return Ok(response),
        };
        let (userid, userrole, username) = user_info;

        add_to_used_tokens(req);

        Ok(HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: json!({}).into(),
        })
    });


    router.options("/user/data", true, |_req: HttpRequest| async move {
        Ok(HttpResponse {
            status_code: 200,
            headers: {
                let mut headers = HashMap::new();
                headers.insert(String::from("Access-Control-Allow-Origin"), String::from("*"));
                headers.insert(String::from("Access-Control-Allow-Methods"), String::from("GET, OPTIONS"));
                headers.insert(String::from("Access-Control-Allow-Headers"), String::from("Content-Type"));
                headers
            },
            body: "".to_string().into(),
        })
    });    

    router.get("/user/data", false, |req: HttpRequest| async move {
        let user_info = match get_authorized_user_info(&req) {
            Ok(user_info) => user_info,
            Err(response) => return Ok(response),
        };
        let (userid, userrole, username) = user_info;

        let mut response =  HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: json!({
                "statusCode": 200,
                "_id": userid,
                "role": userrole
            })
            .into(),
        };

        // response.add_raw_header("Set-Cookie", cookies);
        response.add_raw_header("Access-Control-Allow-Origin", String::from("*"));
        response.add_raw_header("Access-Control-Allow-Methods", String::from("GET, OPTIONS"));
        response.add_raw_header("Access-Control-Allow-Headers", String::from("Content-Type"));


        Ok(response)
    });

    router.get("/users", false, |_: HttpRequest| async move {
        println!("Hello World from GET /users");
        println!("Users: {:?}", get_all_users_internal());

        //respond with json using users
        Ok(HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: json!({
                "statusCode": 200,
                "message": "Hello World from GET /users",
                "users": get_all_users_internal()
            })
            .into(),
        })
    });

    router.get("/usernames", false, |_: HttpRequest| async move {
        println!("Hello World from GET /usernames");
        println!("Users: {:?}", get_all_usernames_internal());

        //respond with json using users
        Ok(HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: json!({
                "statusCode": 200,
                "message": "Hello World from GET /usernames",
                "usernames": get_all_usernames_internal()
            })
            .into(),
        })
    });

    router.get("/specialties", false, |_: HttpRequest| async move {
        println!("Received a request at GET /specialties");

        let specialties: Vec<_> = SPECIALTIES_STRINGS
            .iter()
            .enumerate()
            .map(|(i, &name)| {
                json!({
                    "_id": format!("{:04}", i),
                    "name": name,
                    "__v": 0
                })
            })
            .collect();

        println!("Specialties: {:?}", specialties);

        let response = HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: serde_json::to_string(&specialties).unwrap().into(),
        };

        println!("Responding with status code: {}", response.status_code);
        println!("Response body: {:?}", response.body);
        Ok(response)
    });
    router
}

fn extract_cookies_from_request(req: &HttpRequest) -> Option<(String, String)> {
    let mut token = None;
    let mut userid = None;

    for header in req.headers.iter() {
        // serialize header to Candid, and deserialize to MyHeaderField
        let mut serializer = IDLBuilder::new();
        serializer.arg(&header).unwrap();
        let candid_message = serializer.serialize_to_vec().unwrap();

        let mut deserializer = IDLDeserialize::new(&candid_message).unwrap();
        let header_field: MyHeaderField = deserializer.get_value().unwrap();

        if header_field.0 == "cookie" {
            let cookies = header_field.1.split(',').map(|s| s.trim());
            for cookie_str in cookies {
                let (token, userid) = parse_cookie(cookie_str);
                // Do something with token and userid
            }     
        }
    }
    match (token, userid) {
        (Some(t), Some(u)) => Some((t, u)),
        _ => None,
    }
}

fn parse_cookie(cookie_str: &str) -> (Option<String>, Option<String>) {
    println!("Parsing cookies: {}", cookie_str);
    let cookies: Vec<&str> = cookie_str.split(',').collect();
    let mut token = None;
    let mut userid = None;

    for cookie_str in cookies {
        let cookie = Cookie::parse(cookie_str.trim()).unwrap();
        match cookie.name() {
            "token" => {
                token = Some(cookie.value().to_string());
                println!("Found token: {}", token.as_ref().unwrap());
            }
            "userid" => {
                userid = Some(cookie.value().to_string());
                println!("Found userid: {}", userid.as_ref().unwrap());
            }
            _ => {
                println!("Found unrecognized cookie name: {}", cookie.name());
            }
        }
    }

    println!("Returning token: {:?}, userid: {:?}", token, userid);
    (token, userid)
}

fn unauthorized_response(message: &str) -> HttpResponse {
    HttpResponse {
        status_code: 401,
        headers: HashMap::new(),
        body: json!({
            "statusCode": 401,
            "message": message
        })
        .into(),
    }
}

fn convert_to_unix_timestamp(date_time_str: &str) -> i64 {
    let format = format_description!("[year]-[month]-[day] [hour]:[minute]");
    let date_time = PrimitiveDateTime::parse(date_time_str, &format)
        .expect("Failed to parse date_time_str as datetime");
    let date_time = date_time.assume_offset(UtcOffset::UTC);
    date_time.unix_timestamp()
}

pub fn convert_from_unix_timestamp(unix_timestamp: i64) -> String {
    let format = format_description!("[year]-[month]-[day]T[hour]:[minute]:00.000Z");
    let date_time = OffsetDateTime::from_unix_timestamp(unix_timestamp);

    match date_time {
        Ok(dt) => {
            match dt.format(format) {
                Ok(formatted_datetime) => formatted_datetime,
                Err(e) => {
                    eprintln!("An error occurred: {}", e);
                    String::new() // return an empty string in case of an error
                }
            }
        }
        Err(e) => {
            eprintln!("An error occurred: {}", e);
            String::new() // return an empty string in case of an error
        }
    }
}

fn extract_user_info(payload: &Value) -> (u32, &str, &str) {
    let user_id = payload["userId"].as_u64().unwrap() as u32;
    let user_role = payload["role"].as_str().unwrap();
    let user_username = payload["username"].as_str().unwrap();

    (user_id, user_role, user_username)
}

fn get_authorized_user_info(req: &HttpRequest) -> Result<(u32, String, String), HttpResponse> {
    let token_userid_pair = extract_cookies_from_request(req);

    let token_userid_pair = match token_userid_pair {
        Some(token_userid_pair) => token_userid_pair,
        None => return Err(unauthorized_response("No token found in request")),
    };

    let (token, userid) = token_userid_pair;

    if is_in_used_tokens(&token) {
        return Err(unauthorized_response("Token already used"));
    }

    let user = get_user_by_id(userid.parse().unwrap());
    let secret = user.password;
    let result = JWT::verify(&token, &secret);

    let payload = match result {
        Ok(Some(payload)) => payload,
        _ => return Err(unauthorized_response("Failed to verify token")),
    };

    let (user_id, user_role, user_username) = extract_user_info(&payload);

    Ok((user_id, user_role.to_string(), user_username.to_string()))
}

fn get_authorized_user_info_from_cookie(cookie : &str) -> Result<(u32, String, String), &str>{
    println!("Cookie: {}", cookie);
    let token_userid_pair = parse_cookie(&cookie);
    println!("Token user id pair: {:?}", token_userid_pair);
    let (token, userid) = token_userid_pair;
    println!("Token: {:?}", token);
    println!("User id: {:?}", userid);

    if token.is_none() || userid.is_none() {
        return Err("No token found in request");
    }

    let token = token.unwrap();
    let userid = userid.unwrap();

    if is_in_used_tokens(&token) {
        return Err("Token already used");
    }

    let user = get_user_by_id(userid.parse().unwrap());
    let secret = user.password;
    let result = JWT::verify(&token, &secret);

    let payload = match result {
        Ok(Some(payload)) => payload,
        _ => return Err("Failed to verify token"),
    };

    let (user_id, user_role, user_username) = extract_user_info(&payload);

    Ok((user_id, user_role.to_string(), user_username.to_string()))
}

fn add_token_to_used(token: String) {
    let now = ic_cdk::api::time();
    USED_TOKENS_MAP.with(|p| p.borrow_mut().insert(token.clone(), now));
    USED_TOKENS_HEAP.with(|p| {
        p.borrow_mut().push(TokenData {
            create_time: Reverse(now),
            token,
        })
    });
}

fn add_to_used_tokens(req: HttpRequest) {
    remove_expired_tokens();
    let token_userid_pair = extract_cookies_from_request(&req);
    let token_userid_pair = match token_userid_pair {
        Some(token_userid_pair) => token_userid_pair,
        None => return,
    };
    let (token, _) = token_userid_pair;
    add_token_to_used(token);
}

fn add_to_used_tokens_from_cookie(cookie : &str) {
    remove_expired_tokens();
    let token_userid_pair = parse_cookie(cookie);
    let (token, _) = token_userid_pair;
    let token = match token {
        Some(token) => token,
        None => return,
    };
    add_token_to_used(token);
}

fn remove_expired_tokens() {
    let now = ic_cdk::api::time();
    let one_hour_ago = now - 3600_000_000_000;
    USED_TOKENS_HEAP.with(|heap| {
        let mut heap = heap.borrow_mut();
        while let Some(token_data) = heap.peek() {
            if token_data.create_time.0 < one_hour_ago {
                let token_data = heap.pop().unwrap();
                USED_TOKENS_MAP.with(|map| {
                    map.borrow_mut().remove(&token_data.token);
                });
            } else {
                break;
            }
        }
    });
}

fn is_in_used_tokens(token: &String) -> bool {
    USED_TOKENS_MAP.with(|p| p.borrow().contains_key(token))
}

#[ic_cdk_macros::update]
async fn perform_registration(
    username: String, 
    password: String, 
    role: UserRole, 
    specialty: Option<i32>, 
    localization: Option<String>
) -> u32 {
    let mut  user = User {
        username,
        password,
        role,
        specialty: specialty.map(|s| s as u16),
        localization,
        email: None,
        phone_number: None,
    };

    // hash the passworf using pbkdf2
    println!("Before hashing password");

    let salt_string = "your_salt_string";
    let hashed_password = hex::encode(hash_password_with_pbkdf2(
        &user.password,
        salt_string.as_bytes(),
    ));
    println!("After hashing password: {}", hashed_password);
    user.password = hashed_password;
    println!("Parsed user: {:?}", user); // Debug print
    let key = insert_user_internal(user);
    println!("Inserted user with key: {:?}", key); // Debug print

    // if key == 0 {
    //     return Ok(HttpResponse {
    //         status_code: 400,
    //         headers: {
    //             let mut headers = HashMap::new();
    //             headers.insert(
    //                 String::from("Access-Control-Allow-Origin"),
    //                 String::from("*"),
    //             );
    //             headers
    //         },
    //         body: json!({
    //             "statusCode": 400,
    //             "message": "Cannot register a new user, the user already exists"
    //         })
    //         .into(),
    //     });
    // }

    

    key
}

#[ic_cdk_macros::query]
async fn perform_login(username: String, password: String) -> Result<String, String> {
    // Find the user
    let user_result = find_user_by_username(&username);

    match user_result {
        None => {
            println!("Login attempt: User not found");
            // Send response with status 400
            return Err("Invalid username or password".to_string());
        }
        Some((id , user)) => {
            // Check the password
            let hashed_password = hex::encode(hash_password_with_pbkdf2(
                &password,
                "your_salt_string".as_bytes(),
            ));

            if user.password == hashed_password {
                println!("User logged in: {}", user.username);

                let payload =
                    json!({ "userId": id, "role": user.role, "username": user.username });
                let secret = user.password;
                let token = JWT::sign(payload, &secret, 3600);

                let token_cookie = Cookie::new("token", token);
                let userid_cookie = Cookie::new("userid", id.to_string());

                let token_cookie_string = token_cookie.to_string();
                let userid_cookie_string = userid_cookie.to_string();

                let cookies = format!("{}, {}", userid_cookie_string, token_cookie_string);


                Ok(cookies)
            } else {
                println!("Login attempt failed for user: {}", username);
                // Send response with status 400
                return Err("Invalid username or password".to_string());
            }
        }
    }
}

// #[ic_cdk_macros::query]
// fn perform_logout(username: String) {
//     let user_info = match get_authorized_user_info(&req) {
//         Ok(user_info) => user_info,
//         Err(response) => return Ok(response),
//     };
//     let (userid, userrole, username) = user_info;

//     add_to_used_tokens(req);

//     Ok(HttpResponse {
//         status_code: 200,
//         headers: HashMap::new(),
//         body: json!({}).into(),
//     })
// }

// router.get("/user/data", false, |req: HttpRequest| async move {
//     let user_info = match get_authorized_user_info(&req) {
//         Ok(user_info) => user_info,
//         Err(response) => return Ok(response),
//     };
//     let (userid, userrole, username) = user_info;

//     let mut response =  HttpResponse {
//         status_code: 200,
//         headers: HashMap::new(),
//         body: json!({
//             "statusCode": 200,
//             "_id": userid,
//             "role": userrole
//         })
//         .into(),
//     };

//     // response.add_raw_header("Set-Cookie", cookies);
//     response.add_raw_header("Access-Control-Allow-Origin", String::from("*"));
//     response.add_raw_header("Access-Control-Allow-Methods", String::from("GET, OPTIONS"));
//     response.add_raw_header("Access-Control-Allow-Headers", String::from("Content-Type"));


//     Ok(response)
// });

#[ic_cdk_macros::query]
async fn get_user_data(cookie : String) -> Result<(u32, String), String> {
    let user_info = get_authorized_user_info_from_cookie(&cookie)?;
    let (userid, userrole, _) = user_info;

    Ok((userid, userrole))
}

#[ic_cdk_macros::query]
async fn perform_logout(cookie : String) -> Result<(), String> {
    println!("Performing logout for cookie: {}", cookie);
    let user_info = get_authorized_user_info_from_cookie(&cookie);

    match user_info {
        Err(e) => {
            println!("Error getting user info: {}", e);
            return Err(e.to_string())
        },
        _ => {}
    }

    println!("Adding used tokens from cookie");
    add_to_used_tokens_from_cookie(&cookie);

    println!("Logout successful");
    Ok(())
}

#[ic_cdk_macros::update]
async fn delete_user(cookie : String) -> Result<(), String> {
    println!("Deleting user for cookie: {}", cookie);
    let user_info = get_authorized_user_info_from_cookie(&cookie);

    match user_info {
        Err(e) => {
            println!("Error getting user info: {}", e);
            return Err(e.to_string())
        },
        _ => {}
    }

    let (userid, _, _) = user_info.unwrap();
    println!("Deleting user with id: {}", userid);
    delete_user_internal(userid);

    println!("User deletion successful");
    Ok(())
}

