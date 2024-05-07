use std::collections::HashMap;

use ic_cdk::println;
use pluto::{
    http::{HttpRequest, HttpResponse, HttpServe},
    router::Router,
};
use serde_json::json;
use crate::{get_all_duty_slots, insert_duty_slot};
use crate::DutySlot;
use crate::DutyStatus;
use crate::types::PublishDutySlotRequest;

//define  a global u32 constant 
pub const TODO_SESSION_USER_ID: u32 = 1;












pub(crate) fn setup() -> Router {
    let mut router = Router::new();

    router.put("/:value", false, |req: HttpRequest| async move {
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
    router.post("/", false, |req: HttpRequest| async move {
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
        println!("Duty slots: {:?}", get_all_duty_slots());


        //respond with json using duty_slots
        Ok(HttpResponse {
            status_code: 200,
            headers: HashMap::new(),
            body: json!({
                "statusCode": 200,
                "message": "Hello World from GET /duty/slots/json",
                "dutySlots": get_all_duty_slots()
            })
            .into(),
        })
    });

    router.post("/duty/publish", false, |req: HttpRequest| async move {
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

    let key = insert_duty_slot(duty_slot);

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

    router
}