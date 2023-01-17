%lang starknet

from contracts.fee_policies.fee_policy_manager import PolicyTarget, PaymentDetails

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
    func get_direct_payments(guild_address: felt, fee_policy: felt) -> (
        direct_payments_len: felt, direct_payments: PaymentDetails*
    ) {
    }
    func add_policy(policy: felt, to: felt, selector: felt) {
    }

    func set_fee_policy(
        policy_address: felt, 
        caller_split: felt, 
        owner_split: felt, 
        admin_split: felt,
        payment_details_len: felt,
        payment_details: PaymentDetails*
    ) {
    }

    func revoke_policy(policy_address: felt) {
    }
}
