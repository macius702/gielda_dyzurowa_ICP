pub mod types;

use candid::{CandidType, Decode, Deserialize, Encode};
use ic_stable_structures::memory_manager::{MemoryId, MemoryManager, VirtualMemory};
use ic_stable_structures::{storable::Bound, DefaultMemoryImpl, StableBTreeMap, Storable};
use std::cmp::Reverse;
use std::collections::{BinaryHeap, HashMap};
use std::str::FromStr;
use std::{borrow::Cow, cell::RefCell};

use serde::Serialize;

mod specialties;
use specialties::SPECIALTIES_STRINGS;

mod bootstrap;
mod controller;
mod jwt;
use pluto::http::RawHttpRequest;
use pluto::http::RawHttpResponse;

use controller::convert_from_unix_timestamp;

type Memory = VirtualMemory<DefaultMemoryImpl>;

const MAX_VALUE_SIZE: u32 = 1000; // Adjust this value as needed

#[derive(CandidType, Deserialize, Clone, Serialize, Debug)]
pub enum DutyStatus {
    open,
    pending,
    filled,
}

#[derive(CandidType, Deserialize, Clone, Serialize, Debug)]
pub struct DutySlot {
    pub required_specialty: u16,
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
#[derive(CandidType, Deserialize, Clone, Debug, Serialize)]
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

#[allow(non_camel_case_types)]
#[derive(CandidType, Deserialize, Clone, Debug, Serialize)]
pub enum UserRole {
    doctor,
    hospital,
}

impl FromStr for UserRole {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "doctor" => Ok(UserRole::doctor),
            "hospital" => Ok(UserRole::hospital),
            _ => Err(()),
        }
    }
}

use std::fmt;

impl fmt::Display for UserRole {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match *self {
            UserRole::doctor => write!(f, "doctor"),
            UserRole::hospital => write!(f, "hospital"),
        }
    }
}

#[derive(Eq, PartialEq, Ord, PartialOrd)]
struct TokenData {
    create_time: Reverse<u64>,
    token: String,
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


    // Used tokens
    static USED_TOKENS_MAP: RefCell<HashMap<String, u64>> = RefCell::new(HashMap::new());
    static USED_TOKENS_HEAP: RefCell<BinaryHeap<TokenData>> = RefCell::new(BinaryHeap::new());
}

fn get_duty_slot_by_id(id: u32) -> Option<DutySlot> {
    MAP.with(|p| p.borrow().get(&id).clone())
}

fn delete_duty_slot_by_id(id: u32) {
    MAP.with(|p| {
        p.borrow_mut().remove(&id);
    });
}

fn accept_duty_slot_by_id(duty_slot_id: u32, doctor_id: u32) {
    // take the duty slot that has the id equal to duty_slot_id
    let duty_slot = get_duty_slot_by_id(duty_slot_id).unwrap();
    // update the duty slot with the doctor_id and status to filled
    //mtlk TODO - can it be shorter , without mentioning all the members ?
    let updated_duty_slot = DutySlot {
        required_specialty: duty_slot.required_specialty,
        hospital_id: duty_slot.hospital_id,
        start_date_time: duty_slot.start_date_time,
        end_date_time: duty_slot.end_date_time,
        status: DutyStatus::filled,
        assigned_doctor_id: Some(doctor_id),
        price_from: duty_slot.price_from,
        price_to: duty_slot.price_to,
        currency: duty_slot.currency,
    };
    // update the duty slot in the MAP
    MAP.with(|p| {
        p.borrow_mut().insert(duty_slot_id, updated_duty_slot);
    });

}

fn find_user_by_username(username: &str) -> Option<(u32, User)> {
    USER_MAP.with(|user_map| {
        let user_map = user_map.borrow();

        for (key, user) in user_map.iter() {
            if user.username == username {
                return Some((key.clone(), user.clone()));
            }
        }

        None
    })
}

/// Retrieves all DutySlots as a Vec.
#[ic_cdk_macros::query]
fn get_all_duty_slots() -> Vec<DutySlot> {
    get_all_duty_slots_internal()
}

fn get_all_duty_slots_internal() -> Vec<DutySlot> {
    MAP.with(|p| p.borrow().iter().map(|(_, v)| v.clone()).collect())
}

// Retrieve all DutySlots as Vec<DutyVacancyForDisplay>
fn get_all_duty_slots_for_display() -> Vec<types::DutyVacancyForDisplay> {
    get_all_duty_slots_for_display_internal()
}

fn get_all_duty_slots_for_display_internal() -> Vec<types::DutyVacancyForDisplay> {
    MAP.with(|p| {
        p.borrow()
            .iter()
            .map(|(k, v)| {
                types::DutyVacancyForDisplay {
                    // for _id I need the key of the MAP
                    _id: k.to_string(),
                    startDateTime: convert_from_unix_timestamp(v.start_date_time),
                    endDateTime: convert_from_unix_timestamp(v.end_date_time),
                    status: v.status.clone(),
                    currency: v.currency.clone(),
                    priceFrom: v.price_from,
                    priceTo: v.price_to,
                    hospitalId: get_hospital_by_id(v.hospital_id),
                    assignedDoctorId: get_doctor_by_id(v.assigned_doctor_id),
                    requiredSpecialty: get_specialty_by_id(v.required_specialty),
                }
            })
            .collect()
    })
}

