use array::ArrayTrait;
use array::SpanTrait;
use serde::Serde;
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
use option::OptionTrait;
use openzeppelin::utils::check_gas;

impl ArrayFeltCopy of Copy::<Array<felt252>>;
impl ArrayU256Copy of Copy::<Array<u256>>;


mod FeePolicies {
    use array::ArrayTrait;
    use integer::upcast;
    use option::OptionTrait;
    use starknet::ContractAddress;
    use starknet::get_contract_address;

    use openzeppelin::token::erc1155::IERC1155Dispatcher;
    use openzeppelin::token::erc1155::IERC1155DispatcherTrait;

    use guildly::fee_policies::constants_fee_policy::NetAssetFlow;
    use guildly::fee_policies::constants_fee_policy::ShiftSplit;
    use guildly::utils::bit_packing::unpack_data;

    use traits::Into;
    use traits::TryInto;

    use guildly::implementations::policy::TokenDifferences;
    use guildly::implementations::policy::TokenBalances;
    use guildly::implementations::policy::ArrayTokenBalancesCopy;


    fn pack_fee_splits(caller_split: felt252, owner_split: felt252, admin_split: felt252) -> felt252 {
        let caller = caller_split * ShiftSplit::_1;
        let owner = owner_split * ShiftSplit::_2;
        let admin = admin_split * ShiftSplit::_3;
        caller + owner + admin
    }

    fn unpack_fee_splits(packed_splits: felt252) -> (usize, usize, usize) {
        let caller_split = unpack_data(packed_splits, 0, 16383);
        let owner_split = unpack_data(packed_splits, 14, 16383);
        let admin_split = unpack_data(packed_splits, 28, 16383);
        return (upcast(caller_split), upcast(owner_split), upcast(admin_split));
    }

    fn get_balances(accrued_token: felt252, acquired_token_ids: Array<u256>) -> Array<u256> {
        let owner = get_contract_address();
        let owners = ArrayTrait::new();

        loop_generate_owners(0, acquired_token_ids.len(), owner, owners);

        // let erc1155_dispatcher = IERC1155Dispatcher { contract_address: accrued_token };

        IERC1155Dispatcher { contract_address: accrued_token }.balance_of_batch(
           owners, acquired_token_ids
        )
    }

    fn loop_generate_owners(index: usize, token_ids_len: usize, owner: ContractAddress, mut owners: Array<ContractAddress>) {
        if index == token_ids_len {
            return ();
        }

        owners.append(owner);

        loop_generate_owners(index + 1_usize, token_ids_len, owner, owners)
    }

    fn calculate_differences(
        index: usize,
        tokens_len: usize,
        pre_balances: Array<TokenBalances>,
        post_balances: Array<TokenBalances>,
        difference_balances: Array<TokenDifferences>,
    ) {
        if tokens_len == 0_usize {
            return ();
        }
        let pre_balance = *pre_balances.at(index);
        let post_balance = *post_balances.at(index);
        let difference_balance = *difference_balances.at(index);
        loop_calculate_differences(
            0_usize,
            pre_balances.at(index).balances.len(),
            pre_balance.balances,
            post_balance.balances,
            difference_balance.differences,
        );

        return calculate_differences(
            index + 1_usize,
            tokens_len - 1_usize,
            pre_balances,
            post_balances,
            difference_balances,
        );
    }

    fn loop_calculate_differences(
        index: usize,
        token_ids_len: usize,
        pre_balances: Array<u256>,
        post_balances: Array<u256>,
        mut difference_balances: Array<felt252>,
    ) {
        if token_ids_len == 0_usize {
            return ();
        }
        let post_balance = *post_balances.at(index);
        let pre_balance = *pre_balances.at(index);
        let diff = post_balance.low.into() - pre_balance.low.into();
        difference_balances.append(diff);
        return loop_calculate_differences(
            index + 1_usize,
            token_ids_len - 1_usize,
            pre_balances,
            post_balances,
            difference_balances,
        );
    }

    fn calculate_distribution_balances(
        index: usize,
        difference_balances: Array<TokenDifferences>,
        caller_split: usize,
        owner_split: usize,
        admin_split: usize,
        caller_balances: Array<TokenBalances>,
        mut owner_balances: Array<TokenBalances>,
        mut admin_balances: Array<TokenBalances>,
    ) {

        if index == difference_balances.len() {
            return ();
        }

        let difference_balance = *difference_balances.at(index);
        let caller_balance = *caller_balances.at(index);
        let owner_balance = *owner_balances.at(index);
        let admin_balance = *admin_balances.at(index);

        loop_calculate_distribution_balances(
            0_usize,
            difference_balance.differences,
            caller_split,
            owner_split,
            admin_split,
            caller_balance.balances,
            owner_balance.balances,
            admin_balance.balances,
        );

        return calculate_distribution_balances(
            0,
            difference_balances,
            caller_split,
            owner_split,
            admin_split,
            caller_balances,
            owner_balances,
            admin_balances,
        );
    }

    fn test_usize(
        value: usize
    ) {
        let value_felt: felt252 = value.into();
        let value_u128: u128 = value_felt.try_into().unwrap();
        return ();
    }

    fn loop_calculate_distribution_balances(
        index: usize,
        differences: Array<felt252>,
        caller_split: usize,
        owner_split: usize,
        admin_split: usize,
        mut caller_balances: Array<u256>,
        mut owner_balances: Array<u256>,
        mut admin_balances: Array<u256>,
    ) {
        if index == differences.len() {
            return ();
        }
        let difference_balance = *differences.at(index);

        if (difference_balance.into() >= u256 { low: 0_u128, high: 0_u128 }) {
            caller_balances.append(difference_balance.into() * u256 { low: caller_split.into().try_into().unwrap(), high: 0_u128 });
            owner_balances.append(difference_balance.into() * u256 { low: owner_split.into().try_into().unwrap(), high: 0_u128 });
            admin_balances.append(difference_balance.into() * u256 { low: admin_split.into().try_into().unwrap(), high: 0_u128 });

            return loop_calculate_distribution_balances(
                index,
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
                index + 1_usize,
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
