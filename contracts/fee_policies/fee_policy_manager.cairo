%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from contracts.interfaces.IGuildManager import IGuildManager
from contracts.interfaces.IFeePolicy import IFeePolicy
from contracts.fee_policies.library import FeePolicies
from contracts.lib.module import Module
from contracts.lib.token_standard import TokenStandard

from openzeppelin.upgrades.library import Proxy

//
// Structs
//

struct PaymentDetails {
    payment_token_standard: felt,
    payment_token: felt,
    payment_token_id: Uint256,
    payment_amount: Uint256,
}

struct PolicyTarget {
    to: felt,
    selector: felt,
}

//
// Storage variables
//

@storage_var
func _guild_manager() -> (res: felt) {
}

@storage_var
func fee_policy(policy: felt) -> (policy_target: PolicyTarget) {
}

@storage_var
func policy_distribution(guild_address: felt, fee_policy: felt) -> (distribution: felt) {
}

@storage_var
func guild_policy_count(guild_address: felt) -> (res: felt) {
}

@storage_var
func guild_policy(guild_address: felt, to: felt, selector: felt) -> (fee_policy: felt) {
}

@storage_var
func direct_payments(guild_address: felt, fee_policy: felt, index: felt) -> (payment_details: PaymentDetails) {
}

//
// Guards
//

func assert_only_guild{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller) = get_caller_address();
    let (guild_manager) = _guild_manager.read();
    let (check_guild) = IGuildManager.get_is_guild(guild_manager, caller);
    with_attr error_message("Guild Certificate: Contract is not valid") {
        assert check_guild = TRUE;
    }
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

//
// Initialize & upgrade
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt
) {
    // Module.initializer(controller_address);
    Proxy.initializer(proxy_admin);
    return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(implementation);
    return ();
}

//
// Getters
//

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
func get_policy_distribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(guild_address: felt, fee_policy: felt) -> (
    caller_split: felt, owner_split: felt, admin_split: felt
) {
    let (distribution) = policy_distribution.read(guild_address, fee_policy);
    let (caller_split, owner_split, admin_split) = FeePolicies.unpack_fee_splits(distribution);
    return (caller_split, owner_split, admin_split);
}

@view
func get_direct_payments{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    guild_address: felt,
    fee_policy: felt
) -> (
    direct_payments_len: felt,
    direct_payments: PaymentDetails*
) {
    alloc_locals;
    let (direct_payments: PaymentDetails*) = alloc();

    loop_get_direct_payment(
        0,
        guild_address,
        fee_policy,
        direct_payments
    );

    return (3, direct_payments);
}

func loop_get_direct_payment{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
} (
    index: felt,
    guild_address: felt,
    fee_policy: felt,
    payments: PaymentDetails*
) {
    let (payment_details) = direct_payments.read(guild_address, fee_policy, index);

    assert payments[index] = payment_details;

    return loop_get_direct_payment(
        index + 1,
        guild_address,
        fee_policy,
        payments
    );
}

//
// Externals
//

@external
func add_policy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    policy: felt, to: felt, selector: felt
) {
    // Module.only_arbiter();
    let policy_target = PolicyTarget(to, selector);
    fee_policy.write(policy, policy_target);
    return ();
}

@external
func set_fee_policy{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
} (
    policy_address: felt, 
    caller_split: felt, 
    owner_split: felt, 
    admin_split: felt,
    payment_details_len: felt,
    payment_details: PaymentDetails*
) {
    alloc_locals;
    assert_only_guild();
    let (guild_address) = get_caller_address();
    assert_policy(policy_address);
    // check splits are equal or under 100%
    with_attr error_message("Fee Policy Manager: splits cannot be over 100%") {
        assert_le(caller_split + owner_split + admin_split, 10000);
    }

    let (policy_target: PolicyTarget) = fee_policy.read(policy_address);

    guild_policy.write(guild_address, policy_target.to, policy_target.selector, policy_address);

    let (packed_splits) = FeePolicies.pack_fee_splits(caller_split, owner_split, admin_split);

    policy_distribution.write(guild_address, policy_address, packed_splits);

    return loop_store_direct_payment(
        0,
        guild_address,
        policy_address,
        payment_details_len,
        payment_details,
    );
}

@external
func revoke_policy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    policy_address: felt
) {
    alloc_locals;
    assert_only_guild();
    let (guild_address) = get_caller_address();
    assert_policy(policy_address);

    let (policy_target: PolicyTarget) = fee_policy.read(policy_address);
    guild_policy.write(guild_address, policy_target.to, policy_target.selector, 0);
    return ();
}

// Internals

func loop_store_direct_payment{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    index: felt,
    guild_address: felt,
    fee_policy: felt,
    payment_details_len: felt,
    payment_details: PaymentDetails*
) {
    if (index == payment_details_len) {
        return ();
    }

    direct_payments.write(guild_address, fee_policy, index, payment_details[index]);
    return loop_store_direct_payment(
        index + 1,
        guild_address,
        fee_policy,
        payment_details_len,
        payment_details
    );
}

// func loop_execute_payments{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     index: felt,
//     guild_address: felt,
//     fee_policy: felt,
// ) {
//     if (payment_tokens_len == payment_tokens_len) {
//         return ();
//     }
//     let (payment_details) = direct_payments.read(guild_address, fee_policy, index);

//     if (payment_details.token_standard == TokenStandard.ERC721) {

//     }
//     return loop_store_direct_payment(
//         index + 1,
//         guild_address,
//         fee_policy,
//         payment_tokens_len,
//         payment_token_standards,
//         payment_tokens,
//         payment_token_ids,
//         payment_amounts
//     );
// }

