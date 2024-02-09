mod guild;

const ISRC6_ID: felt252 = 0x2ceccef7f994940b3962a6c67e0ba4fcd37df7d131417c604f91e03caecc1cd;

#[starknet::contract]
mod Guild {
    use openzeppelin::access::accesscontrol::interface::IAccessControlCamel;
use openzeppelin::access::accesscontrol::interface::IAccessControl;
use openzeppelin::access::accesscontrol::accesscontrol::AccessControlComponent::InternalTrait;
    use array::{ArrayTrait, SpanTrait};
    use box::BoxTrait;
    use core::clone::Clone;
    use core::serde::Serde;
    use ecdsa::check_ecdsa_signature;
    use option::OptionTrait;
    use starknet::{
        get_tx_info, get_caller_address, get_contract_address, ContractAddress, ClassHash,
        contract_address_const, contract_address::ContractAddressZeroable
    };
    use traits::{Into, TryInto};
    use guildly::certificate::interfaces::{ICertificateDispatcher, ICertificateDispatcherTrait};
    use guildly::guild::guild::{
        interfaces::{IGuild}, constants::{Roles, TokenStandard}, guild::{Call, Permission, Token}
    };
    use guildly::utils::{math_utils::MathUtils,};
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
    use zeroable::Zeroable;

    component!(path: AccessControlComponent, storage: access, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Access
    impl AccessControlInternalImpl = AccessControlComponent::AccessControl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        access: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        _name: felt252,
        _is_permissions_initialized: bool,
        _is_blacklisted: LegacyMap<ContractAddress, bool>,
        _is_permission: LegacyMap<(ContractAddress, felt252), bool>,
        _guild_certificate: ContractAddress,
        _current_nonce: felt252,
        _proxy_admin: ContractAddress
    }

