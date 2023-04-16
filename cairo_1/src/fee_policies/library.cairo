use array::ArrayTrait;
use array::SpanTrait;

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_nn
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_lt, uint256_eq

from openzeppelin.security.safemath.library import SafeUint256

from contracts.fee_policies.constants import NetAssetFlow
from contracts.interfaces.IERC1155 import IERC1155
from contracts.utils.constants import SHIFT_SPLIT
from contracts.utils.general import unpack_data

struct TokenBalances {
    token: felt252,
    balances: Array<Span<u256>>
}

struct TokenDifferences {
    token: felt252,
    differences: Array<Span<u256>>
}

struct TokenDetails {
    token_standard: felt,
    token: felt252,
    ids: Array<Span<u256>>
}

mod FeePolicies {
    func pack_fee_splits(caller_split: felt252, owner_split: felt252, admin_split: felt252) -> felt252 {
        let caller = caller_split * SHIFT_SPLIT._1;
        let owner = owner_split * SHIFT_SPLIT._2;
        let admin = admin_split * SHIFT_SPLIT._3;

        let packed_splits = caller + owner + admin
    }

    func unpack_fee_splits(packed_splits: felt252) -> (felt252, felt252, felt252) {
        let caller_split = unpack_data(packed_splits, 0, 16383);
        let owner_split = unpack_data(packed_splits, 14, 16383);
        let admin_split = unpack_data(packed_splits, 28, 16383);
        return (caller_split, owner_split, admin_split);
    }

    func get_balances(accrued_token: felt252, accrued_token_ids: Array<Span<u256>>) -> Array<Span<u256>> {
        let owner = get_contract_address();
        let owners = ArrayTrait::new();

        loop_generate_owners(0, accrued_token_ids_len, owner, owners);

        let balances: ArrayTrait<Span<u256>> = IERC1155::balanceOfBatch(
            accrued_token, accrued_token_ids_len, owners, accrued_token_ids_len, accrued_token_ids
        )
    }

    func loop_generate_owners(index: felt252, token_ids_len: felt252, owner: ContractAddress, owners: Array<Span<ContractAddress>>) {
        if (index == token_ids_len) {
            return ();
        }

        owners.append(owner);

        return loop_generate_owners(index + 1, token_ids_len, owner, owners)
    }

    func calculate_differences(
        tokens_len: felt,
        pre_balances: Array<Span<TokenBalances>>,
        post_balances: Array<Span<TokenBalances>>,
        difference_balances: Array<Span<TokenDifferences>>,
    ) {
        if (tokens_len == 0) {
            return ();
        }
        loop_calculate_differences(
            0,
            [pre_balances].token_balances,
            [post_balances].token_balances,
            [difference_balances].token_differences,
        );

        return calculate_differences(
            tokens_len - 1,
            pre_balances + TokenBalances.SIZE,
            post_balances + TokenBalances.SIZE,
            difference_balances + TokenDifferences.SIZE,
        );
    }

    func loop_calculate_differences(
        token_ids_len: felt252,
        pre_balances: Array<Span<u256>>,
        post_balances: Array<Span<u256>>,
        difference_balances: Array<Span<felt252>>,
    ) {
        if (token_ids_len == 0) {
            return ();
        }

        uint256_check([pre_balances]);
        uint256_check([post_balances]);
        let diff = [post_balances].low - [pre_balances].low;
        assert [difference_balances] = diff;
        return loop_calculate_differences(
            token_ids_len - 1,
            pre_balances + Uint256.SIZE,
            post_balances + Uint256.SIZE,
            difference_balances + 1,
        );
    }

    func calculate_split_balances(
        index: felt252,
        difference_balances: Array<Span<TokenDifferences>>,
        caller_split: felt252,
        owner_split: felt252,
        admin_split: felt252,
        caller_balances: Array<Span<TokenBalances>>,
        owner_balances: Array<Span<TokenBalances>>,
        admin_balances: Array<SpanTokenBalances>>,
    ) {
        if (index == difference_balances_len) {
            return ();
        }

        loop_calculate_split_balances(
            0,
            difference_balances[index].token_differences_len,
            difference_balances[index].token_differences,
            caller_split,
            owner_split,
            admin_split,
            caller_balances[index].token_balances,
            owner_balances[index].token_balances,
            admin_balances[index].token_balances,
        );

        return calculate_split_balances(
            0,
            difference_balances_len,
            difference_balances,
            caller_split,
            owner_split,
            admin_split,
            caller_balances,
            owner_balances,
            admin_balances,
        );
    }

    func loop_calculate_split_balances(
        index: felt252,
        differences: Array<Span<felt252>>,
        caller_split: felt252,
        owner_split: felt252,
        admin_split: felt252,
        caller_balances: Array<Span<u256>>,
        owner_balances: Array<Span<u256>>,
        admin_balances: Array<Span<u256>>,
    ) {
        if (index == differences_len) {
            return ();
        }

        let flow_positive_check = is_nn(differences[index]);

        if (flow_positive_check == TRUE) {
            assert caller_balances[index] = Uint256(differences[index] * caller_split, 0);
            assert owner_balances[index] = Uint256(differences[index] * owner_split, 0);
            assert admin_balances[index] = Uint256(differences[index] * admin_split, 0);

            return loop_calculate_distribution_balances(
                index + 1,
                differences_len,
                differences,
                caller_split,
                owner_split,
                admin_split,
                caller_balances,
                owner_balances,
                admin_balances,
            );
        } else {
            return loop_calculate_distribution_balances(
                index + 1,
                differences_len,
                differences,
                caller_split,
                owner_split,
                admin_split,
                caller_balances,
                owner_balances,
                admin_balances,
            );
        }
    }
}
