use array::ArrayTrait;
use starknet::ContractAddress;
use guildly::implementations::token::Token;
use guildly::implementations::policy::PolicyTarget;


#[abi]
trait IFeePolicyManager {
    fn has_fee_policy(guild: ContractAddress, fee_policy: ContractAddress) -> bool; 
    fn get_fee_policy(guild: ContractAddress, to: ContractAddress, selector: felt252) -> ContractAddress;
    fn get_policy_target(fee_policy: ContractAddress) -> PolicyTarget;
    fn get_policy_distribution(guild: ContractAddress, fee_policy: ContractAddress) -> (usize, usize, usize);
    fn get_direct_payments(guild: ContractAddress, fee_policy: ContractAddress) -> Array<Token>;
    fn add_policy(policy: ContractAddress, to: ContractAddress, selector: felt252);
    fn set_fee_policy(
        policy_address: ContractAddress, 
        caller_split: usize, 
        owner_split: usize, 
        admin_split: usize,
        payment_details: Array<Token>
    );
    fn revoke_policy(policy_address: ContractAddress);
}

#[contract]
mod FeePolicyManager {
    use array::ArrayTrait;
    use integer::upcast;
    use zeroable::Zeroable;
    use starknet::ContractAddress;
    use starknet::ContractAddressZeroable;
    use starknet::syscalls::deploy_syscall;
    use starknet::call_contract_syscall;
    use starknet::get_caller_address;

    use openzeppelin::upgrades::library::Proxy;

    use guildly::implementations::token::Token;
    use guildly::implementations::token::ArrayTokenCopy;
    use guildly::implementations::policy::PolicyTarget;
    use guildly::fee_policies::library_fee_policy::FeePolicies;
    use guildly::constants::TokenStandard;

    struct Storage {
        _guild_manager: ContractAddress,
        _fee_policy: LegacyMap<ContractAddress, PolicyTarget>,
        _policy_distribution: LegacyMap<(ContractAddress, ContractAddress), felt252>,
        _guild_policy_count: LegacyMap<ContractAddress, felt252>,
        _guild_policy: LegacyMap<(ContractAddress, ContractAddress, ContractAddress), ContractAddress>,
        _direct_payments: LegacyMap<(ContractAddress, ContractAddress, u32), Token>,
    }

    #[abi]
    trait IManager {
        fn get_is_guild(address: ContractAddress) -> bool;
    }


    //
    // Guards
    //

    #[internal]
    fn assert_only_guild() {
        let caller = get_caller_address();
        let guild_manager = _guild_manager::read();
        let manager_dispatcher = IManagerDispatcher { contract_address: guild_manager };
        let check_guild = manager_dispatcher.get_is_guild(caller);
        assert(check_guild, 'Guild is not valid');
    }

    #[internal]
    fn assert_policy(policy: ContractAddress) {
        let policy_target = _fee_policy::read(policy);
        let PolicyTarget { to, selector } = policy_target;
        assert(!to.is_zero(), 'Policy is not valid')
    }

    //
    // Initialize & upgrade
    //

    #[external]
    fn initializer() {
        Proxy::initializer(proxy_admin)
    }

    #[external]
    fn upgrade(implementation: ContractAddress) {
        Proxy::assert_only_admin();
        Proxy::_set_implementation_hash(implementation)
    }

    //
    // Getters
    //

    #[view]
    fn get_fee_policy(guild_address: ContractAddress, to: ContractAddress, selector: ContractAddress) -> ContractAddress {
        _guild_policy::read((guild_address, to, selector))
    }

    #[view]
    fn get_policy_target(policy: ContractAddress) -> PolicyTarget {
        _fee_policy::read(policy)
    }

    #[view]
    fn get_policy_distribution(guild_address: ContractAddress, fee_policy: ContractAddress) -> (usize, usize, usize) {
        let distribution = _policy_distribution::read((guild_address, fee_policy));
        FeePolicies::unpack_fee_splits(distribution)
    }

    #[view]
    fn get_direct_payments(guild_address: ContractAddress, fee_policy: ContractAddress) -> Array<Token> {
        let mut payment_details = ArrayTrait::<Token>::new();
        let mut index = 0_usize;
        loop {
            match gas::withdraw_gas_all(get_builtin_costs()) {
                Option::Some(_) => {},
                Option::None(_) => {
                    let mut err_data = array::array_new();
                    array::array_append(ref err_data, 'Out of gas');
                    panic(err_data)
                },
            }
            let direct_payment = _direct_payments::read((guild_address, fee_policy, index));
            payment_details.append(direct_payment);
            if index == 0_usize {
                break payment_details;
            }
            index -= 1_usize;
        }
    }

    //
    // Externals
    //

    #[external]
    fn add_policy(policy: ContractAddress, to: ContractAddress, selector: ContractAddress) {
        let policy_target = PolicyTarget { to, selector };
        _fee_policy::write(policy, policy_target)
    }

    #[external]
    fn set_fee_policy(
        policy_address: ContractAddress, 
        caller_split: usize,
        owner_split: usize,
        admin_split: usize,
        payment_details: Array<Token>
    ) {
        assert_only_guild();
        let guild_address = get_caller_address();
        assert_policy(policy_address);
        // check splits are equal or under 100%
        assert(caller_split + owner_split + admin_split <= 10000_usize, 'Splits cannot be over 100%');

        let policy_target: PolicyTarget = _fee_policy::read(policy_address);
        _guild_policy::write((guild_address, policy_target.to, policy_target.selector), policy_address);

        let packed_splits = FeePolicies::pack_fee_splits(upcast(caller_split), upcast(owner_split), upcast(admin_split));
        _policy_distribution::write((guild_address, policy_address), packed_splits);

        return loop_store_direct_payment(
            0_usize,
            guild_address,
            policy_address,
            payment_details,
        );
    }

    #[external]
    fn revoke_policy(policy_address: ContractAddress) {
        assert_only_guild();
        let guild_address = get_caller_address();
        assert_policy(policy_address);
        let policy_target: PolicyTarget = _fee_policy::read(policy_address);
        let PolicyTarget { to, selector } = policy_target;
        _guild_policy::write((guild_address, to, selector), ContractAddressZeroable::zero())
    }

    #[internal]
    fn loop_store_direct_payment(
        index: u32, 
        guild_address: ContractAddress, 
        fee_policy: ContractAddress,
        payment_details: Array<Token>
    ) {
        if upcast(index) == payment_details.len() {
            return ();
        }
        _direct_payments::write((guild_address, fee_policy, index), *payment_details.at(index));
        loop_store_direct_payment(index + 1_u32, guild_address, fee_policy, payment_details)
    }

}