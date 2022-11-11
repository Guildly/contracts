%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.starknet.common.syscalls import get_caller_address

from contracts.interfaces.IFeePolicy import IFeePolicy
from contracts.fee_policies.library import FeePolicies
from contracts.lib.module import Module

from openzeppelin.upgrades.library import Proxy

struct PolicyDistribution {
    caller_split: felt,
    owner_split: felt,
    admin_split: felt
}

struct PolicyTarget {
    to: felt,
    selector: felt,
}

@storage_var
func fee_policy(policy: felt) -> (policy_target: PolicyTarget) {
}

@storage_var
func policy_distribution(guild_address: felt, fee_policy: felt) -> (
    distribution: felt
) {
}

@storage_var
func guild_policy_count(guild_address: felt) -> (res: felt) {
}

@storage_var
func guild_policy(guild_address: felt, to: felt, selector: felt) -> (fee_policy: felt) {
}

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt
) {
    // Module.initializer(controller_address);
    Proxy.initializer(proxy_admin);
    return ();
}

@view
func get_fee_policy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    guild_address: felt, to: felt, selector: felt
) -> (policy: felt) {
    let (policy) = guild_policy.read(guild_address, to, selector);
    return (policy,);
}

@view
func get_policy_target{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    policy: felt
) -> (policy_target: PolicyTarget) {
    let (policy_target: PolicyTarget) = fee_policy.read(policy);
    return (policy_target,);
}

@view
func get_policy_distribution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    guild_address: felt, fee_policy: felt
) -> (caller_split: felt, owner_split: felt, admin_split: felt) {
    let (distribution) = policy_distribution.read(guild_address, fee_policy);
    let (caller_split, owner_split, admin_split) = FeePolicies.unpack_fee_splits(distribution);
    return (distribution.caller_split, distribution.owner_split, distribution.admin_split);
}

@external
func add_policy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    policy: felt, to: felt, selector: felt
) {
    // TODO: check only arbiter/ module controller
    // Module.only_approved();
    // TODO: check policy already added
    // let (stored_policy) = 
    // with_attr error_message("Fee Policy Manager: Policy already added.") {
    //     assert_not_equal(policy
    // }
    let policy_target = PolicyTarget(to, selector);
    fee_policy.write(policy, policy_target);
    return ();
}

@external
func set_fee_policy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    policy_address: felt, caller_split: felt, owner_split: felt, admin_split: felt
) {
    alloc_locals;
    // TODO: Check guild calling
    // Module.only_approved();
    let (guild_address) = get_caller_address();
    assert_policy(policy_address);

    let (policy_target: PolicyTarget) = fee_policy.read(policy_address);

    guild_policy.write(guild_address, policy_target.to, policy_target.selector, policy_address);

    let packed_splits = FeePolicies.pack_splits(caller_split, owner_split, admin_split);

    policy_distribution.write(guild_address, policy_address, packed_splits);
    return ();
}

@external
func revoke_policy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    policy_address: felt
) {
    alloc_locals;
    // TODO: Check guild calling
    // Module.only_approved();
    let (guild_address) = get_caller_address();
    assert_policy(policy_address);

    let (policy_target: PolicyTarget) = fee_policy.read(policy_address);
    guild_policy.write(guild_address, policy_target.to, policy_target.selector, 0);
    return ();
}

func assert_policy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(policy: felt) {
    let (policy_target) = fee_policy.read(policy);
    let check_not_zero = is_not_zero(policy_target.to);
    with_attr error_message("Fee Policy Manager: Policy does not exist") {
        assert check_not_zero = TRUE;
    }
    return ();
}
