%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_lt, uint256_eq

from openzeppelin.security.safemath.library import SafeUint256

from contracts.fee_policies.constants import NetAssetFlow
from contracts.interfaces.IERC1155 import IERC1155
from contracts.utils.constants import SHIFT_SPLIT
from contracts.utils.general import unpack_data

struct TokenBalances {
    token: felt,
    token_balances_len: felt,
    token_balances: Uint256*,
}

struct TokenBalancesArray {
    token: felt,
    token_balances_offset: felt,
    token_balances_len: felt,
}

struct TokenDetails {
    token_standard: felt,
    token: felt,
    token_ids_len: felt,
    token_ids: Uint256*,
}

// Tmp struct introduced while we wait for Cairo
// to support passing '[TokenDetails]' to __execute__
struct TokenArray {
    token_standard: felt,
    token: felt,
    token_ids_offset: felt,
    token_ids_len: felt,
}

namespace FeePolicies {
    func pack_fee_splits{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(caller_split: felt, owner_split: felt, admin_split: felt) -> (packed_splits: felt) {
        let caller = caller_split * SHIFT_SPLIT._1;
        let owner = owner_split * SHIFT_SPLIT._2;
        let admin = admin_split * SHIFT_SPLIT._3;

        let packed_splits = caller + owner + admin;

        return (packed_splits,);
    }

    func unpack_fee_splits{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(packed_splits: felt) -> (caller_split: felt, owner_split: felt, admin_split: felt) {
        alloc_locals;

        let (caller_split) = unpack_data(packed_splits, 0, 16383);
        let (owner_split) = unpack_data(packed_splits, 14, 16383);
        let (admin_split) = unpack_data(packed_splits, 28, 16383);

        return (caller_split, owner_split, admin_split);
    }

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

    func calculate_differences{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokens_len: felt,
        pre_balances: TokenBalances*,
        post_balances: TokenBalances*,
        difference_balances: TokenBalances*
    ) -> (asset_flow: felt) {
        if (tokens_len == 0) {
            return ();
        }
        loop_calculate_differences(
            0,
            [pre_balances].token_balances,
            [post_balances].token_balances,
            [difference_balances].token_balances
        );

        calculate_differences(
            tokens_len - 1,
            pre_balances + TokenBalances.SIZE,
            post_balances + TokenBalances.SIZE,
            difference_balances + TokenBalances.SIZE
        );
        return (NetAssetFlow.POSITIVE);
    }

    func loop_calculate_differences{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_ids_len: felt,
        pre_balances: Uint256*,
        post_balances: Uint256*,
        difference_balances: Uint256*
    ) {
        if (token_ids_len == 0) {
            return ();
        }

        uint256_check([pre_balances]);
        uint256_check([post_balances]);
        let (is_lt) = uint256_lt([post_balances], [pre_balances]);
        if (is_lt == TRUE) {
            let (diff: Uint256) = SafeUint256.sub_le([post_balances], [pre_balances]);
            return (NetAssetFlow.NEGATIVE);
        }
        let (is_eq) = uint256_eq([pre_balances], [post_balances]);
        if (is_eq == TRUE) {
            return (NetAssetFlow.NEUTRAL);
        }
        let (diff: Uint256) = SafeUint256.sub_le([pre_balances], [post_balances]);
        assert [difference_balances] = diff;
        return loop_calculate_differences(
            token_ids_len, - 1,
            pre_balances + Uint256.SIZE,
            post_balances + Uint256.SIZE,
            difference_balances + Uint256.SIZE
        );
    }

    func from_token_array_to_tokens{syscall_ptr: felt*} (
        token_array_len: felt, 
        token_array: TokenArray*, 
        token_ids: felt*, 
        token_details: TokenDetails*
    ) {
        // if no more tokens
        if (token_array_len == 0) {
            return ();
        }

        // parse the current call
        assert [token_details] = TokenDetails(
            to=[token_array].to,
            selector=[token_array].selector,
            token_ids_len=[token_array].token_ids_len,
            token_ids=token_ids + [token_array].token_ids_offset
            );

        // parse the remaining calls recursively
        return from_token_array_to_tokens(
            token_array_len - 1, 
            token_array + TokenArray.SIZE, 
            token_ids, 
            token_details + TokenDetails.SIZE
        );
    }
}
