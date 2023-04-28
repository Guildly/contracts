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
struct Token {
    token_standard: felt252,
    token: ContractAddress,
    token_id: u256,
    amount: u256,
}

impl TokenStorageAccess of StorageAccess::<Token> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<Token> {
        Result::Ok(
            Token {
                token_standard: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 0_u8)
                )?,
                token: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 1_u8)
                )?.try_into().unwrap(),
                token_id: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 2_u8)
                )?.into(),
                amount: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 3_u8)
                )?.into(),
            }
        )
    }

    fn write(address_domain: u32, base: StorageBaseAddress, value: Token) -> SyscallResult::<()>  {
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 0_u8), value.token_standard
        )?;
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 1_u8), value.token.into()
        )?;
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 2_u8), value.token_id.low.into()
        )?;
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 3_u8), value.amount.low.into()
        )
    }
}

impl ArrayTokenCopy of Copy::<Array<Token>>;

impl ArrayTokenSerde of Serde::<Array<Token>> {
    fn serialize(ref output: Array<felt252>, mut input: Array<Token>) {
        Serde::<usize>::serialize(ref output, input.len());
        serialize_array_token_helper(ref output, input);
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<Array<Token>> {
        let length = *serialized.pop_front()?;
        let mut arr = ArrayTrait::new();
        deserialize_array_token_helper(ref serialized, arr, length)
    }
}

fn serialize_array_token_helper(ref output: Array<felt252>, mut input: Array<Token>) {
    check_gas();
    match input.pop_front() {
        Option::Some(value) => {
            Serde::<Token>::serialize(ref output, value);
            serialize_array_token_helper(ref output, input);
        },
        Option::None(_) => {},
    }
}

fn deserialize_array_token_helper(
    ref serialized: Span<felt252>, mut curr_output: Array<Token>, remaining: felt252
) -> Option<Array<Token>> {
    if remaining == 0 {
        return Option::Some(curr_output);
    }

    check_gas();

    curr_output.append(Serde::<Token>::deserialize(ref serialized)?);
    deserialize_array_token_helper(ref serialized, curr_output, remaining - 1)
}