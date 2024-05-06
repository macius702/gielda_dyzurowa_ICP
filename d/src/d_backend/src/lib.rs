





use candid::{CandidType, Deserialize, Encode, Decode};
use ic_stable_structures::memory_manager::{MemoryId, MemoryManager, VirtualMemory};
use ic_stable_structures::{DefaultMemoryImpl, StableBTreeMap, Storable, 
    storable::Bound};
use std::{borrow::Cow, cell::RefCell};

use serde::Serialize;

mod specialties;
use specialties::SPECIALTIES_STRINGS;

mod bootstrap;
mod controller;
use pluto::http::RawHttpRequest;
use pluto::http::RawHttpResponse;


type Memory = VirtualMemory<DefaultMemoryImpl>;

const MAX_VALUE_SIZE: u32 = 1000; // Adjust this value as needed

#[derive(CandidType, Deserialize, Clone, Serialize, Debug)]
pub enum DutyStatus {
    Open,
    Waiting,
    Filled,
}

#[derive(CandidType, Deserialize, Clone, Serialize, Debug)]
pub struct DutySlot {
    pub required_specialty: usize,
    pub hospital_id: u32,
    pub start_date_time: i64,
    pub end_date_time: i64,
    pub status: DutyStatus,
    pub assigned_doctor_id: Option<u32>,
    pub price_from: Option<f64>,
    pub price_to: Option<f64>,
    pub currency: Option<String>,
}

impl Storable for DutySlot {
    fn to_bytes(&self) -> Cow<[u8]> {
        Cow::Owned(Encode!(self).unwrap())
    }

    fn from_bytes(bytes: Cow<[u8]>) -> Self {
        Decode!(bytes.as_ref(), Self).unwrap()
    }

    const BOUND: Bound = Bound::Bounded {
        max_size: MAX_VALUE_SIZE,
        is_fixed_size: false,
    };
}

// A storable type of User
#[derive(CandidType, Deserialize, Clone)]
pub struct User {
    pub username: String,
    pub password: String,
    pub role: UserRole,
    pub specialty: Option<u16>,
    pub localization: Option<String>,
    pub email: Option<String>,
    pub phone_number: Option<String>,
}

impl Storable for User {
    fn to_bytes(&self) -> Cow<[u8]> {
        Cow::Owned(Encode!(self).unwrap())
    }

    fn from_bytes(bytes: Cow<[u8]>) -> Self {
        Decode!(bytes.as_ref(), Self).unwrap()
    }

    const BOUND: Bound = Bound::Bounded {
        max_size: MAX_VALUE_SIZE,
        is_fixed_size: false,
    };
}       



#[derive(CandidType, Deserialize, Clone)]
pub enum UserRole {
    Doctor,
    Hospital,
}

thread_local! {
    static MEMORY_MANAGER: RefCell<MemoryManager<DefaultMemoryImpl>> =
        RefCell::new(MemoryManager::init(DefaultMemoryImpl::default()));

    static MAP: RefCell<StableBTreeMap<u32, DutySlot, Memory>> = RefCell::new(
        StableBTreeMap::init(
            MEMORY_MANAGER.with(|m| m.borrow().get(MemoryId::new(0))),
        )
    );
    static NEXT_DUTYSLOTS_KEY: RefCell<u32> = RefCell::new(1);

    static SPECIALTIES: RefCell<Vec<String>> = RefCell::new(SPECIALTIES_STRINGS.iter().map(|&s| s.to_string()).collect());

    // User map
    static USER_MAP: RefCell<StableBTreeMap<u32, User, Memory>> = RefCell::new(
        StableBTreeMap::init(
            MEMORY_MANAGER.with(|m| m.borrow().get(MemoryId::new(1))),
        )
    );
    // Next user key
    static NEXT_USER_KEY: RefCell<u32> = RefCell::new(1);




}


/// Retrieves all DutySlots as a Vec.
#[ic_cdk_macros::query]
fn get_all_duty_slots() -> Vec<DutySlot> {
    MAP.with(|p| p.borrow().iter().map(|(_, v)| v.clone()).collect())
}

#[ic_cdk_macros::update]
fn insert_duty_slot(value: DutySlot) -> u32 {
    let key = NEXT_DUTYSLOTS_KEY.with(|k| {
        let key = *k.borrow();
        *k.borrow_mut() += 1;
        key
    });

    MAP.with(|p| p.borrow_mut().insert(key, value));
    key
}

// Retirieve all specialties
#[ic_cdk_macros::query]
fn get_specialties() -> Vec<String> {
    ic_cdk::println!("println from get_specialties()\n");
    SPECIALTIES.with(|p| p.borrow().clone())
}

// Insert a new user
#[ic_cdk_macros::update]
fn insert_user(value: User) -> u32 {
    let key = NEXT_USER_KEY.with(|k| {
        let key = *k.borrow();
        *k.borrow_mut() += 1;
        key
    });

    USER_MAP.with(|p| p.borrow_mut().insert(key, value));
    key
}

// Get all users
#[ic_cdk_macros::query]
fn get_all_users() -> Vec<User> {
    USER_MAP.with(|p| p.borrow().iter().map(|(_, v)| v.clone()).collect())
}



ic_cdk::export_candid!();