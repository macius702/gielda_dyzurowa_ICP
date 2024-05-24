use std::collections::HashMap;


use ic_cdk::println;
use pluto::{
    http::{HttpRequest, HttpResponse, HttpServe},
    router::Router,
};
use serde_json::{json, Value};
use candid::ser::IDLBuilder;
use candid;
use candid::de::IDLDeserialize;
use candid::{CandidType, Deserialize};
use cookie::{Cookie, SameSite};
use crate::jwt::JWT;
use crate::UserRole;
use maplit::hashmap;
use time::{PrimitiveDateTime, UtcOffset};
use time::macros::format_description;




// for display private HeaderField fields
#[derive(CandidType, Deserialize, Clone, Debug)]
pub struct MyHeaderField(pub String, pub String);

use crate::{find_user_by_username, get_all_duty_slots_internal, get_all_users_internal, insert_duty_slot_internal, insert_user_internal};
use crate::DutySlot;
use crate::DutyStatus;
use crate::types::PublishDutySlotRequest;
use crate::User;
use crate::specialties::SPECIALTIES_STRINGS;

//define  a global u32 constant 
pub const TODO_SESSION_USER_ID: u32 = 1;




use ring::pbkdf2;
use ring::digest;

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
            body: json!({
                "statusCode": 200,
                "message": "Hello World from GET /duty/slots/json",
                "dutySlots": get_all_duty_slots_internal()
            })
            .into(),
        })
    });

    router.post("/duty/publish", true, |req: HttpRequest| async move {
    let body_string = String::from_utf8(req.body.clone()).unwrap();
    println!("Received body: {}", body_string);
    let publish_duty_slot_request: PublishDutySlotRequest = serde_json::from_str(&body_string).unwrap();
    println!("Deserialized request: {:?}", publish_duty_slot_request);

// use time::OffsetDateTime;

// let unix_timestamp: i64 = 1615866792; // Replace with your Unix timestamp
// let date_time = OffsetDateTime::from_unix_timestamp(unix_timestamp);
// let date_time = match date_time {
//     Ok(date_time) => date_time,
//     Err(_) => return Err(HttpResponse {
//         status_code: 400,
//         headers: HashMap::new(),
//         body: json!({
//             "statusCode": 400,
//             "message": "Invalid date time"
//         })
//         .into(),
//     }),
// };



    let start_date_time_str = format!("{} {}", publish_duty_slot_request.startDate, publish_duty_slot_request.startTime);
    println!("1 Start date time: {}", start_date_time_str);
    let start_date_time = convert_to_unix_timestamp(&start_date_time_str);
    println!("2 Start date time: {}", start_date_time);

    let end_date_time = format!("{} {}", publish_duty_slot_request.endDate, publish_duty_slot_request.endTime);
    println!("1 End date time: {}", end_date_time);
    let end_date_time = convert_to_unix_timestamp(&end_date_time);
    println!("2 End date time: {}", end_date_time);

    // let end_date_time = NaiveDateTime::parse_from_str(&end_date_time, "%Y-%m-%dT%H:%M").expect("Failed to parse end_date_time as datetime");
    // let end_date_time = end_date_time.and_utc().timestamp();



    let duty_slot = DutySlot {
        required_specialty: publish_duty_slot_request.requiredSpecialty._id.parse::<u16>().unwrap(),
        hospital_id: TODO_SESSION_USER_ID, //req.session.user_id,
        start_date_time: start_date_time,
        end_date_time: end_date_time,
        price_from: publish_duty_slot_request.priceFrom,
        price_to: publish_duty_slot_request.priceTo,
        currency: publish_duty_slot_request.currency,
        status: DutyStatus::open,
        assigned_doctor_id: None
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

    
    router.post("/auth/register"
        , true
        , |req: HttpRequest| async move {
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
                specialty: user_deserialize.specialty.as_ref().and_then(|s| s.parse::<u16>().ok()),
                email: user_deserialize.email,
                phone_number: user_deserialize.phone_number
            };
            
            // hash the passworf using pbkdf2
            println!("Before hashing password");

            let salt_string = "your_salt_string";
            let hashed_password = hex::encode(hash_password_with_pbkdf2(&user.password, salt_string.as_bytes()));
            println!("After hashing password: {}", hashed_password); 
            user.password = hashed_password;
            println!("Parsed user: {:?}", user); // Debug print
            let key = insert_user_internal(user);
            println!("Inserted user with key: {:?}", key); // Debug print
            Ok(HttpResponse {
                status_code: 200,
                headers: HashMap::new(),
                body: json!({
                    "statusCode": 200,
                    "message": "User registered",
                    "key": key
                })
                .into(),
            })
        });

    router.post("/auth/login", true, move |req: HttpRequest| async move {
        // Log the full incoming request
        println!("Incoming Request: method = {}, url = {}", req.method, req.url);
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
                let hashed_password = hex::encode(hash_password_with_pbkdf2(password, "your_salt_string".as_bytes()));

                if user.password == hashed_password {
                    println!("User logged in: {}", user.username);

                    // Create a JWT
                    let payload = json!({ "userId": id, "role": user.role, "username": user.username });
                    let token = JWT::sign(payload, "your_secret", 3600);
                    // Create a cookie
                    let mut cookie = Cookie::new("token", token);
                    cookie.set_http_only(true);
                    cookie.set_same_site(SameSite::Strict);

                    // Convert the cookie to a string
                    let cookie_string = cookie.to_string();

                    // Define response
                    let response = HttpResponse {
                        status_code: 200,
                        headers: hashmap! {
                            "Set-Cookie".to_string() => cookie_string,
                        },
                        body: json!({
                            "statusCode": 200,
                            "message": "User logged in",
                            "username": user.username
                        })
                        .into(),
                    };

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


    router.get("/user/data", false, |req: HttpRequest| async move {
        let token = extract_token_from_cookie(&req);
        println!("In the user data route Token: {:?}",  token);
        let secret = "your_secret";

        let token = match token {
            Some(token) => token,
            None => return Ok(unauthorized_response("No token found in request")),
        };

        let result = JWT::verify(&token, secret);
        println!("Result: {:?}", result);

        let payload = match result {
            Ok(Some(payload)) => payload,
            _ => return Ok(unauthorized_response("Failed to verify token")),
        };

        println!("Payload: {:?}", payload);

        let (user_id, user_role, user_username) = extract_user_info(&payload);

        println!("User ID: {}", user_id);
        println!("User Role: {}", user_role);
        println!("User Username: {}", user_username);

        Ok(HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: json!({
                "statusCode": 200,
                "_id": user_id,
                "role": user_role
            })
            .into(),
        })
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

    router.get("/specialties", false, |_: HttpRequest| async move {
        println!("Received a request at GET /specialties");

        let specialties: Vec<_> = SPECIALTIES_STRINGS.iter().enumerate().map(|(i, &name)| {
            json!({
                "_id": format!("{:04x}", i),
                "name": name,
                "__v": 0
            })
        }).collect();            

        println!("Specialties: {:?}", specialties);

        let response = HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: serde_json::to_string(&specialties).unwrap()
            .into()
        };

        println!("Responding with status code: {}", response.status_code);
        println!("Response body: {:?}", response.body);
        Ok(response)
    });
    router
}

fn extract_token_from_cookie(req: &HttpRequest) -> Option<String> {
    for header in req.headers.iter() {
        // serialize header to Candid, and deserialize to MyHeaderField
        let mut serializer = IDLBuilder::new();
        serializer.arg(&header).unwrap();
        let candid_message = serializer.serialize_to_vec().unwrap();
        
        let mut deserializer = IDLDeserialize::new(&candid_message).unwrap();
        let header_field: MyHeaderField = deserializer.get_value().unwrap();

        if header_field.0 == "cookie" {
            let cookie = Cookie::parse(header_field.1).unwrap();
            if cookie.name() == "token" {
                return Some(cookie.value().to_string());
            }
        }

        
    }
    None
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

fn extract_user_info(payload: &Value) -> (u64, &str, &str) {
    let user_id = payload["userId"].as_u64().unwrap();
    let user_role = payload["role"].as_str().unwrap();
    let user_username = payload["username"].as_str().unwrap();

    (user_id, user_role, user_username)
}

