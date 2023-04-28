use serde::Serde;
use array::ArrayTrait;
use array::SpanTrait;
use hash::LegacyHash;
use starknet::ContractAddress;
use starknet::StorageAccess;
use starknet::StorageBaseAddress;
use starknet::SyscallResult;
use starknet::storage_access;
use starknet::storage_read_syscall;
use starknet::storage_write_syscall;
use starknet::storage_base_address_from_felt252;
use starknet::storage_address_from_base_and_offset;
use traits::Into;
use traits::TryInto;
use option::OptionTrait;
use openzeppelin::utils::check_gas;
use core::integer::Felt252IntoU256;
use guildly::implementations::token::Token;
use guildly::implementations::permission::Permission;

impl LegacyHashPermission of LegacyHash::<Permission> {
    fn hash(state: felt252, value: Permission) -> felt252 {
        LegacyHash::<felt252>::hash(state, value.into())
    }
}

impl ArrayFeltCopy of Copy::<Array<felt252>>;
impl ArrayU256Copy of Copy::<Array<u256>>;

#[contract]
mod Guild {
    use box::BoxTrait;
    use serde::Serde;
    use array::ArrayTrait;
    use array::SpanTrait;
    use zeroable::Zeroable;
    use ecdsa::check_ecdsa_signature;
    use starknet::get_tx_info;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::ContractAddress;
    use starknet::ClassHash;
    use starknet::contract_address::ContractAddressPartialEq;
    use starknet::contract_address::ContractAddressZeroable;
    use starknet::contract_address::Felt252TryIntoContractAddress;
    use traits::Into;
    use traits::TryInto;
    use option::OptionTrait;

    // use openzeppelin::token::erc721::IERC721Dispatcher;
    // use openzeppelin::token::erc721::IERC721DispatcherTrait;
    use openzeppelin::introspection::erc165::ERC165;
    use openzeppelin::utils::check_gas;

    use guildly::upgradeable::Upgradeable;

    use guildly::fee_policies::fee_policy::IFeePolicyDispatcher;
    use guildly::fee_policies::fee_policy::IFeePolicyDispatcherTrait;
    use guildly::fee_policies::fee_policy_manager::IFeePolicyManagerDispatcher;
    use guildly::fee_policies::fee_policy_manager::IFeePolicyManagerDispatcherTrait;
    use guildly::access_control::accesscontrol_library::AccessControl;
    use guildly::constants::Roles;
    use guildly::constants::TokenStandard;
    use guildly::math_utils::MathUtils;
    use guildly::certificate::ICertificateDispatcher;
    use guildly::certificate::ICertificateDispatcherTrait;
    use guildly::fee_policies::library_fee_policy::FeePolicies;
    use guildly::fee_policies::constants_fee_policy::Recipient;
    use guildly::helpers::Helpers::find_value;

    use guildly::implementations::call::Call;
    use super::LegacyHashPermission;
    use super::ArrayFeltCopy;
    use super::ArrayU256Copy;
    use guildly::implementations::permission::Permission;
    use guildly::implementations::permission::ArrayPermissionSerde;
    use guildly::implementations::permission::ArrayPermissionCopy;
    use guildly::implementations::permission::ArrayPermissionDrop;
    use guildly::implementations::token::Token;
    use guildly::implementations::policy::TokenDetails;
    use guildly::implementations::policy::ArrayTokenDetailsSerde;
    use guildly::implementations::policy::TokenBalances;
    use guildly::implementations::policy::ArrayTokenBalancesCopy;
    use guildly::implementations::policy::TokenDifferences;
    use guildly::implementations::general::ArraySpanSerde;

    struct Storage {
        _name: felt252,
        _is_permissions_initialized: bool,
        _is_blacklisted: LegacyMap<ContractAddress, bool>,
        _is_permission: LegacyMap<Permission, bool>,
        _guild_certificate: ContractAddress,
        _fee_policy_manager: ContractAddress,
        _current_nonce: felt252,
    }