    //
    // Events
    //

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        WhitelistMember: WhitelistMember,
        RemoveMember: RemoveMember,
        UpdateMemberRole: UpdateMemberRole,
        SetPermissions: SetPermissions,
        ExecuteCall: ExecuteCall,
        ExecuteTransaction: ExecuteTransaction,
        Deposit: Deposit,
        Withdraw: Withdraw,
    }

    #[external(v0)]
    impl Guild of IGuild<ContractState> {
        //
        // Initialize & upgrade
        //
        fn initialize(
            ref self: ContractState,
            name: felt252,
            master: ContractAddress,
            guild_certificate: ContractAddress,
            proxy_admin: ContractAddress
        ) {
            self._name.write(name);
            self._guild_certificate.write(guild_certificate);

            let contract_address = get_contract_address();
            ICertificateDispatcher { contract_address: guild_certificate }
                .mint(master, contract_address);

            self._proxy_admin.write(proxy_admin);
            self.access._set_role_admin(Roles::MEMBER, Roles::ADMIN);
            self.access._set_role_admin(Roles::OWNER, Roles::ADMIN);
            self.access.grant_role(Roles::ADMIN, proxy_admin)
        }
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.upgradeable._upgrade(new_class_hash)
        }
        //
        // Externals
        //
        fn add_member(ref self: ContractState, account: ContractAddress, role: felt252) {
            let guild_certificate = self._guild_certificate.read();
            let contract_address = get_contract_address();
            let caller_address = get_caller_address();

            // require_not_blacklisted(caller_address);
            ICertificateDispatcher { contract_address: guild_certificate }
                .mint(account, contract_address);
            self.access.grant_role(role, account);

            __event__WhitelistMember(ref self, account, role)
        }
        fn leave(ref self: ContractState) {
            let guild_certificate = self._guild_certificate.read();
            let contract_address = get_contract_address();
            let caller_address = get_caller_address();

            let certificate_id = ICertificateDispatcher { contract_address: guild_certificate }
                .get_certificate_id(caller_address, contract_address);

            let check = ICertificateDispatcher { contract_address: guild_certificate }
                .check_tokens_exist(certificate_id);

            assert(check == false, 'Account has items in guild');

            ICertificateDispatcher { contract_address: guild_certificate }
                .guild_burn(caller_address, contract_address);
            self.access.renounce_role(Roles::MEMBER, caller_address);
            self.access.renounce_role(Roles::OWNER, caller_address);
            self.access.renounce_role(Roles::ADMIN, caller_address);
        }
        fn remove_member(ref self: ContractState, account: ContractAddress) {
            let caller_address = get_caller_address();
            let contract_address = get_contract_address();
            let guild_certificate = self._guild_certificate.read();
            self.access.assert_only_role(Roles::ADMIN);
            let certificate_dispatcher = ICertificateDispatcher {
                contract_address: guild_certificate
            };
            let certificate_id = certificate_dispatcher
                .get_certificate_id(account, contract_address);
            let check = certificate_dispatcher.check_tokens_exist(certificate_id);

            assert(check == false, 'Member holds items in guild.');
            certificate_dispatcher.guild_burn(account, contract_address);

            self.access.revoke_role(Roles::MEMBER, account);
            self.access.revoke_role(Roles::OWNER, account);
            self.access.revoke_role(Roles::ADMIN, account);
            self._is_blacklisted.write(account, true);

            __event__RemoveMember(ref self, account)
        }
        fn force_transfer_item(ref self: ContractState, token: Token, account: ContractAddress) {
            let contract_address = get_contract_address();
            let guild_certificate = self._guild_certificate.read();
            let caller = get_caller_address();
            self.access.assert_only_role(Roles::ADMIN);

            let certificate_dispatcher = ICertificateDispatcher {
                contract_address: guild_certificate
            };
            let certificate_id = certificate_dispatcher
                .get_certificate_id(account, contract_address);

            assert(token.amount > u256 { low: 0_u128, high: 0_u128 }, 'Amount must be > 0.');

            if (token.token_standard == TokenStandard::ERC721) {
                let token_dispatcher = IERC721Dispatcher { contract_address: token.token };
                token_dispatcher.transfer_from(contract_address, account, token.token_id,);
                ICertificateDispatcher { contract_address: guild_certificate }
                    .change_token_data(
                        certificate_id,
                        token.token_standard,
                        token.token,
                        token.token_id,
                        u256 { low: 0_u128, high: 0_u128 },
                    );
            }
            if (token.token_standard == TokenStandard::ERC20) {
                let token_dispatcher = IERC721Dispatcher { contract_address: token.token };
                token_dispatcher.transfer_from(contract_address, account, token.token_id,);
                ICertificateDispatcher { contract_address: guild_certificate }
                    .change_token_data(
                        certificate_id,
                        token.token_standard,
                        token.token,
                        token.token_id,
                        u256 { low: 0_u128, high: 0_u128 },
                    );
            }
        // TODO: Add ERC1155 transfer method
        }
        fn update_roles(ref self: ContractState, account: ContractAddress, roles: felt252) {
            self.access.grant_role(roles, account)
        }
        fn deposit(
            ref self: ContractState,
            token_standard: u8,
            token: ContractAddress,
            token_id: u256,
            amount: u256
        ) {
            let caller_address = get_caller_address();
            self.access.assert_only_role(Roles::ADMIN);

            assert(amount > u256 { low: 0_u128, high: 0_u128 }, 'Guild: Amount cannot be 0');

            if token_standard == TokenStandard::ERC721 {
                assert(
                    amount == u256 { low: 1_u128, high: 0_u128 }, 'Guild: ERC721 amount must be 1'
                );
            }


            let guild_certificate = self._guild_certificate.read();
            let contract_address = get_contract_address();

            let certificate_dispatcher = ICertificateDispatcher {
                contract_address: guild_certificate
            };

            let certificate_id = certificate_dispatcher
                .get_certificate_id(caller_address, contract_address);

            let check_exists = certificate_dispatcher
                .check_token_exists(certificate_id, token_standard, token, token_id);

            if token_standard == TokenStandard::ERC721 {
                assert(check_exists, 'Caller already holds ERC721');
                let erc721_dispatcher = IERC721Dispatcher { contract_address: token };
                erc721_dispatcher.transfer_from(caller_address, contract_address, token_id);
                certificate_dispatcher
                    .add_token_data(certificate_id, token_standard, token, token_id, amount,);
            }
            if token_standard == TokenStandard::ERC20 {
                let erc20_dispatcher = IERC20Dispatcher { contract_address: token };
                erc20_dispatcher.transfer_from(caller_address, contract_address, amount);
                certificate_dispatcher
                    .add_token_data(certificate_id, token_standard, token, 0, amount,);
            }
                    // TODO: Add ERC1155 transfer method

            let initial_amount = certificate_dispatcher
                .get_token_amount(certificate_id, token_standard, token, token_id,);

            let new_amount = initial_amount + amount;

            __event__Deposit(
                ref self, caller_address, certificate_id, token_standard, token, token_id, amount,
            )
        }
        fn withdraw(
            ref self: ContractState,
            token_standard: u8,
            token: ContractAddress,
            token_id: u256,
            amount: u256
        ) {
            let caller_address = get_caller_address();
            self.access.assert_only_role(Roles::ADMIN);

            if token_standard == TokenStandard::ERC721 {
                assert(amount == u256 { low: 1_u128, high: 0_u128 }, 'ERC721 amount must be 1');
            }

            let guild_certificate = self._guild_certificate.read();
            let contract_address = get_contract_address();

            let certificate_dispatcher = ICertificateDispatcher {
                contract_address: guild_certificate
            };
            let certificate_id = certificate_dispatcher
                .get_certificate_id(caller_address, contract_address);

            let check_exists = certificate_dispatcher
                .check_token_exists(certificate_id, token_standard, token, token_id,);

            assert(check_exists, 'Caller has no tokens');

            if token_standard == TokenStandard::ERC721 {
                let erc721_dispatcher = IERC721Dispatcher { contract_address: token };
                erc721_dispatcher.transfer_from(contract_address, caller_address, token_id);
                certificate_dispatcher
                    .change_token_data(
                        certificate_id,
                        token_standard,
                        token,
                        token_id,
                        u256 { low: 0_u128, high: 0_u128 },
                    );
            }
                        if token_standard == TokenStandard::ERC20 {
                let erc20_dispatcher = IERC20Dispatcher { contract_address: token };
                erc20_dispatcher.transfer_from(caller_address, contract_address, amount);
                certificate_dispatcher
                    .add_token_data(certificate_id, token_standard, token, 0, amount,);
            }

            let initial_amount = certificate_dispatcher
                .get_token_amount(certificate_id, token_standard, token, token_id,);

            let new_amount = initial_amount - amount;

            __event__Withdraw(
                ref self, caller_address, certificate_id, token_standard, token, token_id, amount,
            )
        }
        fn execute(ref self: ContractState, mut calls: Array<Call>, nonce: felt252) {
            // check_gas();
            let caller = get_caller_address();
            self.access.assert_only_role(Roles::MEMBER);

            let current_nonce = self._current_nonce.read();
            assert(current_nonce == nonce, 'Guild: Invalid nonce');
            self._current_nonce.write(current_nonce + 1);

            let tx_info = get_tx_info().unbox();

            let response = _execute_calls(ref self, calls, ArrayTrait::<Span<felt252>>::new());
            // emit event
            __event__ExecuteTransaction(
                ref self, caller, tx_info.transaction_hash.try_into().unwrap()
            );
            return response;
        }
        fn initialize_permissions(ref self: ContractState, mut permissions: Array<Permission>) {
            self.access.assert_only_role(Roles::ADMIN);
            let permissions_initialized = self._is_permissions_initialized.read();
            assert(!permissions_initialized, 'Permissions already initialized');
            _set_permissions(ref self, 0, permissions);
            self._is_permissions_initialized.write(true)
        }
        fn set_permissions(ref self: ContractState, mut permissions: Array<Permission>) {
            _set_permissions(ref self, 0, permissions.clone());
            let caller = get_caller_address();
            __event__SetPermissions(ref self, caller, permissions.clone())
        }
        fn supports_interface(self: @ContractState, interfaceId: usize) -> bool {
            // ERC165::supports_interface(interfaceId)
            true
        }
        fn name(self: @ContractState) -> felt252 {
            self._name.read()
        }

        fn guild_certificate(self: @ContractState) -> ContractAddress {
            self._guild_certificate.read()
        }

        fn is_permissions_initialized(self: @ContractState) -> bool {
            self._is_permissions_initialized.read()
        }

        fn get_nonce(self: @ContractState) -> felt252 {
            self._current_nonce.read()
        }

        fn has_role(self: @ContractState, role: felt252, account: ContractAddress) -> bool {
            self.access.has_role(Roles::ADMIN, account)
        }
    }

    // Internals

    fn _execute_calls(
        ref self: ContractState, mut calls: Array<Call>, mut res: Array<Span<felt252>>
    ) {
        // check_gas();
        match calls.pop_front() {
            Option::Some(call) => {
                let _res = _execute_single_call(ref self, call);
                res.append(_res);
                return _execute_calls(ref self, calls, res);
            },
            Option::None(_) => { // return res;
            },
        }
    }

    fn _execute_single_call(ref self: ContractState, mut call: Call) -> Span<felt252> {
        let contract_address = get_contract_address();
        let caller = get_caller_address();
        let guild_certificate = self._guild_certificate.read();

        let Call{to, selector, calldata } = call;

        // Check the tranasction is permitted
        _check_permitted_call(@self, to, selector);

        let certificate_dispatcher = ICertificateDispatcher { contract_address: guild_certificate };

        let certificate_id = certificate_dispatcher.get_certificate_id(caller, contract_address);

        // Actually execute it
        let res = starknet::call_contract_syscall(to, selector, calldata.span()).unwrap();

        __event__ExecuteCall(ref self, caller, to, selector);

        return res;
    }

    fn _set_permissions(
        ref self: ContractState, permissions_index: usize, mut permissions: Array<Permission>
    ) {
        if permissions_index == permissions.len() {
            return ();
        }

        self
            ._is_permission
            .write(
                (
                    *permissions.at(permissions_index).to,
                    *permissions.at(permissions_index).selector
                ),
                true
            );

        return _set_permissions(ref self, permissions_index + 1_u32, permissions,);
    }

    fn _check_permitted_call(self: @ContractState, to: ContractAddress, selector: felt252) {
        let is_permitted = self._is_permission.read((to, selector));
        assert(is_permitted, 'Call is not permitted');
    }

    // EVENTS ------------------------------------ //

    #[derive(Drop, starknet::Event)]
    struct WhitelistMember {
        account: ContractAddress,
        role: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct RemoveMember {
        account: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct UpdateMemberRole {
        account: ContractAddress,
        new_role: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct SetPermissions {
        account: ContractAddress,
        permissions: Array<Permission>
    }

    #[derive(Drop, starknet::Event)]
    struct ExecuteCall {
        account: ContractAddress,
        contract: ContractAddress,
        selector: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct ExecuteTransaction {
        account: ContractAddress,
        hash: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct Deposit {
        account: ContractAddress,
        certificate_id: u256,
        token_standard: u8,
        token: ContractAddress,
        token_id: u256,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Withdraw {
        account: ContractAddress,
        certificate_id: u256,
        token_standard: u8,
        token: ContractAddress,
        token_id: u256,
        amount: u256,
    }

    fn __event__WhitelistMember(ref self: ContractState, account: ContractAddress, role: felt252,) {
        self.emit(Event::WhitelistMember(WhitelistMember { account, role }));
    }

    fn __event__RemoveMember(ref self: ContractState, account: ContractAddress,) {
        self.emit(Event::RemoveMember(RemoveMember { account }));
    }

    fn __event__UpdateMemberRole(
        ref self: ContractState, account: ContractAddress, new_role: felt252
    ) {
        self.emit(Event::UpdateMemberRole(UpdateMemberRole { account, new_role }));
    }

    fn __event__SetPermissions(
        ref self: ContractState, account: ContractAddress, permissions: Array<Permission>
    ) {
        self.emit(Event::SetPermissions(SetPermissions { account, permissions }));
    }

    fn __event__ExecuteCall(
        ref self: ContractState,
        account: ContractAddress,
        contract: ContractAddress,
        selector: felt252
    ) {
        self.emit(Event::ExecuteCall(ExecuteCall { account, contract, selector }));
    }

    fn __event__ExecuteTransaction(
        ref self: ContractState, account: ContractAddress, hash: ContractAddress,
    ) {
        self.emit(Event::ExecuteTransaction(ExecuteTransaction { account, hash }));
    }

    fn __event__Deposit(
        ref self: ContractState,
        account: ContractAddress,
        certificate_id: u256,
        token_standard: u8,
        token: ContractAddress,
        token_id: u256,
        amount: u256,
    ) {
        self
            .emit(
                Event::Deposit(
                    Deposit { account, certificate_id, token_standard, token, token_id, amount }
                )
            );
    }

    fn __event__Withdraw(
        ref self: ContractState,
        account: ContractAddress,
        certificate_id: u256,
        token_standard: u8,
        token: ContractAddress,
        token_id: u256,
        amount: u256,
    ) {
        self
            .emit(
                Event::Withdraw(
                    Withdraw { account, certificate_id, token_standard, token, token_id, amount }
                )
            );
    }
}
