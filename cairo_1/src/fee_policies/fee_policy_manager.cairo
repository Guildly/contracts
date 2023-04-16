use starknet::ContractAddress;

from contracts.interfaces.IFeePolicy import IFeePolicy
from contracts.fee_policies.library import FeePolicies
from contracts.lib.module import Module
from contracts.lib.token_standard import TokenStandard

from openzeppelin.upgrades.library import Proxy

//
// Structs
//

struct PaymentDetails {
    payment_token_standard: felt252,
    payment_token: ContractAddress,
    payment_token_id: u256,
    payment_amount: u256,
}

struct PolicyTarget {
    to: ContractAddress,
    selector: ContractAddress,
}

#[contract]
mod FeePolicyManager {
    use starknet::ContractAddress;
    use starknet::syscalls::deploy_syscall;
    use starknet::call_contract_syscall;
    use starknet::get_caller_address;

    use upgrades::library::Proxy;
    use manager::IManager;
    use fee_policies::feelibrar

    struct Storage {
        _guild_manager: ContractAddress;
        _fee_policy: LegacyMap<ContractAddress, PolicyTarget>;
        _policy_distribution: LegacyMap<(ContractAddress, ContractAddress), felt252>;
        _guild_policy_count: LegacyMap<ContractAddress, felt252>;
        _guild_policy: LegacyMap<(ContractAddress, ContractAddress, ContractAddress), ContractAddress>;
        _direct_payments: LegacyMap<(ContractAddress, ContractAddress, felt252), PaymentDetails>;
    }

    //
    // Guards
    //

    #[internal]
    fn assert_only_guild() {
        let caller = get_caller_address();
        let guild_manager = _guild_manager::read();
        let check_guild = IGuildManager { contract_address: guild_manager }.get_is_guild(caller);
        assert(check_guild, "Guild Certificate: Contract is not valid")
    }

    #[internal]
    fn assert_policy(policy: felt252) {
        let policy_target = _fee_policy::read(policy);
        assert(!policy_target.to.is_zero())
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
    fn get_fee_policy(guild_address: felt252,, to: ContractAddress, selector: ContractAddress) -> ContractAddress {
        _guild_policy::read(guild_address, to, selector)
    }

    #[view]
    fn get_policy_target(policy: ContractAddress) -> PolicyTarget {
        _fee_policy::read(policy)
    }

    #[view]
    fn get_policy_distribution(guild_address: ContractAddress, fee_policy: ContractAddress) -> (felt252, felt252, felt252) {
        let distribution = _policy_distribution::read(guild_address, fee_policy);
        FeePolicies.unpack_fee_splits(distribution)
    }

    #[view]
    fn get_direct_payments(guild_address: ContractAddress, fee_policy: ContractAddress) -> Array<PaymentDetails> {
        let payment_details = ArrayTrait::new();
        loop {
            match gas::withdraw_gas_all(get_builtin_costs()) {
                Option::Some(_) => {},
                Option::None(_) => {
                    let mut err_data = ArrayTrait::new();
                    err_data.append(ref err_data, 'Out of gas');
                    panic(err_data)
                },
            }
            let direct_payment - direct_payments::read(guild_address, fee_policy, index);
            payment_details[index] = direct_payment;
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
        let policy_target = PolicyTarget(to, selector);
        _fee_policy::write(policy_target)
    }

    #[external]
    fn set_fee_policy(
        policy_address: ContractAddress, 
        caller_split: felt252,
        owner_split: felt252,
        admin_split: felt252,
        payment_details: Array<PaymentDetails>
    ) {
        assert_only_guild();
        let guild_address = get_caller_address();
        assert_policy(policy_address);
        // check splits are equal or under 100%
        assert(caller_split + owner_split + admin_split, 'Fee Policy Manager: splits cannot be over 100%');

        let policy_target: PolicyTarget = _fee_policy::read(policy_address);
        _guild_policy::write(guild_address, policy_target.to, policy_target.selector, policy_address);

        let packed_splits = FeePolicies::pack_fee_splits(caller_split, owner_split, admin_split);
        _policy_distribution::write(guild_address, policy_address, packed_splits);

        return loop_store_direct_payment(
            0,
            guild_address,
            policy_address,
            payment_details_len,
            payment_details,
        );
    }

    #[external]
    fn revoke_policy(policy_address: ContractAddress) {
        assert_only_guild();
        let guild_address = get_caller_address();
        assert_policy(policy_address);
        let policy_target: PolicyTarget = _fee_policy::read(policy_address);
        _guild_policy::write(guild_address, policy_target.to, policy_target.selector, 0)
    }

    #[internal]
    fn loop_store_direct_payment(
        index: felt252, 
        guild_address: ContractAddress, 
        fee_policy: ContractAddress,
        payment_details: Array<PaymentDetails>
    ) {
        if (index == payment_details.len()) {
            return ();
        }
        _direct_payments::write(guild_address, fee_policy, index, payment_details[index]);
        loop_store_direct_payment(index + 1, guild_address, fee_policy, payment_details)
    }

}