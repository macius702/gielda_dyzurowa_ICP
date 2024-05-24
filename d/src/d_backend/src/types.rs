
use serde::Serialize;
use serde::Deserialize;


#[derive(Debug, Serialize, Deserialize)]
pub struct PublishDutySlotRequest {
    pub requiredSpecialty: Specialty,
    pub startDate: String,
    pub startTime: String,
    pub endDate: String,
    pub endTime: String,
    pub priceFrom: Option<f64>,
    pub priceTo: Option<f64>,
    pub currency: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Specialty {
    pub _id: String,
    pub name: String,
}
