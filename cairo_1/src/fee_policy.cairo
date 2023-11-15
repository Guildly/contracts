mod fee_policy;

#[starknet::contract]
mod FeePolicy {
    use array::ArrayTrait;
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::{ContractAddress, get_contract_address};
    use guildly::guild::guild::guild::Call;
    use guildly::fee_policy::fee_policy::{
        constants::{NetAssetFlow, ShiftSplit},
        interfaces::{IFeePolicy, TokenBalances, TokenDifferences, TokenDetails},
    };

    #[storage]
    struct Storage {
        _realms_contract: ContractAddress,
        _resources_contract: ContractAddress,
    }

    #[external(v0)]
    impl FeePolicy of IFeePolicy<ContractState> {
        fn get_tokens(
            self: @ContractState, to: ContractAddress, selector: felt252, calldata: Array<felt252>
        ) -> (Array<TokenDetails>, Array<TokenDetails>) {
            // let Call {to, selector, calldata } = call;
            // let realm_id_low = calldata[0];
            // let realm_id_high = calldata[1];
            // let realm_id = Uint256(
            //     realm_id_low,
            //     realm_id_high
            // );
            // let realms_address = self._realms_contract.read();
            // let resources_address = self._resources_contract.read();

            // let used_token_ids = ArrayTrait::new();
            // used_token_ids[0] = realm_id;

            // let accrued_token_ids = get_resources();

            // let (accrued_token_array: TokenArray*) = alloc();
            // assert accrued_token_array[0] = TokenArray(
            //     1,
            //     resources_address,
            //     0,
            //     RESOURCES_LENGTH
            // );

            let used_token_ids = ArrayTrait::<TokenDetails>::new();
            let accrued_token_ids = ArrayTrait::<TokenDetails>::new();

            return (used_token_ids, accrued_token_ids, );
        }

        fn get_balances(self: @ContractState) -> Array<TokenBalances> {
            // let owner = get_contract_address();
            // let owners = ArrayTrait::new();

            // loop_generate_owners(ref self, 0, acquired_token_ids.len(), owner, owners);

            // // let erc1155_dispatcher = IERC1155Dispatcher { contract_address: accrued_token };

            // IERC1155Dispatcher { contract_address: accrued_token }.balance_of_batch(
            // owners, acquired_token_ids
            // )
            let output = ArrayTrait::<TokenBalances>::new();
            return output;
        }

        fn check_owner_balances(
            self: @ContractState, feedata: Span<felt252>, owner_balances: Array<u256>
        ) -> bool {
            return true;
        }
    }

    fn calculate_differences(
        ref self: ContractState,
        index: usize,
        tokens_len: usize,
        pre_balances: Array<TokenBalances>,
        post_balances: Array<TokenBalances>,
        difference_balances: Array<TokenDifferences>,
    ) {
        if tokens_len == 0_usize {
            return ();
        }
        let pre_balance = pre_balances.at(index);
        let post_balance = post_balances.at(index);
        let difference_balance = difference_balances.at(index);
        // _loop_calculate_differences(
        //     ref self,
        //     0_usize,
        //     pre_balances.at(index).balances.len(),
        //     pre_balance.balances,
        //     post_balance.balances,
        //     difference_balance.differences,
        // );

        return calculate_differences(
            ref self,
            index + 1_usize,
            tokens_len - 1_usize,
            pre_balances,
            post_balances,
            difference_balances,
        );
    }

    fn pack_fee_splits(
        ref self: ContractState, caller_split: felt252, owner_split: felt252, admin_split: felt252
    ) -> felt252 {
        let caller = caller_split * ShiftSplit::_1;
        let owner = owner_split * ShiftSplit::_2;
        let admin = admin_split * ShiftSplit::_3;
        caller + owner + admin
    }

    fn unpack_fee_splits(ref self: ContractState, packed_splits: felt252) -> (usize, usize, usize) {
        // let caller_split = unpack_data(packed_splits, 0, 16383);
        // let owner_split = unpack_data(packed_splits, 14, 16383);
        // let admin_split = unpack_data(packed_splits, 28, 16383);
        // return (caller_split.try_into().unwrap(), owner_split.try_into().unwrap(), admin_split.try_into().unwrap());
        return (0_usize, 0_usize, 0_usize);
    }

    fn _loop_generate_owners(
        ref self: ContractState,
        index: usize,
        token_ids_len: usize,
        owner: ContractAddress,
        mut owners: Array<ContractAddress>
    ) {
        if index == token_ids_len {
            return ();
        }

        owners.append(owner);

        _loop_generate_owners(ref self, index + 1_usize, token_ids_len, owner, owners)
    }

    fn _loop_calculate_differences(
        ref self: ContractState,
        index: usize,
        token_ids_len: usize,
        pre_balances: @Array<u256>,
        post_balances: @Array<u256>,
        mut difference_balances: Array<felt252>,
    ) {
        if token_ids_len == 0_usize {
            return ();
        }
        let post_balance = post_balances.at(index);
        let pre_balance = pre_balances.at(index);
        // let diff = post_balance.low.into() - pre_balance.low.into();
        // difference_balances.append(diff);
        return _loop_calculate_differences(
            ref self,
            index + 1_usize,
            token_ids_len - 1_usize,
            pre_balances,
            post_balances,
            difference_balances,
        );
    }

    fn calculate_distribution_balances(
        ref self: ContractState,
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

        let difference_balance = difference_balances.at(index);
        let caller_balance = caller_balances.at(index);
        let owner_balance = owner_balances.at(index);
        let admin_balance = admin_balances.at(index);

        // loop_calculate_distribution_balances(
        //     ref self,
        //     0_usize,
        //     *difference_balance.differences,
        //     caller_split,
        //     owner_split,
        //     admin_split,
        //     *caller_balance.balances,
        //     *owner_balance.balances,
        //     *admin_balance.balances,
        // );

        return calculate_distribution_balances(
            ref self,
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

    fn loop_calculate_distribution_balances(
        ref self: ContractState,
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
            caller_balances
                .append(
                    difference_balance.into() * u256 { low: caller_split.into(), high: 0_u128 }
                );
            owner_balances
                .append(difference_balance.into() * u256 { low: owner_split.into(), high: 0_u128 });
            admin_balances
                .append(difference_balance.into() * u256 { low: admin_split.into(), high: 0_u128 });

            return loop_calculate_distribution_balances(
                ref self,
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
                ref self,
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
