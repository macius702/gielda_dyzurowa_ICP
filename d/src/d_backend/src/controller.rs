use std::collections::HashMap;

use ic_cdk::println;
use pluto::{
    http::{HttpRequest, HttpResponse, HttpServe},
    router::Router,
};
use serde_json::json;
use crate::{find_user_by_username, get_all_duty_slots_internal, get_all_users_internal, insert_duty_slot_internal, insert_user_internal};
use crate::DutySlot;
use crate::DutyStatus;
use crate::types::PublishDutySlotRequest;
use crate::User;

//define  a global u32 constant 
pub const TODO_SESSION_USER_ID: u32 = 1;




use ring::pbkdf2;
use ring::digest;

static PBKDF2_ALG: pbkdf2::Algorithm = pbkdf2::PBKDF2_HMAC_SHA256;
const CREDENTIAL_LEN: usize = digest::SHA256_OUTPUT_LEN;
type Credential = [u8; CREDENTIAL_LEN];

fn hash_password(password: &str, salt: &[u8]) -> Credential {
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
    let publish_duty_slot_request: PublishDutySlotRequest = serde_json::from_str(&body_string).unwrap();

    let start_date_time = format!("{}T{}", publish_duty_slot_request.start_date, publish_duty_slot_request.start_time);
    let end_date_time = format!("{}T{}", publish_duty_slot_request.end_date, publish_duty_slot_request.end_time);

    let duty_slot = DutySlot {
        required_specialty: publish_duty_slot_request.required_specialty,
        hospital_id: TODO_SESSION_USER_ID, //req.session.user_id,
        start_date_time: start_date_time.parse::<i64>().unwrap(),
        end_date_time: end_date_time.parse::<i64>().unwrap(),
        price_from: publish_duty_slot_request.price_from,
        price_to: publish_duty_slot_request.price_to,
        currency: publish_duty_slot_request.currency,
        status: DutyStatus::Open,
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
            let mut user: User = serde_json::from_str(&body_string).unwrap();
            
            // hash the passworf using bcrypt
            println!("Before hashing password");

            let salt_string = "your_salt_string";
            let hashed_password = hex::encode(hash_password(&user.password, salt_string.as_bytes()));
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
        let user = find_user_by_username(username);

        match user {
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
            Some(user) => {
                // Check the password
                let hashed_password = hex::encode(hash_password(password, "your_salt_string".as_bytes()));
                if user.password == hashed_password {
                    println!("User logged in: {}", user.username);
                    // Send response with status 200
                    Ok(HttpResponse {
                        status_code: 200,
                        headers: HashMap::new(),
                        body: json!({
                            "statusCode": 200,
                            "message": "User logged in",
                            "username": user.username
                        })
                        .into(),
                    })
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





    router
}