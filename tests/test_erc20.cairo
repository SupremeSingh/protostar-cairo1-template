use result::ResultTrait;
use cheatcodes::RevertedTransactionTrait;
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
    let address_one: ContractAddress = contract_address_const::<0>();
    let address_one_felt252 = contract_address_to_felt252(address_one);

    let address_two: ContractAddress = contract_address_const::<1>();
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

    (address_one_felt252, address_two_felt252, deployed_contract_address)
}

#[test]
fn test_decimals() {
    let (address_one, address_two, deployed_contract_address) = setup();

    let return_data = call(deployed_contract_address, 'decimals', ArrayTrait::new() ).unwrap();
    assert(*return_data.at(0_u32) == 18, *return_data.at(0_u32)); 
}

#[test]
fn test_balance_of() {
    let (address_one, address_two, deployed_contract_address) = setup();

    let mut calldata_one: Array<felt252> = ArrayTrait::new();
    calldata_one.append(address_one);

    let return_data_one: Array<felt252> = call(deployed_contract_address, 'balanceOf', calldata_one).unwrap();
    assert(*return_data_one.at(1_u32) == 100, *return_data_one.at(1_u32)); 

    let mut calldata_two: Array<felt252> = ArrayTrait::new();
    calldata_two.append(address_two);

    let return_data_two: Array<felt252> = call(deployed_contract_address, 'balanceOf', calldata_two).unwrap();
    assert(*return_data_two.at(1_u32) == 0, *return_data_two.at(1_u32));
}

#[test]
fn test_transfer_from() {
    let (address_one, address_two, deployed_contract_address) = setup();
    let amount: u256 = u256 {
        high: 0_u128,
        low: 10_u128
    };

    let mut calldata_zero: Array<felt252> = ArrayTrait::new();
    calldata_zero.append(address_two);
    calldata_zero.append(amount.high.into());
    calldata_zero.append(amount.low.into());

    invoke(deployed_contract_address, 'transfer', calldata_zero).unwrap();

    let mut calldata_one: Array<felt252> = ArrayTrait::new();
    calldata_one.append(address_one);

    let return_data_one: Array<felt252> = call(deployed_contract_address, 'balance_of', calldata_one).unwrap();
    assert(*return_data_one.at(1_u32) == 90, *return_data_one.at(1_u32));

    let mut calldata_two: Array<felt252> = ArrayTrait::new();
    calldata_two.append(address_two);

    let return_data_two: Array<felt252> = call(deployed_contract_address, 'balance_of', calldata_two).unwrap();
    assert(*return_data_two.at(1_u32) == 10, *return_data_two.at(1_u32));
}
