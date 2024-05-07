
use serde::Serialize;
use candid::Deserialize;


#[derive(Debug, Serialize, Deserialize)]
pub struct PublishDutySlotRequest {
    pub required_specialty: usize,
    pub start_date: String,
    pub start_time: String,
    pub end_date: String,
    pub end_time: String,
    pub price_from: Option<f64>,
    pub price_to: Option<f64>,
    pub currency: Option<String>,
}       


