%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

func get_owners{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt, owners: felt*
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