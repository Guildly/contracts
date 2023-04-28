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

#[derive(Copy, Serde, LegacyHash)]
struct Permission {
    to: ContractAddress,
    selector: felt252,
}

impl ArrayPermissionCopy of Copy::<Array<Permission>>;
impl ArrayPermissionDrop of Drop::<Array<Permission>>;

impl ArrayPermissionSerde of Serde::<Array<Permission>> {
    fn serialize(ref output: Array<felt252>, mut input: Array<Permission>) {
        Serde::<usize>::serialize(ref output, input.len());
        serialize_array_permission_helper(ref output, input);
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<Array<Permission>> {
        let length = *serialized.pop_front()?;
        let mut arr = ArrayTrait::new();
        deserialize_array_permission_helper(ref serialized, arr, length)
    }
}

fn serialize_array_permission_helper(ref output: Array<felt252>, mut input: Array<Permission>) {
    check_gas();
    match input.pop_front() {
        Option::Some(value) => {
            Serde::<Permission>::serialize(ref output, value);
            serialize_array_permission_helper(ref output, input);
        },
        Option::None(_) => {},
    }
}

fn deserialize_array_permission_helper(
    ref serialized: Span<felt252>, mut curr_output: Array<Permission>, remaining: felt252
) -> Option<Array<Permission>> {
    if remaining == 0 {
        return Option::Some(curr_output);
    }

    check_gas();

    curr_output.append(Serde::<Permission>::deserialize(ref serialized)?);
    deserialize_array_permission_helper(ref serialized, curr_output, remaining - 1)
}