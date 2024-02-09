use core::clone::Clone;
use core::serde::Serde;
use array::ArrayTrait;
use starknet::ContractAddress;

#[derive(Clone, Drop, Serde)]
struct TokenBalances {
    token: felt252,
    balances: Array<u256>
}

#[derive(Clone, Drop, Serde)]
struct TokenDifferences {
    token: felt252,
    differences: Array<felt252>
}

#[derive(Clone, Drop, Serde)]
struct TokenDetails {
    token_standard: u8,
    token: ContractAddress,
    ids: Array<u256>
}
