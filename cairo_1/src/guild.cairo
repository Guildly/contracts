mod guild;

const ISRC6_ID: felt252 = 0x2ceccef7f994940b3962a6c67e0ba4fcd37df7d131417c604f91e03caecc1cd;

#[starknet::contract]
mod Guild {
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
        interfaces::{IGuild}, constants::{Roles, TokenStandard}, guild::{Call, Permission}
    };
    use guildly::fee_policy::{
        FeePolicy,
        fee_policy::{
            interfaces::{IFeePolicyDispatcher, IFeePolicyDispatcherTrait}, constants::Recipient,
            fee_policy::{TokenDetails, TokenBalances, TokenDifferences}
        }
    };
    use guildly::fee_policy_manager::{
        interfaces::{IFeePolicyManagerDispatcher, IFeePolicyManagerDispatcherTrait},
        fee_policy_manager::Token
    };
    use guildly::utils::{access_control::AccessControl, math_utils::MathUtils, };
    use openzeppelin::upgrades::upgradeable::Upgradeable;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
    use zeroable::Zeroable;

    #[storage]
    struct Storage {
        _name: felt252,
        _is_permissions_initialized: bool,
        _is_blacklisted: LegacyMap<ContractAddress, bool>,
        _is_permission: LegacyMap<(ContractAddress, felt252), bool>,
        _guild_certificate: ContractAddress,
        _fee_policy_manager: ContractAddress,
        _current_nonce: felt252,
        _proxy_admin: ContractAddress
    }

    //
    // Events
    //

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
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
            fee_policy_manager: ContractAddress,
            proxy_admin: ContractAddress
        ) {
            self._name.write(name);
            self._guild_certificate.write(guild_certificate);
            self._fee_policy_manager.write(fee_policy_manager);

            let contract_address = get_contract_address();
            ICertificateDispatcher {
                contract_address: guild_certificate
            }.mint(master, contract_address);

            self._proxy_admin.write(proxy_admin);
            let mut access_control_state = AccessControl::unsafe_new_contract_state();
            AccessControl::_set_admin(ref access_control_state, master);
        //SRC5::register_interface(ISRC6_ID)
        }
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            // let mut unsafe_state = src5::SRC5::unsafe_new_contract_state();
            let mut upgradable_state = Upgradeable::unsafe_new_contract_state();
            Upgradeable::InternalImpl::_upgrade(ref upgradable_state, new_class_hash)
        }
        //
        // Externals
        //
        fn add_member(ref self: ContractState, account: ContractAddress, role: felt252) {
            let guild_certificate = self._guild_certificate.read();
            let contract_address = get_contract_address();
            let caller_address = get_caller_address();

            // require_not_blacklisted(caller_address);
            ICertificateDispatcher {
                contract_address: guild_certificate
            }.mint(account, contract_address);
            let mut access_control_state = AccessControl::unsafe_new_contract_state();
            AccessControl::grant_role(ref access_control_state, role, account);

            __event__WhitelistMember(ref self, account, role)
        }
        fn leave(ref self: ContractState) {
            let guild_certificate = self._guild_certificate.read();
            let contract_address = get_contract_address();
            let caller_address = get_caller_address();

            let certificate_id = ICertificateDispatcher {
                contract_address: guild_certificate
            }.get_certificate_id(caller_address, contract_address);

            let check = ICertificateDispatcher {
                contract_address: guild_certificate
            }.check_tokens_exist(certificate_id);

            assert(check == false, 'Account has items in guild');

            ICertificateDispatcher {
                contract_address: guild_certificate
            }.guild_burn(caller_address, contract_address);

            let mut access_control_state = AccessControl::unsafe_new_contract_state();
            let roles = AccessControl::get_roles(@access_control_state, caller_address);
            AccessControl::revoke_role(ref access_control_state, roles, caller_address)
        }
        fn remove_member(ref self: ContractState, account: ContractAddress) {
            let caller_address = get_caller_address();
            let contract_address = get_contract_address();
            let guild_certificate = self._guild_certificate.read();
            let mut access_control_state = AccessControl::unsafe_new_contract_state();
            AccessControl::has_role(@access_control_state, Roles::ADMIN, caller_address);
            let certificate_dispatcher = ICertificateDispatcher {
                contract_address: guild_certificate
            };
            let certificate_id = certificate_dispatcher
                .get_certificate_id(account, contract_address);
            let check = certificate_dispatcher.check_tokens_exist(certificate_id);

            assert(check == false, 'Member holds items in guild.');
            certificate_dispatcher.guild_burn(account, contract_address);

            let mut access_control_state = AccessControl::unsafe_new_contract_state();
            let roles = AccessControl::get_roles(@access_control_state, account);
            AccessControl::revoke_role(ref access_control_state, roles, account);
            self._is_blacklisted.write(account, true);

            __event__RemoveMember(ref self, account)
        }
        fn force_transfer_item(ref self: ContractState, token: Token, account: ContractAddress) {
            let contract_address = get_contract_address();
            let guild_certificate = self._guild_certificate.read();
            let caller = get_caller_address();
            let mut access_control_state = AccessControl::unsafe_new_contract_state();
            AccessControl::has_role(@access_control_state, Roles::ADMIN, caller);

            let certificate_dispatcher = ICertificateDispatcher {
                contract_address: guild_certificate
            };
            let certificate_id = certificate_dispatcher
                .get_certificate_id(account, contract_address);

            assert(token.amount > u256 { low: 0_u128, high: 0_u128 }, 'Amount must be > 0.');

            if (token.token_standard == TokenStandard::ERC721) {
                let token_dispatcher = IERC721Dispatcher {
                    contract_address: token.token
                };
                token_dispatcher.transfer_from(contract_address, account, token.token_id, );
                ICertificateDispatcher {
                    contract_address: guild_certificate
                }
                    .change_token_data(
                        certificate_id,
                        token.token_standard,
                        token.token,
                        token.token_id,
                        u256 { low: 0_u128, high: 0_u128 },
                    );
            }
        // if (token.token_standard == TokenStandard::ERC1155) {
        //     let mut data = ArrayTrait::new();
        //     let erc1155_dispatcher = IERC1155Dispatcher { contract_address: token.token };
        //     erc1155_dispatcher.safe_transfer_from(
        //         contract_address,
        //         account,
        //         token.token_id,
        //         token.amount,
        //         data,
        //     );
        //     ICertificateDispatcher { contract_address: guild_certificate }.change_token_data(
        //         certificate_id,
        //         token.token_standard,
        //         token.token,
        //         token.token_id,
        //         u256 { low: 0_u128, high: 0_u128},
        //     );
        // }
        }
        fn update_roles(ref self: ContractState, account: ContractAddress, roles: felt252) {
            let caller_address = get_caller_address();
            let contract_address = get_contract_address();
            let guild_certificate = self._guild_certificate.read();
            let mut access_control_state = AccessControl::unsafe_new_contract_state();
            AccessControl::has_role(@access_control_state, Roles::ADMIN, caller_address);

            let certificate_id = ICertificateDispatcher {
                contract_address: guild_certificate
            }.get_certificate_id(account, contract_address);

            AccessControl::revoke_role(ref access_control_state, roles, account);

            AccessControl::grant_role(ref access_control_state, roles, account);
            __event__UpdateMemberRole(ref self, account, roles)
        }
        fn deposit(
            ref self: ContractState,
            token_standard: u8,
            token: ContractAddress,
            token_id: u256,
            amount: u256
        ) {
            let caller_address = get_caller_address();
            let mut access_control_state = AccessControl::unsafe_new_contract_state();
            AccessControl::has_role(@access_control_state, Roles::OWNER, caller_address);

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
                    .add_token_data(certificate_id, token_standard, token, token_id, amount, );
            }

            let initial_amount = certificate_dispatcher
                .get_token_amount(certificate_id, token_standard, token, token_id, );

            let new_amount = initial_amount + amount;

            // if token_standard == TokenStandard::ERC1155 {
            //     let data = ArrayTrait::new();
            //     IERC1155Dispatcher { contract_address: token }.safe_transfer_from(
            //         caller_address,
            //         contract_address,
            //         token_id,
            //         amount,
            //         data
            //     );
            //     if check_exists {
            //         certificate_dispatcher.change_token_data(
            //             certificate_id,
            //             token_standard,
            //             token,
            //             token_id,
            //             new_amount,
            //         );
            //     } else {
            //         certificate_dispatcher.add_token_data(
            //             certificate_id,
            //             token_standard,
            //             token,
            //             token_id,
            //             amount,
            //         );
            //     }
            // }

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
            let mut access_control_state = AccessControl::unsafe_new_contract_state();
            AccessControl::has_role(@access_control_state, Roles::OWNER, caller_address);

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
                .check_token_exists(certificate_id, token_standard, token, token_id, );

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

            let initial_amount = certificate_dispatcher
                .get_token_amount(certificate_id, token_standard, token, token_id, );

            let new_amount = initial_amount - amount;

            // if token_standard == TokenStandard::ERC1155 {
            //     let data = ArrayTrait::new();
            //     let erc1155_dispatcher = IERC1155Dispatcher { contract_address: token };
            //     erc1155_dispatcher.safe_transfer_from(
            //         contract_address,
            //         caller_address,
            //         token_id,
            //         amount,
            //         data,
            //     );
            //     certificate_dispatcher.change_token_data(
            //         certificate_id,
            //         token_standard,
            //         token,
            //         token_id,
            //         new_amount,
            //     );
            // }

            __event__Withdraw(
                ref self, caller_address, certificate_id, token_standard, token, token_id, amount, 
            )
        }
        fn execute(ref self: ContractState, mut calls: Array<Call>, nonce: felt252) {
            // check_gas();
            let caller = get_caller_address();
            let mut access_control_state = AccessControl::unsafe_new_contract_state();
            AccessControl::has_role(@access_control_state, Roles::MEMBER, caller);

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
            let mut access_control_state = AccessControl::unsafe_new_contract_state();
            AccessControl::assert_admin(@access_control_state);
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
        fn set_fee_policy(
            ref self: ContractState,
            fee_policy: ContractAddress,
            caller_split: usize,
            owner_split: usize,
            admin_split: usize,
            payment_type: felt252,
            payment_details: Array<Token>
        ) {
            let fee_policy_manager = self._fee_policy_manager.read();
            let fee_policy_manager_dispatcher = IFeePolicyManagerDispatcher {
                contract_address: fee_policy_manager
            };

            fee_policy_manager_dispatcher
                .set_fee_policy(fee_policy, caller_split, owner_split, admin_split, payment_details)
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
            let mut access_control_state = AccessControl::unsafe_new_contract_state();
            AccessControl::has_role(@access_control_state, role, account)
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
        let fee_policy_manager = self._fee_policy_manager.read();

        let Call{to, selector, calldata } = call;

        // Check the tranasction is permitted
        _check_permitted_call(@self, to, selector);

        let fee_policy_manager_dispatcher = IFeePolicyManagerDispatcher {
            contract_address: fee_policy_manager
        };

        let fee_policy = fee_policy_manager_dispatcher
            .get_fee_policy(contract_address, to, selector);

        assert(!fee_policy.is_zero(), 'No fee policy set');

        let fee_policy_dispatcher = IFeePolicyDispatcher { contract_address: fee_policy };
        let (used_token_details, acquired_token_details) = fee_policy_dispatcher
            .get_tokens(to, selector, calldata.clone());

        let certificate_dispatcher = ICertificateDispatcher { contract_address: guild_certificate };
        let owner = certificate_dispatcher
            .get_token_owner(
                *used_token_details.at(0_usize).token_standard,
                *used_token_details.at(0_usize).token,
                *used_token_details.at(0_usize).ids.at(0_usize)
            );

        let owner_balances = ArrayTrait::new();

        let certificate_id = certificate_dispatcher.get_certificate_id(caller, contract_address);

        // get the guild balance in order to assess whether the call can be made
        // (currently this is based on the owner balance of accrued tokens)

        _loop_get_guild_balances(
            ref self,
            0,
            guild_certificate,
            certificate_id,
            acquired_token_details.clone(),
            owner_balances.clone()
        );

        // calls the fee policy to perform the check, returns bool if this was passed

        let has_balance = fee_policy_dispatcher
            .check_owner_balances(calldata.span(), owner_balances.clone());

        assert(has_balance, 'Owner under required balances');

        let pre_balances = fee_policy_dispatcher.get_balances();

        // Actually execute it
        let res = starknet::call_contract_syscall(to, selector, calldata.span()).unwrap();

        __event__ExecuteCall(ref self, caller, to, selector);

        let post_balances = fee_policy_dispatcher.get_balances();

        assert(pre_balances.len() == post_balances.len(), 'Balance lengths don\'t match');

        let difference_balances = ArrayTrait::new();

        let mut fee_policy_state = FeePolicy::unsafe_new_contract_state();
        FeePolicy::calculate_differences(
            ref fee_policy_state,
            0_usize,
            pre_balances.len(),
            pre_balances,
            post_balances,
            difference_balances.clone()
        );

        _loop_update_balances(
            ref self,
            0_usize,
            guild_certificate,
            certificate_id,
            acquired_token_details.clone(),
            difference_balances.clone()
        );

        // currently same as guild master
        let mut access_control_state = AccessControl::unsafe_new_contract_state();
        let admin = AccessControl::get_admin(@access_control_state);

        _execute_payments(
            ref self,
            acquired_token_details.clone(),
            difference_balances.clone(),
            fee_policy,
            owner,
            caller,
            admin
        );

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

        return _set_permissions(ref self, permissions_index + 1_u32, permissions, );
    }

    fn _check_permitted_call(self: @ContractState, to: ContractAddress, selector: felt252) {
        let is_permitted = self._is_permission.read((to, selector));
        assert(is_permitted, 'Call is not permitted');
    }

    fn _loop_get_guild_balances(
        ref self: ContractState,
        index: usize,
        guild_certificate: ContractAddress,
        certificate_id: u256,
        accrued_token_details: Array<TokenDetails>,
        owner_balances: Array<u256>
    ) {
        // check_gas();
        if index == accrued_token_details.len() {
            return ();
        }
        let TokenDetails{token_standard, token, ids } = accrued_token_details.at(index);

        _loop_get_token_ids_balance(
            ref self,
            0,
            guild_certificate,
            certificate_id,
            *token_standard,
            *token,
            ids.clone(),
            owner_balances.clone()
        );

        return _loop_get_guild_balances(
            ref self,
            index + 1_usize,
            guild_certificate,
            certificate_id,
            accrued_token_details,
            owner_balances
        );
    }

    fn _loop_get_token_ids_balance(
        ref self: ContractState,
        index: usize,
        guild_certificate: ContractAddress,
        certificate_id: u256,
        token_standard: u8,
        token: ContractAddress,
        ids: Array<u256>,
        mut owner_balances: Array<u256>
    ) {
        if index == ids.len() {
            return ();
        }
        let certificate_dispatcher = ICertificateDispatcher { contract_address: guild_certificate };
        let amount = certificate_dispatcher
            .get_token_amount(certificate_id, token_standard, token, *ids.at(index), );

        owner_balances.append(amount);

        return _loop_get_token_ids_balance(
            ref self,
            index + 1_u32,
            guild_certificate,
            certificate_id,
            token_standard,
            token,
            ids,
            owner_balances
        );
    }

    fn _loop_update_balances(
        ref self: ContractState,
        index: usize,
        guild_certificate: ContractAddress,
        certificate_id: u256,
        token_details: Array<TokenDetails>,
        differences: Array<TokenDifferences>
    ) {
        if index == token_details.len() {
            return ();
        }

        let token_standard = *token_details.at(index).token_standard;
        let token = *token_details.at(index).token;
        let difference = differences.at(index);
        let token_detail = token_details.at(index);

        _loop_update_token_ids_balance(
            ref self,
            0,
            guild_certificate,
            certificate_id,
            token_standard,
            token,
            token_detail.ids.clone(),
            difference.differences.clone()
        );

        return _loop_update_balances(
            ref self, index + 1_usize, guild_certificate, certificate_id, token_details, differences
        );
    }

    fn _loop_update_token_ids_balance(
        ref self: ContractState,
        index: u32,
        guild_certificate: ContractAddress,
        certificate_id: u256,
        token_standard: u8,
        token: ContractAddress,
        ids: Array<u256>,
        differences: Array<felt252>
    ) {
        if index == ids.len() {
            return ();
        }
        let certificate_dispatcher = ICertificateDispatcher { contract_address: guild_certificate };

        let current_balance = certificate_dispatcher
            .get_token_amount(certificate_id, token_standard, token, *ids.at(index), );

        // if there is a change in guild balance remove or add from the owner
        // change in balance is calculated from Fee Policy
        let difference = *differences.at(index);
        if !difference.is_zero() {
            let new_amount = current_balance + difference.into();

            certificate_dispatcher
                .change_token_data(
                    certificate_id, token_standard, token, *ids.at(index), new_amount, 
                );
        } else {
            // we already know the account has enough balance in guild
            let new_amount = current_balance + difference.into();

            certificate_dispatcher
                .change_token_data(
                    certificate_id,
                    token_standard,
                    token,
                    *ids.at(index),
                    u256 { low: 0_u128, high: 0_u128 },
                );
        }

        return _loop_update_token_ids_balance(
            ref self,
            index + 1_u32,
            guild_certificate,
            certificate_id,
            token_standard,
            token,
            ids,
            differences
        );
    }

    fn _execute_payments(
        ref self: ContractState,
        accrued_token_details: Array<TokenDetails>,
        difference_balances: Array<TokenDifferences>,
        fee_policy: ContractAddress,
        owner: ContractAddress,
        caller: ContractAddress,
        admin: ContractAddress
    ) {
        // let data = ArrayTrait::new();

        let contract_address = get_contract_address();

        let fee_policy_manager = self._fee_policy_manager.read();
        let fee_policy_manager_dispatcher = IFeePolicyManagerDispatcher {
            contract_address: fee_policy_manager
        };

        let (caller_split, owner_split, admin_split) = fee_policy_manager_dispatcher
            .get_policy_distribution(contract_address, fee_policy);

        let direct_payments = fee_policy_manager_dispatcher
            .get_direct_payments(contract_address, fee_policy);

        let mut caller_balances = ArrayTrait::new();
        let mut owner_balances = ArrayTrait::new();
        let mut admin_balances = ArrayTrait::new();

        let mut fee_policy_state = FeePolicy::unsafe_new_contract_state();
        FeePolicy::calculate_distribution_balances(
            ref fee_policy_state,
            0_usize,
            difference_balances.clone(),
            caller_split,
            owner_split,
            admin_split,
            caller_balances.clone(),
            owner_balances.clone(),
            admin_balances.clone()
        );

        _loop_distribute_reward(
            ref self,
            0,
            accrued_token_details,
            owner,
            owner_balances.clone(),
            caller,
            caller_balances.clone(),
            admin,
            admin_balances.clone()
        );

        loop_direct_payment(ref self, 0, direct_payments, owner, caller, admin)
    }

    fn _loop_distribute_reward(
        ref self: ContractState,
        index: u32,
        accrued_token_details: Array<TokenDetails>,
        owner: ContractAddress,
        owner_balances: Array<TokenBalances>,
        caller: ContractAddress,
        caller_balances: Array<TokenBalances>,
        admin: ContractAddress,
        admin_balances: Array<TokenBalances>
    ) {
        if index == accrued_token_details.len() {
            return ();
        }

        let contract_address = get_contract_address();

        let TokenDetails{token_standard, token, ids } = accrued_token_details.at(index);

        // if token_standard == TokenStandard::ERC1155 {
        //     let erc1155_dispatcher = IERC1155Dispatcher { contract_address: token };

        //     let data = ArrayTrait::new();
        //     let caller_balance = *caller_balances.at(index);
        //     erc1155_dispatcher.safe_batch_transfer_from(
        //         contract_address,
        //         caller,
        //         ids,
        //         caller_balance.balances,
        //         data,
        //     );

        //     let owner_balance = *owner_balances.at(index);
        //     erc1155_dispatcher.safe_batch_transfer_from(
        //         contract_address,
        //         owner,
        //         ids,
        //         owner_balance.balances,
        //         data,
        //     );

        //     let admin_balance = *admin_balances.at(index);
        //     erc1155_dispatcher.safe_batch_transfer_from(
        //         contract_address,
        //         admin,
        //         ids,
        //         admin_balance.balances,
        //         data,
        //     );

        // }

        return _loop_distribute_reward(
            ref self,
            index + 1_u32,
            accrued_token_details,
            owner,
            owner_balances,
            caller,
            caller_balances,
            admin,
            admin_balances
        );
    }

    fn loop_direct_payment(
        ref self: ContractState,
        index: u32,
        direct_payments: Array<Token>,
        owner: ContractAddress,
        caller: ContractAddress,
        admin: ContractAddress
    ) {
        if index == direct_payments.len() {
            return ();
        }

        let Token{token_standard, token, token_id, amount } = *direct_payments.at(index);

        if token_standard == TokenStandard::ERC20 {
            let erc20_dispatcher = IERC20Dispatcher { contract_address: token };
            if index == Recipient::OWNER.into() {
                erc20_dispatcher.transfer(owner, amount);
            }

            if index == Recipient::CALLER.into() {
                erc20_dispatcher.transfer(caller, amount);
            }

            if index == Recipient::ADMIN.into() {
                erc20_dispatcher.transfer(admin, amount);
            }
        }

        return loop_direct_payment(ref self, index + 1_u32, direct_payments, owner, caller, admin);
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

    fn __event__WhitelistMember(
        ref self: ContractState, account: ContractAddress, role: felt252, 
    ) {
        self.emit(Event::WhitelistMember(WhitelistMember { account, role }));
    }

    fn __event__RemoveMember(ref self: ContractState, account: ContractAddress, ) {
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
