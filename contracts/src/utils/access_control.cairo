#[starknet::contract]
mod AccessControl {
    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    // use test::test_utils::assert_eq;

    #[event]
    fn RoleGranted(role: felt252, account: ContractAddress) {}

    #[event]
    fn RoleRevoked(role: felt252, account: ContractAddress) {}

    #[event]
    fn AdminChanged(prev_admin: ContractAddress, new_admin: ContractAddress) {}

    #[storage]
    struct Storage {
        _admin: ContractAddress,
        _roles: LegacyMap<ContractAddress, felt252>,
    }

    #[external(v0)]
    fn initializer(ref self: ContractState, admin: ContractAddress) {
        _set_admin(ref self, admin)
    }

    #[external(v0)]
    fn get_roles(self: @ContractState, account: ContractAddress) -> felt252 {
        self._roles.read(account)
    }

    #[external(v0)]
    fn has_role(self: @ContractState, role: felt252, account: ContractAddress) -> bool {
        let roles = self._roles.read(account);
        // masks roles such that all bits are zero, except the bit(s) representing `role`, which may be zero or one
        // let masked_roles = bitand(upcast(roles), upcast(role));
        // masked_roles.is_zero()
        return true;
    }

    #[external(v0)]
    fn get_admin(self: @ContractState, ) -> ContractAddress {
        self._admin.read()
    }

    #[external(v0)]
    fn grant_role(ref self: ContractState, role: felt252, account: ContractAddress) {
        // Change from AccessControl Admin to guild ADMIN
        assert_admin(@self);
        let admin = self._admin.read();
        assert(account != admin, 'Cannot change master role');
        _grant_role(ref self, role, account)
    }

    #[external(v0)]
    fn revoke_role(ref self: ContractState, role: felt252, account: ContractAddress) {
        // Change from AccessControl Admin to guild ADMIN
        assert_admin(@self);
        let admin = self._admin.read();
        assert(account != admin, 'Cannot change master role"');
        _revoke_role(ref self, role, account)
    }

    #[external(v0)]
    fn renounce_role(ref self: ContractState, role: felt252, account: ContractAddress) {
        let caller = get_caller_address();
        assert(account == caller, 'Only renounce roles for self');
        _revoke_role(ref self, role, account)
    }

    #[external(v0)]
    fn change_admin(ref self: ContractState, new_admin: ContractAddress) {
        assert_admin(@self);
        _set_admin(ref self, new_admin)
    }

    fn assert_has_role(ref self: ContractState, role: felt252) {
        let caller = get_caller_address();
        let authorized = has_role(@self, role, caller);
        assert(authorized, 'Caller is missing role {role}');
    }

    fn assert_admin(self: @ContractState) {
        let caller = get_caller_address();
        let admin = self._admin.read();
        assert(caller == admin, 'Caller is not admin');
    }

    fn _grant_role(ref self: ContractState, role: felt252, account: ContractAddress) {
        // let roles = self._roles.read(account);
        // let updated_roles = roles & role;
        // self._roles.write(account, updated_roles);
        RoleGranted(role, account)
    }

    fn _revoke_role(ref self: ContractState, role: felt252, account: ContractAddress) {
        // let roles = self._roles.read(account);
        // let revoked_complement = ~role;
        // let updated_roles = roles & revoked_complement;
        // self._roles.write(account, updated_roles);
        RoleRevoked(role, account)
    }

    fn _set_admin(ref self: ContractState, new_admin: ContractAddress) {
        let prev_admin = self._admin.read();
        self._admin.write(new_admin);
        AdminChanged(prev_admin, new_admin)
    }
}
