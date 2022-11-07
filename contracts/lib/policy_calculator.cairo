%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from openzeppelin.security.safemath.library import SafeUint256
from starkware.cairo.common.math import unsigned_div_rem

from contracts.interfaces.IERC1155 import IERC1155
from starkware.starknet.common.syscalls import get_contract_address

namespace PolicyCalculator {
    func get_balances{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        accrued_token: felt,
        accrued_token_ids_len: felt,
        accrued_token_ids: Uint256*
    ) -> (balances_len: felt, balances: Uint256*) {
        alloc_locals;

        let (owner) = get_contract_address();
        let (owners: felt*) = alloc();

        loop_generate_owners(
            0,
            accrued_token_ids_len,
            owner,
            owners
        );

        let (balances_len, balances: Uint256*) = IERC1155.balanceOfBatch(
            accrued_token, 
            accrued_token_ids_len, 
            owners,
            accrued_token_ids_len, 
            accrued_token_ids
        );

        return (balances_len, balances);
    }

    func loop_generate_owners{range_check_ptr}(
        index: felt, token_ids_len: felt, owner, owners: felt*
    ) {
        if (index == token_ids_len) {
            return ();
        }

        assert owners[index] = owner;

        return loop_generate_owners(
            index + 1,
            token_ids_len,
            owner,
            owners
        );
    }

    func calculate_splits{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        balances_len: felt,
        pre_balances: Uint256*,
        post_balances: Uint256*,
        caller_split: felt,
        owner_split: felt,
        admin_split: felt,
        caller_balances: Uint256*,
        owner_balances: Uint256*,
        admin_balances: Uint256*
    ) {
        if (balances_len == 0) {
            return ();
        }
        let (diff: Uint256) = SafeUint256.sub_le([post_balances], [pre_balances]);
        let (caller_balance, _) = unsigned_div_rem(caller_split * diff.low, 100);
        let (owner_balance, _) = unsigned_div_rem(owner_split * diff.low, 100);
        let (admin_balance, _) = unsigned_div_rem(admin_split * diff.low, 100);
        assert [caller_balances] = Uint256(caller_balance, 0);
        assert [owner_balances] = Uint256(owner_balance, 0);
        assert [admin_balances] = Uint256(admin_balance, 0);
        return calculate_splits(
            balances_len - 1,
            pre_balances + Uint256.SIZE,
            post_balances + Uint256.SIZE,
            caller_split,
            owner_split,
            admin_split,
            caller_balances + Uint256.SIZE,
            owner_balances + Uint256.SIZE,
            admin_balances + Uint256.SIZE
        );
    }
}