    #[abi]
    trait IERC20 {
        fn name() -> felt252;
        fn symbol() -> felt252;
        fn decimals() -> u8;
        fn total_supply() -> u256;
        fn balance_of(account: ContractAddress) -> u256;
        fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256;
        fn transfer(recipient: ContractAddress, amount: u256) -> bool;
        fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
        fn approve(spender: ContractAddress, amount: u256) -> bool;
    }

    #[abi]
    trait IERC721 {
        // IERC721Metadata
        fn name() -> felt252;
        fn symbol() -> felt252;
        fn token_uri(token_id: u256) -> felt252;
        // IERC721
        fn balance_of(owner: ContractAddress) -> u256;
        fn owner_of(token_id: u256) -> ContractAddress;
        fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256);
        fn safe_transfer_from(
            from: ContractAddress, to: ContractAddress, token_id: u256, data: Array<felt252>
        );
        fn approve(approved: ContractAddress, token_id: u256);
        fn set_approval_for_all(operator: ContractAddress, approved: bool);
        fn get_approved(token_id: u256) -> ContractAddress;
        fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool;
    }


    #[abi]
    trait IERC1155 {
        // IERC1155
        fn balance_of(account: ContractAddress, id: u256) -> u256;
        fn balance_of_batch(accounts: Array<ContractAddress>, ids: Array<u256>) -> Array<u256>;
        fn is_approved_for_all(account: ContractAddress, operator: ContractAddress) -> bool;
        fn set_approval_for_all(operator: ContractAddress, approved: bool);
        fn safe_transfer_from(
            from: ContractAddress, to: ContractAddress, id: u256, amount: u256, data: Array<felt252>
        );
        fn safe_batch_transfer_from(
            from: ContractAddress,
            to: ContractAddress,
            ids: Array<u256>,
            amounts: Array<u256>,
            data: Array<felt252>
        );
        // IERC1155MetadataURI
        fn uri(id: u256) -> felt252;
    }

    //
    // Events
    //

    #[event]
    fn WhitelistMember(account: ContractAddress, role: felt252) {}

    #[event]
    fn RemoveMember(account: ContractAddress) {}

    #[event]
    fn UpdateMemberRole(account: ContractAddress, new_role: Array<felt252>) {}

    #[event]
    fn SetPermissions(account: ContractAddress, permissions: Array<Permission>) {}
    
    // TODO: add calldata after fixing Array<Span<felt252>>
    #[event]
    fn ExecuteTransaction(account: ContractAddress, hash: ContractAddress) {}

    #[event]
    fn Deposit(
        account: ContractAddress,
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        token_id: u256,
        amount: u256,
    ) {}

    #[event]
    fn Withdraw(
        account: ContractAddress,
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        token_id: u256,
        amount: u256,
    ) {}

    //
    // Guards
    //

    #[internal]
    fn require_not_blacklisted(account: ContractAddress) {
        let is_blacklisted = _is_blacklisted::read(account);
        assert(is_blacklisted == false, 'Guild: Account is blacklisted')
    }

    //
    // Initialize & upgrade
    //

    #[external]
    fn initializer(name: felt252, master: ContractAddress, guild_certificate: ContractAddress, fee_policy_manager: ContractAddress, proxy_admin: ContractAddress) {
        _name::write(name);
        _guild_certificate::write(guild_certificate);
        _fee_policy_manager::write(fee_policy_manager);

        let contract_address = get_contract_address();
        ICertificateDispatcher { contract_address: guild_certificate }.mint(master, contract_address);

        Upgradeable::initializer(proxy_admin);
        AccessControl::_set_admin(master);

        ERC165::register_interface(IACCOUNT_ID)
    }

    #[external]
    fn upgrade(implementation: ClassHash) {
        Upgradeable::assert_only_admin();
        Upgradeable::_upgrade(implementation)
    }

    //
    // Getters
    //

    #[view]
    fn supportsInterface(interfaceId: felt252) -> bool {
        ERC165::supports_interface(interfaceId)
    }

    #[view]
    fn name() -> felt252 {
        _name::read()
    }

    #[view]
    fn guild_certificate() -> ContractAddress {
        _guild_certificate::read()
    }

    #[view]
    fn is_permissions_initialized() -> bool {
        _is_permissions_initialized::read()
    }

    #[view]
    fn get_nonce() -> felt252 {
        _current_nonce::read()
    }

    #[view]
    fn has_role(role: felt252, account: ContractAddress) -> bool {
        AccessControl::has_role(role, account)
    }

    //
    // Externals
    //

    #[external]
    fn add_member(account: ContractAddress, role: felt252) {
        let guild_certificate = _guild_certificate::read();
        let contract_address = get_contract_address();
        let caller_address = get_caller_address();

        require_not_blacklisted(caller_address);
        ICertificateDispatcher { contract_address: guild_certificate }.mint(account, contract_address);
        AccessControl::grant_role(role, account);

        WhitelistMember(account, role)
    }

    #[external]
    fn leave() {
        let guild_certificate = _guild_certificate::read();
        let contract_address = get_contract_address();
        let caller_address = get_caller_address();

        let certificate_id = ICertificateDispatcher{ contract_address: guild_certificate }.get_certificate_id(
            caller_address, contract_address
        );

        let check = ICertificateDispatcher{ contract_address: guild_certificate }.check_tokens_exist(
            certificate_id
        );

        assert(check == false, 'Account has items in guild');

        ICertificateDispatcher { contract_address: guild_certificate }.guild_burn(caller_address, contract_address);

        let roles = AccessControl::get_roles(caller_address);
        AccessControl::revoke_role(roles, caller_address)
    }

    #[external]
    fn remove_member(account: ContractAddress) {
        let caller_address = get_caller_address();
        let contract_address = get_contract_address();
        let guild_certificate = _guild_certificate::read();

        AccessControl::has_role(GuildRoles.ADMIN, caller_address);
        let certificate_dispatcher = ICertificateDispatcher {contract_address: guild_certificate};
        let certificate_id = certificate_dispatcher.get_certificate_id(
            account, contract_address
        );
        let check = certificate_dispatcher.check_tokens_exist(
            certificate_id
        );

        assert(check == false, 'Member holds items in guild.');
        certificate_dispatcher.guild_burn(account, contract_address);
        let roles = AccessControl::get_roles(account);
        AccessControl::revoke_role(roles, account);
        _is_blacklisted::write(account, true);

        RemoveMember(account)
    }

    #[external]
    fn force_transfer_item(token: Token, account: ContractAddress) {
        let contract_address = get_contract_address();
        let guild_certificate = _guild_certificate::read();

        AccessControl::has_role(GuildRoles.ADMIN, caller_address);

        let certificate_dispatcher = ICertificateDispatcher {contract_address: guild_certificate};
        let certificate_id = certificate_dispatcher.get_certificate_id(
            account, contract_address
        );


        assert(token.amount > u256 { low: 0_u128, high: 0_u128 }, 'Amount must be > 0.');

        if (token.token_standard == TokenStandard::ERC721) {
            IERC721Dispatcher { contract_address: token.token }.transfer_from(
                contract_address,
                account,
                token.token_id,
            );
            ICertificateDispatcher { contract_address: guild_certificate }.change_token_data(
                certificate_id,
                token.token_standard,
                token.token,
                token.token_id,
                u256 { low: 0_u128, high: 0_u128 },
            );
        } 

        if (token.token_standard == TokenStandard::ERC1155) {
            let mut data = ArrayTrait::new();
            let erc1155_dispatcher = IERC1155Dispatcher { contract_address: token.token };
            erc1155_dispatcher.safe_transfer_from(
                contract_address,
                account,
                token.token_id,
                token.amount,
                data,
            );
            ICertificateDispatcher { contract_address: guild_certificate }.change_token_data(
                certificate_id,
                token.token_standard,
                token.token,
                token.token_id,
                u256 { low: 0_u128, high: 0_u128},
            );
        }
    }

    #[external]
    fn update_roles(account: ContractAddress, new_roles: Array<felt252>) {
        let caller_address = get_caller_address();
        let contract_address = get_contract_address();
        let guild_certificate = _guild_certificate::read();

        AccessControl::has_role(GuildRoles.ADMIN, caller_address);

        let certificate_id = ICertificateDispatcher{ contract_address: guild_certificate }.get_certificate_id(
            account, contract_address
        );

        let roles = AccessControl::get_roles(account);
        AccessControl::revoke_role(roles, account);
        AccessControl::grant_role(new_roles, account);

        UpdateMemberRole(account, new_roles)
    }

    #[external]
    fn deposit(token_standard: felt252, token: ContractAddress, token_id: u256, amount: u256) {
        let caller_address = get_caller_address();
        AccessControl::has_role(Roles::OWNER, caller_address);

        assert(amount > u256 { low: 0_u128, high: 0_u128}, 'Guild: Amount cannot be 0');

        if token_standard == TokenStandard::ERC721 {
            assert(amount == u256 { low: 1_u128, high: 0_u128}, 'Guild: ERC721 amount must be 1');
        }

        let guild_certificate = _guild_certificate::read();
        let contract_address = get_contract_address();

        let certificate_dispatcher = ICertificateDispatcher{ contract_address: guild_certificate };

        let certificate_id = certificate_dispatcher.get_certificate_id(
            caller_address, contract_address
        );

        let check_exists = certificate_dispatcher.check_token_exists(
            certificate_id, token_standard, token, token_id
        );

        if token_standard == TokenStandard::ERC721 {
            assert(check_exists, 'Caller already holds ERC721');
            let erc721_dispatcher = IERC721Dispatcher { contract_address: token};
            erc721_dispatcher.transfer_from(
                caller_address, contract_address, token_id
            );
            certificate_dispatcher.add_token_data(
                certificate_id,
                token_standard,
                token,
                token_id,
                amount,
            );
        }

        let initial_amount = certificate_dispatcher.get_token_amount(
            certificate_id,
            token_standard,
            token,
            token_id,
        );

        let new_amount = initial_amount + amount;

        if token_standard == TokenStandard::ERC1155 {
            let data = ArrayTrait::new();
            IERC1155Dispatcher { contract_address: token }.safe_transfer_from(
                caller_address,
                contract_address,
                token_id,
                amount,
                data
            );
            if check_exists {
                certificate_dispatcher.change_token_data(
                    certificate_id,
                    token_standard,
                    token,
                    token_id,
                    new_amount,
                );
            } else {
                certificate_dispatcher.add_token_data(
                    certificate_id,
                    token_standard,
                    token,
                    token_id,
                    amount,
                );
            }
        }

        Deposit(
            caller_address,
            certificate_id,
            token_standard,
            token,
            token_id,
            amount,
        )
    }

    #[external]
    fn withdraw(token_standard: felt252, token: ContractAddress, token_id: u256, amount: u256) {
        let caller_address = get_caller_address();
        AccessControl::has_role(GuildRoles.OWNER, caller_address);

        if token_standard == TokenStandard::ERC721 {
            assert(amount == u256 { low: 1_u128, high: 0_u128 }, 'ERC721 amount must be 1');
        }

        let guild_certificate = _guild_certificate::read();
        let contract_address = get_contract_address();

        let certificate_dispatcher = ICertificateDispatcher { contract_address: guild_certificate };
        let certificate_id = certificate_dispatcher.get_certificate_id(
            caller_address, contract_address
        );

        let check_exists = certificate_dispatcher.check_token_exists(
            certificate_id,
            token_standard,
            token,
            token_id,
        );

        assert(check_exists, 'Caller has no tokens');

        if token_standard == TokenStandard::ERC721 {
            let erc721_dispatcher = IERC721Dispatcher { contract_address: token };
            erc721_dispatcher.transfer_from(
                contract_address, caller_address, token_id
            );
            certificate_dispatcher.change_token_data(
                certificate_id,
                token_standard,
                token,
                token_id,
                u256 { low: 0_u128, high: 0_u128},
            );
        }

        let initial_amount = certificate_dispatcher.get_token_amount(
            certificate_id,
            token_standard,
            token,
            token_id,
        );

        let new_amount = initial_amount - amount;

        if token_standard == TokenStandard::ERC1155 {
            let data = ArrayTrait::new();
            let erc1155_dispatcher = IERC1155Dispatcher { contract_address: token };
            erc1155_dispatcher.safe_transfer_from(
                contract_address,
                caller_address,
                token_id,
                amount,
                data,
            );
            certificate_dispatcher.change_token_data(
                certificate_id,
                token_standard,
                token,
                token_id,
                new_amount,
            );
        }

        Withdraw(
            caller_address,
            certificate_id,
            token_standard,
            token,
            token_id,
            amount,
        )
    }

    #[internal]
    fn _execute_calls(mut calls: Array<Call>, nonce: felt252) -> Array<Span<felt252>> {
        check_gas();
        let caller = get_caller_address();

        AccessControl::has_role(Roles::MEMBER, caller);

        let current_nonce = _current_nonce::read();
        assert(current_nonce == nonce, 'Guild: Invalid nonce');
        _current_nonce::write(current_nonce + 1);

        let tx_info = get_tx_info().unbox();

        let response = execute_list(calls, ArrayTrait::new());
        // emit event
        ExecuteTransaction(
            caller, tx_info.transaction_hash.try_into().unwrap()
        );
        return response;
    }

    #[external]
    fn execute_list(mut calls: Array<Call>, mut res: Array<Span<felt252>>) -> Array<Span<felt252>> {
        check_gas();
        match calls.pop_front() {
            Option::Some(call) => {
                let _res = _execute_single_call(call);
                res.append(_res);
                return execute_list(calls, res);
            },
            Option::None(_) => {
                return res;
            },
        }
    }

    #[internal]
    fn _execute_single_call(mut call: Call) -> Span<felt252> {
        let contract_address = get_contract_address();
        let caller = get_caller_address();
        let guild_certificate = _guild_certificate::read();
        let fee_policy_manager = _fee_policy_manager::read();

        let Call {to, selector, calldata } = call;

        // Check the tranasction is permitted
        check_permitted_call(to, selector);

        let fee_policy_manager_dispatcher = IFeePolicyManagerDispatcher { contract_address: fee_policy_manager };

        let fee_policy = fee_policy_manager_dispatcher.get_fee_policy(
            contract_address, to, selector
        );

        assert(fee_policy.is_non_zero(), 'No fee policy set');

        let fee_policy_dispatcher = IFeePolicyDispatcher { contract_address: fee_policy };
        let (used_token_details, acquired_token_details) = fee_policy_dispatcher.get_tokens(
            call
        );

        let certificate_dispatcher = ICertificateDispatcher { contract_address: guild_certificate };
        let owner = certificate_dispatcher.get_token_owner(
            *used_token_details.at(0_usize).token_standard, 
            *used_token_details.at(0_usize).token, 
            *used_token_details.at(0_usize).ids.at(0_usize)
        );

        let owner_balances = ArrayTrait::new();

        let certificate_id = certificate_dispatcher.get_certificate_id(caller, contract_address);

        // get the guild balance in order to assess whether the call can be made
        // (currently this is based on the owner balance of accrued tokens)

        loop_get_guild_balances(
            0,
            guild_certificate,
            certificate_id,
            acquired_token_details,
            owner_balances
        );

        // calls the fee policy to perform the check, returns bool if this was passed

        let has_balance = fee_policy_dispatcher.check_owner_balances(calldata, owner_balances);

        assert(has_balance, 'Owner under required balances');

        let pre_balances = fee_policy_dispatcher.get_balances();

        // Actually execute it
        let res = starknet::call_contract_syscall(to, selector, calldata.span()).unwrap_syscall();

        let post_balances = fee_policy_dispatcher.get_balances();

        assert(pre_balances.len() == post_balances.len(), 'Balance lengths don\'t match');

        let difference_balances = ArrayTrait::<TokenDifferences>::new();

        FeePolicies::calculate_differences(0_usize, pre_balances.len(), pre_balances, post_balances, difference_balances);

        loop_update_balances(
            0_usize,
            guild_certificate,
            certificate_id,
            acquired_token_details,
            difference_balances
        );

        // currently same as guild master
        let admin = AccessControl::get_admin();

        execute_payments(
            acquired_token_details,
            difference_balances,
            fee_policy,
            owner,
            caller,
            admin
        );

        return res;
    }

    #[external]
    fn initialize_permissions(permissions: Array<Permission>) {
        AccessControl::assert_admin();
        let permissions_initialized = _is_permissions_initialized::read();
        assert(!permissions_initialized, 'Permissions already initialized');
        set_permissions(permissions);
        _is_permissions_initialized::write(true)
    }

    #[external]
    fn set_permissions(permissions: Array<Permission>) {
        _set_permissions(0, permissions);
        let caller = get_caller_address();
        SetPermissions(caller, permissions)
    }

    #[external]
    fn set_fee_policy(
        fee_policy: ContractAddress, 
        caller_split: usize, 
        owner_split: usize, 
        admin_split: usize,
        payment_type: felt252,
        payment_details: Array<Token>
    ) {
        let fee_policy_manager = _fee_policy_manager::read();
        let fee_policy_manager_dispatcher = IFeePolicyManagerDispatcher {contract_address: fee_policy_manager};

        fee_policy_manager_dispatcher.set_fee_policy(
            fee_policy, 
            caller_split,
            owner_split, 
            admin_split,
            payment_details
        )
    }

    // Internals

    #[internal]
    fn _set_permissions(permissions_index: usize, permissions: Array<Permission>) {
        if permissions_index == permissions.len() {
            return ();
        }

        _is_permission::write(*permissions.at(permissions_index), true);

        return _set_permissions(
            permissions_index + 1_u32,
            permissions,
        );
    }

    #[internal]
    fn check_permitted_call(to: ContractAddress, selector: felt252) {
        let execute_call = Permission { to, selector };
        let is_permitted = _is_permission::read(execute_call);
        assert(is_permitted, 'Call is not permitted');
    }

    #[internal]
    fn loop_get_guild_balances(
        index: usize,
        guild_certificate: ContractAddress,
        certificate_id: u256,
        accrued_token_details: Array<TokenDetails>,
        owner_balances: Array<u256>
    ) {
        check_gas();
        if index == accrued_token_details.len() {
            return ();
        }
        let TokenDetails { token_standard, token, ids } = accrued_token_details.at(index);

        loop_get_token_ids_balance(
            0,
            guild_certificate,
            certificate_id,
            *token_standard,
            *token,
            *ids,
            owner_balances
        );

        return loop_get_guild_balances(
            index + 1_usize,
            guild_certificate,
            certificate_id,
            accrued_token_details,
            owner_balances
        );
    }

    #[internal]
    fn loop_get_token_ids_balance(
        index: usize,
        guild_certificate: ContractAddress,
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        ids: Array<u256>,
        mut owner_balances: Array<u256>
    ) {
        if index == ids.len() {
            return ();
        }
        let certificate_dispatcher = ICertificateDispatcher { contract_address: guild_certificate };
        let amount = certificate_dispatcher.get_token_amount(
            certificate_id,
            token_standard,
            token,
            *ids.at(index),
        );

        owner_balances.append(amount);

        return loop_get_token_ids_balance(
            index + 1_u32,
            guild_certificate,
            certificate_id,
            token_standard,
            token,
            ids,
            owner_balances
        );
    }

    #[internal]
    fn loop_update_balances(
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
        let difference = *differences.at(index);
        let token_detail = *token_details.at(index);

        loop_update_token_ids_balance(
            0,
            guild_certificate,
            certificate_id,
            token_standard,
            token,
            token_detail.ids,
            difference.differences
        );

        return loop_update_balances(
            index + 1_usize,
            guild_certificate,
            certificate_id,
            token_details,
            differences
        );

    }

    #[internal]
    fn loop_update_token_ids_balance(
        index: u32,
        guild_certificate: ContractAddress,
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        ids: Array<u256>,
        differences: Array<felt252>
    ) {
        if index == ids.len() {
            return ();
        }
        let certificate_dispatcher = ICertificateDispatcher { contract_address: guild_certificate };

        let current_balance = certificate_dispatcher.get_token_amount(
            certificate_id,
            token_standard,
            token,
            *ids.at(index),
        );

        // if there is a change in guild balance remove or add from the owner
        // change in balance is calculated from Fee Policy
        let difference = *differences.at(index);
        if difference.is_non_zero() {

            let new_amount = current_balance + difference.into();

            certificate_dispatcher.change_token_data(
                certificate_id,
                token_standard,
                token,
                *ids.at(index),
                new_amount,
            );
        } else {

            // we already know the account has enough balance in guild
            let new_amount = current_balance + difference.into();

            certificate_dispatcher.change_token_data(
                certificate_id,
                token_standard,
                token,
                *ids.at(index),
                u256 { low: 0_u128, high: 0_u128},
            );
        }

        return loop_update_token_ids_balance(
            index + 1,
            guild_certificate,
            certificate_id,
            token_standard,
            token,
            ids,
            differences
        );
    }

    #[internal]
    fn execute_payments(
        accrued_token_details: Array<TokenDetails>,
        difference_balances: Array<TokenDifferences>,
        fee_policy: ContractAddress,
        owner: ContractAddress,
        caller: ContractAddress,
        admin: ContractAddress
    ) {
        let data = ArrayTrait::<felt252>::new();

        let contract_address = get_contract_address();

        let fee_policy_manager = _fee_policy_manager::read();
        let fee_policy_manager_dispatcher = IFeePolicyManagerDispatcher { contract_address: fee_policy_manager };

        let (caller_split, owner_split, admin_split) = fee_policy_manager_dispatcher.get_policy_distribution(
            contract_address, fee_policy
        );

        let direct_payments = fee_policy_manager_dispatcher.get_direct_payments(
            contract_address, fee_policy
        );

        let mut caller_balances = ArrayTrait::<TokenBalances>::new();
        let mut owner_balances = ArrayTrait::<TokenBalances>::new();
        let mut admin_balances = ArrayTrait::<TokenBalances>::new();

        FeePolicies::calculate_distribution_balances(
            0_usize,
            difference_balances,
            caller_split,
            owner_split,
            admin_split,
            caller_balances,
            owner_balances,
            admin_balances
        );

        loop_distribute_reward(
            0, 
            accrued_token_details,
            owner,
            owner_balances,
            caller,
            caller_balances,
            admin,
            admin_balances
        );


        loop_direct_payment(0, direct_payments, owner, caller, admin)
    }

    #[internal]
    fn loop_distribute_reward(
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

        let TokenDetails {token_standard, token, ids} = *accrued_token_details.at(index);

        if token_standard == TokenStandard::ERC1155 {
            let erc1155_dispatcher = IERC1155Dispatcher { contract_address: token };

            let data = ArrayTrait::new();
            let caller_balance = *caller_balances.at(index);
            erc1155_dispatcher.safe_batch_transfer_from(
                contract_address,
                caller,
                ids,
                caller_balance.balances,
                data,
            );

            let owner_balance = *owner_balances.at(index);
            erc1155_dispatcher.safe_batch_transfer_from(
                contract_address,
                owner,
                ids,
                owner_balance.balances,
                data,
            );

            let admin_balance = *admin_balances.at(index);
            erc1155_dispatcher.safe_batch_transfer_from(
                contract_address,
                admin,
                ids,
                admin_balance.balances,
                data,
            );

        }

        return loop_distribute_reward(
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

    #[internal]
    fn loop_direct_payment(
        index: u32,
        direct_payments: Array<Token>,
        owner: ContractAddress,
        caller: ContractAddress,
        admin: ContractAddress
    ) {
        if index == direct_payments.len() {
            return ();
        }

        let Token { token_standard, token, token_id, amount} = *direct_payments.at(index);

        if token_standard == TokenStandard::ERC20 {
            let erc20_dispatcher = IERC20Dispatcher { contract_address: token };
            if index == Recipient::OWNER {
                erc20_dispatcher.transfer(
                    owner,
                    amount
                );
            }

            if index == Recipient::CALLER {
                erc20_dispatcher.transfer(
                    caller,
                    amount
                );
            }

            if index == Recipient::ADMIN {
                erc20_dispatcher.transfer(
                    admin,
                    amount
                );
            }
        }

        return loop_direct_payment(
            index + 1_u32,
            direct_payments,
            owner,
            caller,
            admin
        );
    }
}