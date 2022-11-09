%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from contracts.lib.role import GuildRoles

from contracts.access_control.accesscontrol_library import AccessControl

const FAKE_OWNER_ADDR = 20;

@external
func test_grant_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}() {

    AccessControl.grant_role(GuildRoles.MEMBER, FAKE_OWNER_ADDR);

    let role = AccessControl.get_roles(FAKE_OWNER_ADDR);

    assert role = GuildRoles.MEMBER;

    return();
}

@external
func test_grant_roles{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}() {

    AccessControl.grant_role(GuildRoles.MEMBER + GuildRoles.OWNER, FAKE_OWNER_ADDR);

    let roles = AccessControl.get_roles(FAKE_OWNER_ADDR);

    AccessControl.has_role(GuildRoles.MEMBER, FAKE_OWNER_ADDR);
    AccessControl.has_role(GuildRoles.OWNER, FAKE_OWNER_ADDR);

    return();
}

@external
func test_revoke_all_roles{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}() {

    AccessControl.grant_role(GuildRoles.MEMBER, FAKE_OWNER_ADDR);
    AccessControl.grant_role(GuildRoles.OWNER, FAKE_OWNER_ADDR);

    let roles = AccessControl.get_roles(FAKE_OWNER_ADDR);

    AccessControl.revoke_role(roles, FAKE_OWNER_ADDR);

    let new_roles = AccessControl.get_roles(FAKE_OWNER_ADDR);

    assert new_roles = 0;

    return ();
}