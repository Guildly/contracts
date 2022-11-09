%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.bitwise import bitwise_and, bitwise_not, bitwise_or
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.math_cmp import is_not_zero

from contracts.access_control.aliases import address, bool, ufelt

//
// Events
//

@event
func RoleGranted(role: ufelt, account: address) {
}

@event
func RoleRevoked(role: ufelt, account: address) {
}

@event
func AdminChanged(prev_admin: address, new_admin: address) {
}

//
// Storage
//

@storage_var
func accesscontrol_admin() -> (admin: address) {
}

@storage_var
func accesscontrol_roles(account: address) -> (role: ufelt) {
}

namespace AccessControl {
    //
    // Initializer
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        admin: address
    ) {
        _set_admin(admin);
        return ();
    }

    //
    // Modifier
    //

    func assert_has_role{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(role: ufelt) {
        alloc_locals;
        let (caller: address) = get_caller_address();
        let authorized: bool = has_role(role, caller);
        with_attr error_message("AccessControl: caller is missing role {role}") {
            assert authorized = TRUE;
        }
        return ();
    }

    func assert_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        alloc_locals;
        let (caller: address) = get_caller_address();
        let admin: address = accesscontrol_admin.read();
        with_attr error_message("AccessControl: caller is not admin") {
            assert caller = admin;
        }
        return ();
    }

    //
    // Getters
    //

    func get_roles{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: address
    ) -> ufelt {
        let (roles: ufelt) = accesscontrol_roles.read(account);
        return roles;
    }

    func has_role{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(role: ufelt, account: address) -> bool {
        let (roles: ufelt) = accesscontrol_roles.read(account);
        // masks roles such that all bits are zero, except the bit(s) representing `role`, which may be zero or one
        let (masked_roles: ufelt) = bitwise_and(roles, role);
        let authorized: bool = is_not_zero(masked_roles);
        return authorized;
    }

    func get_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> address {
        let (admin: address) = accesscontrol_admin.read();
        return admin;
    }

    //
    // Externals
    //

    func grant_role{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(role: ufelt, account: address) {
        // Change from AccessControl Admin to guild ADMIN
        // assert_admin();
        let (admin) = accesscontrol_admin.read();
        with_attr error_message("AccessControl: cannot change master role") {
            assert_not_equal(account, admin);
        }
        _grant_role(role, account);
        return ();
    }

    func revoke_role{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(role, account) {
        // Change from AccessControl Admin to guild ADMIN
        // assert_admin();
        let (admin) = accesscontrol_admin.read();
        with_attr error_message("AccessControl: cannot change master role") {
            assert_not_equal(account, admin);
        }
        _revoke_role(role, account);
        return ();
    }

    func renounce_role{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(role: ufelt, account: address) {
        let (caller: address) = get_caller_address();
        with_attr error_message("AccessControl: can only renounce roles for self") {
            assert account = caller;
        }
        _revoke_role(role, account);
        return ();
    }

    func change_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        new_admin: address
    ) {
        assert_admin();
        _set_admin(new_admin);
        return ();
    }

    //
    // Unprotected
    //

    func _grant_role{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(role: ufelt, account: address) {
        let (roles: ufelt) = accesscontrol_roles.read(account);
        let (updated_roles: ufelt) = bitwise_or(roles, role);
        accesscontrol_roles.write(account, updated_roles);
        RoleGranted.emit(role, account);
        return ();
    }

    func _revoke_role{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(role: ufelt, account: address) {
        let (roles: ufelt) = accesscontrol_roles.read(account);
        let (revoked_complement: ufelt) = bitwise_not(role);
        let (updated_roles: ufelt) = bitwise_and(roles, revoked_complement);
        accesscontrol_roles.write(account, updated_roles);
        RoleRevoked.emit(role, account);
        return ();
    }

    func _set_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        new_admin: address
    ) {
        let prev_admin: address = accesscontrol_admin.read();
        accesscontrol_admin.write(new_admin);
        AdminChanged.emit(prev_admin, new_admin);
        return ();
    }
}