use core::serde::Serde;
use array::ArrayTrait;
use starknet::ContractAddress;

impl ArrayFelt252Copy of Copy<Array<felt252>>;

#[derive(Drop, Serde)]
struct Call {
    to: ContractAddress,
    selector: felt252,
    calldata: Array<felt252>
}

#[derive(Copy, Drop, Serde)]
struct Permission {
    to: ContractAddress,
    selector: felt252,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
struct Token {
    token_standard: u8,
    token: ContractAddress,
    token_id: u256,
    amount: u256,
}
