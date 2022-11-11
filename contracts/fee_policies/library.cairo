
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from contracts.utils.constants import SHIFT_SPLIT
from contracts.utils.general import unpack_data

namespace FeePolicies {
    func pack_fee_splits{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (caller_split: felt, owner_split: felt, admin_split: felt) -> (packed_splits: felt) {

        let caller = caller_split * SHIFT_SPLIT._1;
        let owner = owner_split * SHIFT_SPLIT._2;
        let admin = admin_split * SHIFT_SPLIT._3;

        let packed_splits = caller + owner + admin;

        return (packed_splits,);
    }

    func unpack_fee_splits{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (packed_splits: felt) -> (caller_split: felt, owner_split: felt, admin_split: felt) {
        alloc_locals;

        let (caller_split) = unpack_data(packed_splits, 0, 16383);
        let (owner_split) = unpack_data(packed_splits, 14, 16383);
        let (admin_split) = unpack_data(packed_splits, 28, 16383);
        
        return (caller_split, owner_split, admin_split);
    }
}