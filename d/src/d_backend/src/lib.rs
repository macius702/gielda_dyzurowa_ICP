





use candid::{CandidType, Deserialize, Encode, Decode};
use ic_stable_structures::memory_manager::{MemoryId, MemoryManager, VirtualMemory};
use ic_stable_structures::{DefaultMemoryImpl, StableBTreeMap, Storable, 
    storable::Bound};
use std::{borrow::Cow, cell::RefCell};

mod specialties;
use specialties::SPECIALTIES_STRINGS;

type Memory = VirtualMemory<DefaultMemoryImpl>;

const MAX_VALUE_SIZE: u32 = 1000; // Adjust this value as needed

#[derive(CandidType, Deserialize, Clone)]
pub enum DutyStatus {
    Open,
    Waiting,
    Filled,
}

#[derive(CandidType, Deserialize, Clone)]
pub struct DutySlot {
    pub required_specialty: usize,
    pub hospital_id: usize,
    pub start_date_time: i64,
    pub end_date_time: i64,
    pub status: DutyStatus,
    pub assigned_doctor_id: Option<usize>,
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

thread_local! {
    static MEMORY_MANAGER: RefCell<MemoryManager<DefaultMemoryImpl>> =
        RefCell::new(MemoryManager::init(DefaultMemoryImpl::default()));

    static MAP: RefCell<StableBTreeMap<u32, DutySlot, Memory>> = RefCell::new(
        StableBTreeMap::init(
            MEMORY_MANAGER.with(|m| m.borrow().get(MemoryId::new(0))),
        )
    );

    static SPECIALTIES: RefCell<Vec<String>> = RefCell::new(SPECIALTIES_STRINGS.iter().map(|&s| s.to_string()).collect());
}


/// Retrieves all DutySlots as a Vec.
#[ic_cdk_macros::query]
fn get_all() -> Vec<DutySlot> {
    MAP.with(|p| p.borrow().iter().map(|(_, v)| v.clone()).collect())
}

#[ic_cdk_macros::update]
fn insert(key: u32, value: DutySlot) -> Option<DutySlot> {
    MAP.with(|p| p.borrow_mut().insert(key, value))
}

// Retirieve all specialties
#[ic_cdk_macros::query]
fn get_specialties() -> Vec<String> {
    SPECIALTIES.with(|p| p.borrow().clone())
}


ic_cdk::export_candid!();