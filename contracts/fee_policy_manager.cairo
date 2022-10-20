%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.lib.module import Module
from openzeppelin.upgrades.library import Proxy

struct PolicyDistribution {
    caller_split: felt,
    owner_split: felt
}

@storage_var
func fee_policy(contract_address: felt, selector: felt) -> (res: felt) {
}

@storage_var
func policy_distribution(fee_policy: felt) -> (distribution: PolicyDistribution) {
}


@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    module_controller: felt, proxy_admin: felt
) {
    Module.initializer(module_controller);
    Proxy.initializer(proxy_admin);
    return();
}

@view
func get_fee_policy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_address: felt, selector: felt
) -> (policy: felt) {
    let (policy) = fee_policy.read(contract_address, selector);
    return (policy,);
}

@external
func set_fee_policy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_address: felt, selector: felt, caller_split: felt, owner_split: felt, guild_split: felt, policy_address: felt
) {
    Module.only_approved();
    fee_policy.write(contract_address, selector, policy_address);
    return ();
}

@view
func get_policy_distributions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fee_policy: felt
) -> (distribution: felt) {
    let (caller_split, owner_split) = policy_distribution.read(fee_policy);
    return (caller_split, owner_split);
}