use array::ArrayTrait;
use core::serde::Serde;
use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, starknet::Store)]
struct Token {
    token_standard: u8,
    token: ContractAddress,
    token_id: u256,
    amount: u256,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
struct PolicyTarget {
    to: ContractAddress,
    selector: felt252,
}
