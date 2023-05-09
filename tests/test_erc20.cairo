use result::ResultTrait;
use array::ArrayTrait;
use starknet::ContractAddress;
use starknet::contract_address_const;
use starknet::contract_address_to_felt252;
use traits::Into;

fn setup() -> (felt252, felt252, felt252, felt252){

    let caller_address: ContractAddress = contract_address_const::<0>();
    let caller_address_felt252 = contract_address_to_felt252(caller_address);

    let address_one: ContractAddress = contract_address_const::<1>();
    let address_one_felt252 = contract_address_to_felt252(address_one);

    let address_two: ContractAddress = contract_address_const::<2>();
    let address_two_felt252 = contract_address_to_felt252(address_two);

    let mut constructor_calldata: Array<felt252> = ArrayTrait::new();
    constructor_calldata.append('MyToken');
    constructor_calldata.append('MTN');
    constructor_calldata.append(18_u8.into());

    let deployed_contract_address: felt252 = deploy_contract('erc20', constructor_calldata).unwrap();

    let amount: u256 = u256 {
        high: 0_u128,
        low: 100_u128
    };

    let mut mint_calldata: Array<felt252> = ArrayTrait::new();
    mint_calldata.append(amount.high.into());
    mint_calldata.append(amount.low.into());

    invoke(deployed_contract_address, 'mint', mint_calldata).unwrap();

    (caller_address_felt252, address_one_felt252, address_two_felt252, deployed_contract_address)
}

#[test]
#[available_gas(2000000)]
fn test_setup() {
    let (caller_address, address_one, address_two, deployed_contract_address) = setup();

    let return_data = call(deployed_contract_address, 'name', ArrayTrait::new() ).unwrap();
    assert(*return_data.at(0_u32) == 'MyToken', *return_data.at(0_u32)); 

    let return_data = call(deployed_contract_address, 'symbol', ArrayTrait::new() ).unwrap();
    assert(*return_data.at(0_u32) == 'MTN', *return_data.at(0_u32)); 

    let return_data = call(deployed_contract_address, 'decimals', ArrayTrait::new() ).unwrap();
    assert(*return_data.at(0_u32) == 18, *return_data.at(0_u32)); 
}

#[test]
#[available_gas(2000000)]
fn test_mint() {
    let (caller_address, address_one, address_two, deployed_contract_address) = setup();

    let mut calldata_one: Array<felt252> = ArrayTrait::new();
    calldata_one.append(caller_address);

    let return_data_one: Array<felt252> = call(deployed_contract_address, 'balance_of', calldata_one).unwrap();
    assert(*return_data_one.at(1_u32) == 100, *return_data_one.at(1_u32)); 

    let mut calldata_two: Array<felt252> = ArrayTrait::new();
    calldata_two.append(address_one);

    let return_data_two: Array<felt252> = call(deployed_contract_address, 'balance_of', calldata_two).unwrap();
    assert(*return_data_two.at(1_u32) == 0, *return_data_two.at(1_u32));
}

#[test]
#[available_gas(2000000)]
fn test_transfer() {
    let (caller_address, address_one, address_two, deployed_contract_address) = setup();
    let amount: u256 = u256 {
        high: 0_u128,
        low: 10_u128
    };

    let mut calldata_zero: Array<felt252> = ArrayTrait::new();
    calldata_zero.append(address_one);
    calldata_zero.append(amount.high.into());
    calldata_zero.append(amount.low.into());

    invoke(deployed_contract_address, 'transfer', calldata_zero).unwrap();

    let mut calldata_one: Array<felt252> = ArrayTrait::new();
    calldata_one.append(caller_address);

    let return_data_one: Array<felt252> = call(deployed_contract_address, 'balance_of', calldata_one).unwrap();
    assert(*return_data_one.at(1_u32) == 90, *return_data_one.at(1_u32));

    let mut calldata_two: Array<felt252> = ArrayTrait::new();
    calldata_two.append(address_one);

    let return_data_two: Array<felt252> = call(deployed_contract_address, 'balance_of', calldata_two).unwrap();
    assert(*return_data_two.at(1_u32) == 10, *return_data_two.at(1_u32));
}

#[test]
#[available_gas(2000000)]
fn test_transfer_error() {
    let (caller_address, address_one, address_two, deployed_contract_address) = setup();
    let amount: u256 = u256 {
        high: 0_u128,
        low: 110_u128
    };

    let mut calldata_zero: Array<felt252> = ArrayTrait::new();
    calldata_zero.append(address_one);
    calldata_zero.append(amount.high.into());
    calldata_zero.append(amount.low.into());

    let result = invoke(deployed_contract_address, 'transfer', calldata_zero);
    assert(result.is_err(), 'Transfer should fail');
}

#[test]
#[available_gas(2000000)]
fn test_approve() {
    let (caller_address, address_one, address_two, deployed_contract_address) = setup();
    let amount: u256 = u256 {
        high: 0_u128,
        low: 10_u128
    };

    let mut calldata_zero: Array<felt252> = ArrayTrait::new();
    calldata_zero.append(address_one);
    calldata_zero.append(amount.high.into());
    calldata_zero.append(amount.low.into());

    invoke(deployed_contract_address, 'approve', calldata_zero).unwrap();

    let mut calldata_one: Array<felt252> = ArrayTrait::new();
    calldata_one.append(caller_address);
    calldata_one.append(address_one);

    let return_data_one: Array<felt252> = call(deployed_contract_address, 'allowance', calldata_one).unwrap();
    assert(*return_data_one.at(1_u32) == 10, *return_data_one.at(1_u32));
}

// TO DO - Transfer from, Requires being able to change the caller address

// 0 address is always the caller 
// u256 values need to be split into two felt252 values
// Note: Protostar is not able to handle #[external] functions which emit an event for testing 
// just yet. Please wait for the next release.
