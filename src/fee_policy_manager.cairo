mod fee_policy_manager;
mod interfaces;

#[starknet::contract]
mod FeePolicyManager {
    use array::ArrayTrait;
    use zeroable::Zeroable;
    use starknet::{
        ClassHash, ContractAddress, call_contract_syscall, get_caller_address,
        contract_address::ContractAddressZeroable
    };
    use traits::{Into, TryInto};
    use guildly::guild_manager::guild_manager::interfaces::{
        IGuildManagerDispatcher, IGuildManagerDispatcherTrait
    };
    use guildly::fee_policy_manager::{
        interfaces::IFeePolicyManager, fee_policy_manager::{Token, PolicyTarget}
    };
    use guildly::fee_policy::FeePolicy;
    use guildly::guild::guild::constants::TokenStandard;
    use openzeppelin::upgrades::upgradeable::Upgradeable;

    #[storage]
    struct Storage {
        _guild_manager: ContractAddress,
        _fee_policy: LegacyMap<ContractAddress, PolicyTarget>,
        _policy_distribution: LegacyMap<(ContractAddress, ContractAddress), felt252>,
        _guild_policy_count: LegacyMap<ContractAddress, felt252>,
        _guild_policy: LegacyMap<(ContractAddress, ContractAddress, felt252), ContractAddress>,
        _direct_payments: LegacyMap<(ContractAddress, ContractAddress, u32), Token>,
        _proxy_admin: ContractAddress,
    }

    #[external(v0)]
    impl FeePolicyManager of IFeePolicyManager<ContractState> {
        //
        // Initialize & upgrade
        //
        fn initialize(ref self: ContractState, proxy_admin: ContractAddress) {
            self._proxy_admin.write(proxy_admin)
        }
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            let mut upgradable_state = Upgradeable::unsafe_new_contract_state();
            Upgradeable::InternalImpl::_upgrade(ref upgradable_state, new_class_hash)
        }
        //
        // Externals
        //
        fn add_policy(
            ref self: ContractState, policy: ContractAddress, to: ContractAddress, selector: felt252
        ) {
            let policy_target = PolicyTarget { to, selector };
            self._fee_policy.write(policy, policy_target)
        }
        fn set_fee_policy(
            ref self: ContractState,
            policy_address: ContractAddress,
            caller_split: usize,
            owner_split: usize,
            admin_split: usize,
            payment_details: Array<Token>
        ) {
            _assert_only_guild(@self);
            let guild_address = get_caller_address();
            _assert_policy(@self, policy_address);
            // check splits are equal or under 100%
            assert(
                caller_split + owner_split + admin_split <= 10000_usize,
                'Splits cannot be over 100%'
            );

            let policy_target: PolicyTarget = self._fee_policy.read(policy_address);
            self
                ._guild_policy
                .write((guild_address, policy_target.to, policy_target.selector), policy_address);

            let mut fee_policy_state = FeePolicy::unsafe_new_contract_state();
            let packed_splits = FeePolicy::pack_fee_splits(
                ref fee_policy_state, caller_split.into(), owner_split.into(), admin_split.into()
            );
            self._policy_distribution.write((guild_address, policy_address), packed_splits);

            return _loop_store_direct_payment(
                ref self, 0_usize, guild_address, policy_address, payment_details, 
            );
        }
        fn revoke_policy(ref self: ContractState, policy_address: ContractAddress) {
            _assert_only_guild(@self);
            let guild_address = get_caller_address();
            _assert_policy(@self, policy_address);
            let policy_target: PolicyTarget = self._fee_policy.read(policy_address);
            let PolicyTarget{to, selector } = policy_target;
            self._guild_policy.write((guild_address, to, selector), ContractAddressZeroable::zero())
        }
        //
        // Getters
        //
        fn get_fee_policy(
            self: @ContractState,
            guild_address: ContractAddress,
            to: ContractAddress,
            selector: felt252
        ) -> ContractAddress {
            self._guild_policy.read((guild_address, to, selector))
        }
        fn get_policy_target(self: @ContractState, policy: ContractAddress) -> PolicyTarget {
            self._fee_policy.read(policy)
        }
        fn get_policy_distribution(
            self: @ContractState, guild_address: ContractAddress, fee_policy: ContractAddress
        ) -> (usize, usize, usize) {
            let distribution = self._policy_distribution.read((guild_address, fee_policy));
            let mut fee_policy_state = FeePolicy::unsafe_new_contract_state();
            FeePolicy::unpack_fee_splits(ref fee_policy_state, distribution)
        }
        fn get_direct_payments(
            self: @ContractState, guild_address: ContractAddress, fee_policy: ContractAddress
        ) -> Array<Token> {
            let mut payment_details = ArrayTrait::<Token>::new();
            let mut index = 0_usize;
            loop {
                let direct_payment = self._direct_payments.read((guild_address, fee_policy, index));
                payment_details.append(direct_payment);
                if index == 0_usize {
                    break ();
                }
                index -= 1_usize;
            };
            payment_details
        }
    }

    //
    // Internals
    //

    fn _assert_only_guild(self: @ContractState) {
        let caller = get_caller_address();
        let guild_manager = self._guild_manager.read();
        let manager_dispatcher = IGuildManagerDispatcher { contract_address: guild_manager };
        let check_guild = manager_dispatcher.get_is_guild(caller);
        assert(check_guild, 'Guild is not valid');
    }

    fn _assert_policy(self: @ContractState, policy: ContractAddress) {
        let policy_target = self._fee_policy.read(policy);
        assert(!policy_target.to.is_zero(), 'Policy is not valid')
    }

    fn _loop_store_direct_payment(
        ref self: ContractState,
        index: u32,
        guild_address: ContractAddress,
        fee_policy: ContractAddress,
        payment_details: Array<Token>
    ) {
        if index == payment_details.len() {
            return ();
        }
        self._direct_payments.write((guild_address, fee_policy, index), *payment_details.at(index));
        _loop_store_direct_payment(
            ref self, index + 1_u32, guild_address, fee_policy, payment_details
        )
    }
}