fn get_hospital_by_id(_id: u32) -> types::Hospital {
    let user = get_user_by_id(_id);
    types::Hospital {
        _id: _id.to_string(),
        username: user.username,
        password: user.password,
        role: user.role.to_string(),
        profileVisible: true,
    }
}

fn get_doctor_by_id(doctor_id: Option<u32>) -> Option<types::Doctor> {
    match doctor_id {
        Some(id) => {
            let user = get_user_by_id(id);
            Some(types::Doctor {
                _id: id.to_string(),
                username: user.username,
                password: user.password,
                role: user.role.to_string(),
                specialty: user.specialty.unwrap().to_string(),
                localization: user.localization.unwrap(),
                profileVisible: true,
            })
        }
        None => None,
    }
}

fn get_user_by_id(user_id: u32) -> User {
    USER_MAP.with(|p| p.borrow().get(&user_id).unwrap().clone())
}

fn get_specialty_by_id(specialty_id: u16) -> types::Specialty {
    SPECIALTIES.with(|p| {
        let specialties = p.borrow();
        let specialty = specialties.get(specialty_id as usize).unwrap();
        types::Specialty {
            _id: specialty_id.to_string(),
            name: specialty.to_string(),
        }
    })
}

#[ic_cdk_macros::update]
fn delete_all_duty_slots() {
    delete_all_duty_slots_internal();
}

fn delete_all_duty_slots_internal() {
    MAP.with(|p| {
        let keys = p.borrow().iter().map(|(key, _)| key).collect::<Vec<u32>>();
        for key in keys {
            p.borrow_mut().remove(&key);
        }
    });
}

#[ic_cdk_macros::update]
fn insert_duty_slot(value: DutySlot) -> u32 {
    insert_duty_slot_internal(value)
}

fn insert_duty_slot_internal(value: DutySlot) -> u32 {
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
    get_specialties_internal()
}

fn get_specialties_internal() -> Vec<String> {
    ic_cdk::println!("println from get_specialties()\n");
    SPECIALTIES.with(|p| p.borrow().clone())
}

// Insert a new user
#[ic_cdk_macros::update]
fn insert_user(value: User) -> u32 {
    insert_user_internal(value)
}

fn insert_user_internal(value: User) -> u32 {
    println!("Entering function insert_user");
    println!("Inserting user: {:?}", value);

    let mut user_exists = false;

    USER_MAP.with(|p| {
        let map = p.borrow();
        for (_, v) in map.iter() {
            if v.username.eq_ignore_ascii_case(&value.username) {
                println!("User already exists, not inserting");
                user_exists = true;
                break;
            }
        }
    });

    if user_exists {
        return 0;
    }

    let key = NEXT_USER_KEY.with(|k| {
        let key = *k.borrow();
        println!("Current key: {}", key);

        *k.borrow_mut() += 1;
        println!("Incremented key: {}", key);
        key
    });

    USER_MAP.with(|p| {
        p.borrow_mut().insert(key, value);
    });

    println!("Leaving function insert_user");
    key
}

fn delete_user_internal(key: u32) {
    // handle warning on deleting  dependant duty slots - mtlk todo
    //handling assigned_doctor_id - mtlk todo

    //first delete dependent data from MAP, which is when DutySlot hospitalId is equal to key
    MAP.with(|p| {
        let keys = p
            .borrow()
            .iter()
            .filter_map(|(k, v)| {
                if v.hospital_id == key {
                    Some(k.clone())
                } else {
                    None
                }
            })
            .collect::<Vec<u32>>();
        for key in keys {
            p.borrow_mut().remove(&key);
        }
    });

    USER_MAP.with(|p| {
        p.borrow_mut().remove(&key);
    });
}

#[ic_cdk_macros::update]
fn delete_all_users() {
    delete_all_users_internal();
}

fn delete_all_users_internal() {
    //remove items one by one
    USER_MAP.with(|p| {
        let keys = p.borrow().iter().map(|(key, _)| key).collect::<Vec<u32>>();
        for key in keys {
            p.borrow_mut().remove(&key);
        }
    });
}

// Get all users
#[ic_cdk_macros::query]
fn get_all_users() -> Vec<User> {
    get_all_users_internal()
}

fn get_all_users_internal() -> Vec<User> {
    USER_MAP.with(|p| p.borrow().iter().map(|(_, v)| v.clone()).collect())
}

// return only user ames
fn get_all_usernames_internal() -> Vec<String> {
    USER_MAP.with(|p| p.borrow().iter().map(|(_, v)| v.username.clone()).collect())
}

// Get all user names
#[ic_cdk_macros::query]
fn get_all_usernames() -> Vec<String> {
    get_all_usernames_internal()
}

ic_cdk::export_candid!();
