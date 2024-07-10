
use candid::CandidType;
use serde::Serialize;
use serde::Deserialize;
use crate::DutyStatus;


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

#[derive(Debug, Serialize, Deserialize, CandidType)]
pub struct Specialty {
    pub _id: String,
    pub name: String,
}

// ignore snake case warning
// #[allow(non_snake_case)]
#[derive(Debug, Serialize, Deserialize, CandidType)]
pub struct DutyVacancyForDisplay {
    pub _id: String,
    pub hospitalId: Hospital,
    pub requiredSpecialty: Specialty,
    pub status: DutyStatus,
    pub assignedDoctorId: Option<Doctor>,
    pub startDateTime: String,
    pub endDateTime: String,
    pub priceFrom: Option<f64>,
    pub priceTo: Option<f64>,
    pub currency: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, CandidType)]
pub struct Hospital {
    pub _id: String,
    pub username: String,
    pub password: String,
    pub role: String,
    pub profileVisible: bool,
}

#[derive(Debug, Serialize, Deserialize, CandidType)]
pub struct Doctor {
    pub _id: String,
    pub username: String,
    pub password: String,
    pub role: String,
    pub specialty: String,
    pub localization: String,
    pub profileVisible: bool,
}
