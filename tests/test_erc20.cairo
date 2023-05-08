use result::ResultTrait;
use array::ArrayTrait;
use array::ArrayTCloneImpl;
use array::SpanTrait;
use clone::Clone;
use debug::PrintTrait;
use starknet::ContractAddress;
use starknet::contract_address_const;
use starknet::contract_address_to_felt252;
use traits::Into;
use traits::TryInto;

fn setup() -> (felt252, felt252, felt252){

    let address_one = contract_address_const::<0>();
    let address_one_felt252 = contract_address_to_felt252(address_one);

    let address_two = contract_address_const::<1>();
    let address_two_felt252 = contract_address_to_felt252(address_two);

    let class_hash = declare('erc20').unwrap();
    
    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append('MyToken');
    constructor_calldata.append('MTN');
    constructor_calldata.append(18_u8.into());

    let prepare_result = prepare(class_hash, constructor_calldata).unwrap();
    let prepared_contract = PreparedContract {
        contract_address: prepare_result.contract_address,
        class_hash: prepare_result.class_hash,
        constructor_calldata: prepare_result.constructor_calldata
    };

    let deployed_contract_address_felt252 = deploy(prepared_contract).unwrap();

    let amount = u256 {
        high: 0_u128,
        low: 100_u128
    };
    let amount_felt252 = u256_into_felt252(amount);

    let mut mint_calldata = ArrayTrait::new();
    mint_calldata.append(address_one_felt252); 
    mint_calldata.append(amount_felt252);

    invoke(deployed_contract_address_felt252, 'mint', mint_calldata).unwrap();

    (address_one_felt252, address_two_felt252, deployed_contract_address_felt252)
}

// Test Getter Function - Works
#[test]
fn test_decimals() {
    let (address_one, address_two, deployed_contract_address) = setup();

    let return_data = call(deployed_contract_address, 'decimals', ArrayTrait::new() ).unwrap();
    assert(*return_data.at(0_u32) == 18, *return_data.at(0_u32)); 
}

// Test Balance Of Function - Works
#[test]
fn test_balance_of() {
    let (address_one, address_two, deployed_contract_address) = setup();

    let mut calldata_one = ArrayTrait::new();
    calldata_one.append(address_one);

    let return_data_one = call(deployed_contract_address, 'balanceOf', calldata_one).unwrap();
    assert(*return_data_one.at(1_u32) == 100, *return_data_one.at(1_u32)); 

    let mut calldata_two = ArrayTrait::new();
    calldata_two.append(address_two);

    let return_data_two = call(deployed_contract_address, 'balanceOf', calldata_two).unwrap();
    assert(*return_data_two.at(1_u32) == 0, *return_data_two.at(1_u32));
}

// Test Transfer Function - Broken
#[test]
fn test_transfer() {
    let (address_one, address_two, deployed_contract_address) = setup();
    let amount = u256 {
        high: 0_u128,
        low: 10_u128
    };
    let amount_felt252 = u256_into_felt252(amount);

    let mut calldata_zero = ArrayTrait::new();
    calldata_zero.append(address_one);
    calldata_zero.append(address_two);
    calldata_zero.append(amount_felt252);

    invoke(deployed_contract_address, 'transfer', calldata_zero).unwrap();

    let mut calldata_one = ArrayTrait::new();
    calldata_one.append(address_one);

    let return_data_one = call(deployed_contract_address, 'balanceOf', calldata_one).unwrap();
    assert(*return_data_one.at(1_u32) == 90, *return_data_one.at(1_u32)); 

    let mut calldata_two = ArrayTrait::new();
    calldata_two.append(address_two);

    let return_data_two = call(deployed_contract_address, 'balanceOf', calldata_two).unwrap();
    assert(*return_data_two.at(1_u32) == 10, *return_data_two.at(1_u32));
}

// Helper Functions

fn u256_into_felt252(val: u256) -> (felt252) {
    let FELT252_PRIME_HIGH = 0x8000000000000110000000000000000_u128;
    if val.high > FELT252_PRIME_HIGH {
        return 0_felt252;
    }
    if val.high == FELT252_PRIME_HIGH {
        // since FELT252_PRIME_LOW is 1.
        if val.low != 0_u128 {
            return 0_felt252;
        }
    }
    val.high.into() * 0x100000000000000000000000000000000_felt252 + val.low.into()
}