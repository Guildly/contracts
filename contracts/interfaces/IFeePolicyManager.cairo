%lang starknet

from contracts.fee_policies.fee_policy_manager import PolicyDistribution, PolicyTarget

@contract_interface
namespace IFeePolicyManager {
    func has_fee_policy(guild_address: felt, fee_policy: felt) -> (res: felt) {
    }
    func get_fee_policy(guild_address: felt, to: felt, selector: felt) -> (res: felt) {
    }

    func get_policy_target(fee_policy: felt) -> (policy_target: PolicyTarget) {
    }

    func get_policy_distribution(guild_address: felt, fee_policy: felt) -> (
        caller_split: felt, owner_split: felt, admin_split: felt
    ) {
    }

    func add_policy(policy: felt, to: felt, selector: felt) {
    }

    func set_fee_policy(
        policy_address: felt, caller_split: felt, owner_split: felt, admin_split: felt
    ) {
    }

    func revoke_policy(policy_address: felt) {
    }
}
