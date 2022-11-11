%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from contracts.fee_policies.library import FeePolicies

@external
func test_split_packing{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (packed_splits) = FeePolicies.pack_fee_splits(500, 8500, 1000);

    let (local caller_split, local owner_split, local admin_split) = FeePolicies.unpack_fee_splits(packed_splits);

    %{
        print(ids.caller_split)
        print(ids.owner_split)
        print(ids.admin_split)
    %}

    return ();
}