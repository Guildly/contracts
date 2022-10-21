%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.uint256 import Uint256

func get_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    resources: Uint256*
) {
    let (RESOURCES_ARR) = get_label_location(resource_start);
    return (resources=cast(RESOURCES_ARR, Uint256*));

    resource_start:
    dw 1;
    dw 0;
    dw 2;
    dw 0;
    dw 3;
    dw 0;
    dw 4;
    dw 0;
    dw 5;
    dw 0;
    dw 6;
    dw 0;
    dw 7;
    dw 0;
    dw 8;
    dw 0;
    dw 9;
    dw 0;
    dw 10;
    dw 0;
    dw 11;
    dw 0;
    dw 12;
    dw 0;
    dw 13;
    dw 0;
    dw 14;
    dw 0;
    dw 15;
    dw 0;
    dw 16;
    dw 0;
    dw 17;
    dw 0;
    dw 18;
    dw 0;
    dw 19;
    dw 0;
    dw 20;
    dw 0;
    dw 21;
    dw 0;
    dw 22;
    dw 0;
}

func get_owners{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (
    owners: felt*
) {
    let (owners: felt*) = alloc();
    assert [owners] = address;
    assert [owners + 1] = address;
    assert [owners + 2] = address;
    assert [owners + 3] = address;
    assert [owners + 4] = address;
    assert [owners + 5] = address;
    assert [owners + 6] = address;
    assert [owners + 7] = address;
    assert [owners + 8] = address;
    assert [owners + 9] = address;
    assert [owners + 10] = address;
    assert [owners + 11] = address;
    assert [owners + 12] = address;
    assert [owners + 13] = address;
    assert [owners + 14] = address;
    assert [owners + 15] = address;
    assert [owners + 16] = address;
    assert [owners + 17] = address;
    assert [owners + 18] = address;
    assert [owners + 19] = address;
    assert [owners + 20] = address;
    assert [owners + 21] = address;
    return (owners=owners);
}