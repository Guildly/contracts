use array::ArrayTrait;
use array::SpanTrait;
use serde::Serde;
use openzeppelin::utils::check_gas;
use option::OptionTrait;
use starknet::ContractAddress;
use starknet::StorageAccess;
use starknet::StorageBaseAddress;
use starknet::SyscallResult;
use starknet::storage_access;
use starknet::storage_read_syscall;
use starknet::storage_write_syscall;
use starknet::storage_base_address_from_felt252;
use starknet::storage_address_from_base_and_offset;
use traits::Into;
use traits::TryInto;

#[derive(Copy, Drop, Serde)]
struct PolicyTarget {
    to: ContractAddress,
    selector: ContractAddress,
}

#[derive(Copy, Drop, Serde)]
struct TokenBalances {
    token: felt252,
    balances: Array<u256>
}

#[derive(Copy, Drop, Serde)]
struct TokenDifferences {
    token: felt252,
    differences: Array<felt252>
}

#[derive(Copy, Drop, Serde)]
struct TokenDetails {
    token_standard: felt252,
    token: ContractAddress,
    ids: Array<u256>
}

impl ArrayFeltCopy of Copy::<Array<felt252>>;
impl ArrayU256Copy of Copy::<Array<u256>>;


impl PolicyTargetStorageAccess of StorageAccess::<PolicyTarget> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<PolicyTarget> {
        Result::Ok(
            PolicyTarget {
                to: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 0_u8)
                )?.try_into().unwrap(),
                selector: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 1_u8)
                )?.try_into().unwrap(),
            }
        )
    }

    fn write(address_domain: u32, base: StorageBaseAddress, value: PolicyTarget) -> SyscallResult::<()> {
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 0_u8), value.to.into()
        )?;
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 1_u8), value.selector.into()
        )
    }
}

impl ArrayTokenDetailsSerde of Serde::<Array<TokenDetails>> {
    fn serialize(ref output: Array<felt252>, mut input: Array<TokenDetails>) {
        Serde::<usize>::serialize(ref output, input.len());
        serialize_array_token_details_helper(ref output, input);
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<Array<TokenDetails>> {
        let length = *serialized.pop_front()?;
        let mut arr = ArrayTrait::new();
        deserialize_array_token_details_helper(ref serialized, arr, length)
    }
}

fn serialize_array_token_details_helper(ref output: Array<felt252>, mut input: Array<TokenDetails>) {
    check_gas();
    match input.pop_front() {
        Option::Some(value) => {
            Serde::<TokenDetails>::serialize(ref output, value);
            serialize_array_token_details_helper(ref output, input);
        },
        Option::None(_) => {},
    }
}

fn deserialize_array_token_details_helper(
    ref serialized: Span<felt252>, mut curr_output: Array<TokenDetails>, remaining: felt252
) -> Option<Array<TokenDetails>> {
    if remaining == 0 {
        return Option::Some(curr_output);
    }

    check_gas();

    curr_output.append(Serde::<TokenDetails>::deserialize(ref serialized)?);
    deserialize_array_token_details_helper(ref serialized, curr_output, remaining - 1)
}

impl ArrayTokenBalancesCopy of Copy::<Array<TokenBalances>>;

