use array::ArrayTrait;
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

//
// Structs
//

struct Call {
    to: ContractAddress,
    selector: ContractAddress,
    calldata: Array<felt252>
}

#[derive(Copy, Serde)]
struct Permission {
    to: ContractAddress,
    selector: ContractAddress,
}

#[derive(Copy, Serde)]
struct Token {
    token_standard: felt252,
    token: ContractAddress,
    token_id: u256,
    amount: u256,
}

impl TokenStorageAccess of StorageAccess::<Token> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<Token> {
        Result::Ok(
            Token {
                token_standard: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 0_u8)
                )?,
                token: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 1_u8)
                )?.try_into().unwrap(),
                token_id: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 2_u8)
                )?.try_into().unwrap(),
                amount: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 3_u8)
                )?.try_into().unwrap(),
            }
        )
    }

    fn write(address_domain: u32, base: StorageBaseAddress, value: Token) -> SyscallResult::<()> {
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 0_u8), value.token_standard
        )?;
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 1_u8), value.token.into()
        )?;
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 2_u8), value.token_id.into()
        )?:
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 3_u8), value.amount.into()
        )?:
    }
}


// impl ArrayPermissionDrop of Drop::<Array<Permission>>;

// impl ArrayPermissionSerde of Serde::<Array<Permission>> {
//     fn serialize(ref output: Array<felt252>, mut input: Array<TokenBalances>) {
//         Serde::<usize>::serialize(ref output, input.len());
//         serialize_array_call_helper(ref output, input);
//     }

//     fn deserialize(ref serialized: Span<felt252>) -> Option<Array<Permission>> {
//         let length = *serialized.pop_front()?;
//         let mut arr = ArrayTrait::new();
//         deserialize_array_call_helper(ref serialized, arr, length)
//     }
// }

#[contract]
mod Guild {
    use box::BoxTrait;
    use array::ArrayTrait;
    use option::OptionTrait;
    use zeroable::Zeroable;
    use ecdsa::check_ecdsa_signature;
    use starknet::get_tx_info;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::ContractAddress;
    use starknet::contract_address::ContractAddressPartialEq;
    use starknet::contract_address::ContractAddressZeroable;

    use openzeppelin::token::erc721::IERC721;
    use openzeppelin::introspection::erc165::ERC165;
    use openzeppelin::utils::check_gas;
    use openzeppelin::upgrades::library::Proxy;

    // use guild_contracts::fee_policies::fee_policy_manager::FeePolicyManager::IFeePolicyManagerDispatcher;
    use guild_contracts::access_control::accesscontrol_library::AccessControl;
    use guild_contracts::constants::Roles;
    use guild_contracts::constants::TokenStandard;
    use guild_contracts::math_utils::MathUtils;
    use guild_contracts::fee_policies::library_fee_policy::PaymentDetails;
    use guild_contracts::fee_policies::library_fee_policy::FeePolicies;
    use guild_contracts::fee_policies::library_fee_policy::TokenDetails;
    use guild_contracts::fee_policies::library_fee_policy::TokenBalances;
    use guild_contracts::fee_policies::library_fee_policy::TokenDifferences;
    use guild_contracts::fee_policies::constants_fee_policy::Recipient;
    use guild_contracts::helpers::Helpers::find_value;

    use super::Call;
    use super::Permission;
    use super::Token;

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

    #[abi]
    trait ICertificate {
        fn balance_of(owner: ContractAddress) -> u256;
        fn owner_of(certificate_id: u256) -> ContractAddress;

        fn get_certificate_id(owner: ContractAddress, guild: ContractAddress) -> u256;
        fn get_token_amount(
            certificate_id: u256, token_standard: felt252, token: ContractAddress, token_id: u256
        ) -> u256;
        fn get_certificate_owner(certificate_id: u256) -> ContractAddress;
        fn get_token_owner(
            token_standard: felt252, token: ContractAddress, token_id: u256
        ) -> ContractAddress;
        fn check_token_exists(
            certificate_id: u256, token_standard: felt252, token: ContractAddress, token_id: u256
        ) -> bool;
        fn check_tokens_exist(certificate_id: u256) -> bool;
        fn mint(to: ContractAddress, guild: ContractAddress);
        fn burn(account: ContractAddress, guild: ContractAddress);
        fn guild_burn(account: ContractAddress, guild: ContractAddress);
        fn add_token_data(
            certificate_id: u256,
            token_standard: felt252,
            token: ContractAddress,
            token_id: u256,
            amount: u256
        );
        fn change_token_data(
            certificate_id: u256,
            token_standard: felt252,
            token: ContractAddress,
            token_id: u256,
            new_amount: u256
        );
    }

    #[abi]
    trait FeePolicyManager {
        fn has_fee_policy(guild: ContractAddress, fee_policy: ContractAddress) -> bool; 
        fn get_fee_policy(guild: ContractAddress, to: ContractAddress, selector: ContractAddress) -> ContractAddress;
        fn get_policy_target(fee_policy: ContractAddress) -> PolicyTarget;
        fn get_policy_distribution(guild: ContractAddress, fee_policy: ContractAddress) -> (felt252, felt252, felt252);
        fn get_direct_payments(guild: ContractAddress, fee_policy: ContractAddress) -> Array<PaymentDetails>;
        fn add_policy(policy: ContractAddress, to: ContractAddress, selector: ContractAddress);
        fn set_fee_policy(
            policy_address: ContractAddress, 
            caller_split: u256, 
            owner_split: u256, 
            admin_split: u256,
            payment_details: Array<PaymentDetails>
        );
        fn revoke_policy(policy_address: ContractAddress);
    }

    #[abi]
    trait IFeePolicy {
        fn guild_burn(account: ContractAddress, guild: ContractAddress);
    }

    //
    // Events
    //

    #[event]
    fn WhitelistMember(account: ContractAddress, role: felt252) {
    }

    #[event]
    fn RemoveMember(account: ContractAddress) {
    }

    #[event]
    fn UpdateMemberRole(account: ContractAddress, new_role: felt252) {
    }

    #[event]
    fn SetPermissions(account: ContractAddress, permissions: Array<Permission>) {
    }

    #[event]
    fn ExecuteTransaction(account: ContractAddress, hash: ContractAddress, response: Array<Span<felt252>>) {
    }

    #[event]
    fn Deposit(
        account: ContractAddress,
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        token_id: u256,
        amount: u256,
    ) {
    }

    #[event]
    fn Withdraw(
        account: ContractAddress,
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        token_id: u256,
        amount: u256,
    ) {
    }

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

        Proxy::initializer(proxy_admin);
        AccessControl::_set_admin(master);

        ERC165::register_interface(IACCOUNT_ID)
    }

    #[external]
    fn upgrade(implementation: ContractAddress) {
        Proxy::assert_only_admin();
        Proxy::_set_implementation_hash(implementation)
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
        }

        RemoveMember(account)
    }

    #[external]
    fn force_transfer_item(token: Token, account: ContractAddress) {
        let contract_address = get_contract_address();
        let guild_certificate = _guild_certificate::read();

        AccessControl::has_role(GuildRoles.ADMIN, caller_address);

        let certificate_dispatcher = ICertificateDispatcher {contract_address: guild_certificate};
        let certificate_id = certificate_dispatcher.get_certificate_id(
            owner=account, guild=contract_address
        );


        assert(token.amount > 0_uint256, 'Amount must be > 0.');

        if (token.token_standard == TokenStandard.ERC721) {
            IERC721 { contract_address=token.token }.transferFrom(
                from_=contract_address,
                to=account,
                tokenId=token.token_id,
            );
            ICertificateDispatcher { contract_address=guild_certificate }.change_token_data(
                certificate_id=certificate_id,
                token_standard=token.token_standard,
                token=token.token,
                token_id=token.token_id,
                new_amount=Uint256(0, 0),
            );
        } 

        if (token.token_standard == TokenStandard.ERC1155) {
            let data = ArrayTrait::new();
            let erc1155_dispatcher = IERC1155Dispatcher { contract_address=token.token }
            erc1155_dispatcher.safeTransferFrom(
                from_=contract_address,
                to=account,
                tokenId=token.token_id,
                amount=token.amount,
                data=data,
            );
            ICertificateDispatcher { contract_address=guild_certificate }.change_token_data(
                certificate_id=certificate_id,
                token_standard=token.token_standard,
                token=token.token,
                token_id=token.token_id,
                new_amount=Uint256(0, 0),
            );
        }
    }

    #[external]
    fn update_roles(account: ContractAddress, new_roles: Array<Span<felt252>>) {
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
        AccessControl::has_role(GuildRoles.OWNER, caller_address);

        assert(amount > 0_u256, "Guild Contract: Amount cannot be 0");

        if (token_standard == TokenStandard.ERC721) {
            assert(amount == 1_u256, "Guild Contract: ERC721 amount must be 1");
        }

        let guild_certificate = _guild_certificate::read();
        let contract_address = get_contract_address();

        let certificate_dispatcher = ICertificateDispatcher{ contract_address: guild_certificate };

        let certificate_id = certificate_dispatcher.get_certificate_id(
            caller_address, contract_address
        );

        let check_exists = certificate_dispatcher.check_token_exist(
            certificate_id, token_standard, token, token_id
        );

        if (token_standard == TokenStandard.ERC721) {
            assert(check_exists, "Guild Contract: Caller certificate already holds ERC721 token");
            let erc721_dispatcher = IERC721 { contract_address: token};
            erc721_dispatcher.transferFrom(
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

        let (new_amount, _) = uint256_add(initial_amount, amount);

        if (token_standard == TokenStandard.ERC1155) {
            let data = ArrayTrait::new();
            let erc1155_dispatcher = IERC1155Dispatcher { contract_address: token }
            erc1155_dispatcher.safeTransferFrom(
                caller_address,
                contract_address,
                token_id,
                amount,
                data
            );
            if (check_exists == TRUE) {
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
            account=caller_address,
            certificate_id=certificate_id,
            token_standard=token_standard,
            token=token,
            token_id=token_id,
            amount=amount,
        )
    }

    #[external]
    fn withdraw(token_standard: felt252, token: ContractAddress, token_id: u256, amount: u256) {
        let caller_address = get_caller_address();
        AccessControl::has_role(GuildRoles.OWNER, caller_address);

        if (token_standard == TokenStandard.ERC721) {
            assert(amount == u256 { low: 1_u128, high: 0_u128 }, "Guild Contract: ERC721 amount must be 1");
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

        if (token_standard == TokenStandard.ERC721) {
            let erc721_dispatcher = IERC721 { contract_address: token };
            erc721_dispatcher.transferFrom(
                contract_address, caller_address, token_id
            );
            certificate_dispatcher.change_token_data(
                certificate_id,
                token_standard,
                token,
                token_id,
                0_u256,
            );
        }

        let initial_amount = certificate_dispatcher.get_token_amount(
            certificate_id,
            token_standard,
            token,
            token_id,
        );

        let new_amount = initial_amount - amount;

        if (token_standard == TokenStandard.ERC1155) {
            let data = ArrayTrait::new();
            let erc1155_dispatcher = IERC1155Dispatcher { contract_address: token };
            erc1155_dispatcher.safeTransferFrom(
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
            account=caller_address,
            certificate_id=certificate_id,
            token_standard=token_standard,
            token=token,
            token_id=token_id,
            amount=amount,
        )
    }

    #[internal]
    fn _execute_calls(mut calls: Array<Call>, mut res: Array<Span<felt252>>, nonce: felt) -> Array<Span<felt252>> {
        check_gas();
        let (caller) = get_caller_address();

        AccessControl::has_role(GuildRoles.MEMBER, caller);

        let current_nonce = _current_nonce::read();
        assert(current_nonce = nonce, "Guild: Invalid nonce");
        _current_nonce::write(value=current_nonce + 1);

        let tx_info = get_tx_info();
        let response = ArrayTrait::new();

        execute_list(calls_len, calls, response);
        // emit event
        ExecuteTransaction(
            account=caller, hash=tx_info.transaction_hash, response=response
        );
        return response;
    }

    #[external]
    fn execute_list(mut call: Call) -> Span<felt252> {
        check_gas();
        match calls.pop_front() {
            Option::Some(call) => {
                let _res = _execute_single_call(call);
                res.append(_res);
                return _execute_calls(calls, res);
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

        let fee_policy_manager_dispatcher = IFeePolicyManagerDispatcher{ contract_address: fee_policy_manager };

        let fee_policy = fee_policy_manager_dispatcher.get_fee_policy(
            contract_address, to, selector
        );

        if (!fee_policy.is_zero()) {
            let fee_policy_dispatcher = IFeePolicy{ contract_address: fee_policy };
            let (
                used_token_details: Array<TokenDetails>,
                accrued_token_details: Array<TokenDetails>
            ) = fee_policy_dispatcher.get_tokens(
                to, selector, calldata
            );

            let TokenDetails { used_token_standard, used_token, used_token_ids } = used_token_details;
            let TokenDetails { accrued_token_standard, accrued_token, accrued_token_ids } = accrued_token_details;

            let certificate_dispatcher = ICertificateDispatcher{ contract_address: guild_certificate };
            let owner = certificate_dispatcher.get_token_owner(
                used_token_standard, 
                used_token, 
                used_token_ids
            );

            let owner_balances = ArrayTrait::new();

            let certificate_id = certificate_dispatcher.get_certificate_id(caller, contract_address);

            // get the guild balance in order to assess whether the call can be made
            // (currently this is based on the owner balance of accrued tokens)

            loop_get_guild_balances(
                0,
                guild_certificate,
                certificate_id,
                accrued_token_details,
                owner_balances
            );

            // calls the fee policy to perform the check, returns bool if this was passed

            let has_balance = fee_policy_dispatcher.check_owner_balances(calldata, owner_balances);

            assert(has_balance, 'Owner under required token balances');

            let pre_balances = fee_policy_dispatcher.get_balances();

            // Actually execute it
            let res = starknet::call_contract_syscall(to, selector, calldata.span());

            let post_balances = fee_policy_dispatcher.get_balances();

            assert(pre_balances.len() == post_balances.len(), 'Policy balances length do not match');

            let difference_balances = ArrayTrait::new();

            FeePolicies::calculate_differences(pre_balances, post_balances, difference_balances);

            loop_update_balances(
                0,
                guild_certificate,
                certificate_id,
                accrued_token_details,
                difference_balances
            );

            // currently same as guild master
            let admin = AccessControl::get_admin();

            execute_payments(
                accrued_token_details,
                difference_balances,
                fee_policy,
                owner,
                caller,
                admin
            );
        }
    }

    #[external]
    fn initialize_permissions(permissions: Array<Permission>) {
        AccessContro::assert_admin();
        let permissions_initialized = _is_permissions_initialized::read();
        assert(!permissions_initialized, 'Permissions already initialized');
        set_permissions(permissions);
        _is_permissions_initialized::write(true)
    }

    #[external]
    fn set_permissions(permissions: Array<Permission>) {
        _set_permissions(0, permissions_len, permissions);
        let caller = get_caller_address();
        SetPermissions(caller, permissions)
    }

    #[external]
    fn set_fee_policy(
        fee_policy: ContractAddress, 
        caller_split: felt252, 
        owner_split: felt252, 
        admin_split: felt252,
        payment_type: felt252,
        payment_details: Array<PaymentDetails>
    ) {
        let fee_policy_manager = _fee_policy_manager::read();
        let fee_policy_manager_dispatcher = IFeePolicyManagerDispatcher {contract_address: fee_policy_manager};

        fee_policy_manager_dispatcher.set_fee_policy(
            fee_policy_manager, 
            fee_policy, 
            caller_split,
            owner_split, 
            admin_split,
            payment_details_len,
            payment_details
        )
    }

    // Internals

    #[internal]
    fn _set_permissions(permissions_index: u32, permissions_len: u32 permissions: Array<Permission>) {
        if (permissions_index == permissions_len) {
            return ();
        }

        _is_permission::write(permissions[permissions_index], true);

        return _set_permissions(
            permissions_index + 1_u32,
            permissions_len - 1_u32,
            permissions,
        );
    }

    #[internal]
    fn check_permitted_call(to: Contract, selector: ContractAddress) {
        let execute_call = Permission { to, selector };
        let is_permitted = _is_permission::read(execute_call);
        assert(is_permitted, 'Call is not permitted')
    }

    #[internal]
    fn loop_get_guild_balances(
        index: u32,
        guild_certificate: ContractAddress,
        certificate_id: u256,
        accrued_token_details: Array<TokenDetails>,
        owner_balances: Array<u256>
    ) {
        if index == accrued_token_details.len() {
            return ();
        }
        let TokenDetails { token_standard, token_address, token_ids } = accrued_token_details;

        loop_get_token_ids_balance(
            0,
            guild_certificate,
            certificate_id,
            token_standard,
            token_address,
            token_ids,
            owner_balances
        );

        return loop_get_guild_balances(
            index + 1,
            guild_certificate,
            certificate_id,
            accrued_token_details,
            owner_balances
        );
    }

    #[internal]
    fn loop_get_token_ids_balance(
        index: u32,
        guild_certificate: ContractAddress,
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        token_ids: Array<u256>,
        owner_balances: Array<u256>
    ) {
        if index == token_ids.len() {
            return ();
        }
        let certificate_dispatcher = ICertificateDispatcher { contract_address: guild_certificate };
        let amount = certificate_dispatcher.get_token_amount(
            guild_certificate,
            certificate_id,
            token_standard,
            token,
            token_ids[index],
        );

        owner_balances.at(index) = amount;

        return loop_get_token_ids_balance(
            index + 1_u32,
            guild_certificate,
            certificate_id,
            token_standard,
            token,
            token_ids,
            owner_balances
        );
    }

    #[internal]
    fn loop_update_balances{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
        index: u32,
        guild_certificate: ContractAddress,
        certificate_id: Uint256,
        token_details_len: felt,
        token_details: TokenDetails*,
        differences: felt*
    ) {
        if (index == token_details_len) {
            return ();
        }
        
        let token_standard = token_details.at(index).token_standard;
        let token = token_details.at(index).token;

        loop_update_token_ids_balance(
            0,
            guild_certificate,
            certificate_id,
            token_standard,
            token,
            token_details.at(index).token_ids_len,
            token_details.at(index).token_ids,
            differences
        );

        return loop_update_balances(
            index + 1_u32,
            guild_certificate,
            certificate_id,
            token_details_len,
            token_details,
            differences
        );

    }

    #[internal]
    fn loop_update_token_ids_balance(
        index: u32,
        guild_certificate: ContractAddress,
        certificate_id: u32,
        token_standard: felt252,
        token: ContractAddress,
        token_ids: Array<u256>,
        differences: Array<felt252>
    ) {
        if index == token_ids_len.len() {
            return ();
        }
        let certificate_dispatcher = ICertificateDispatcher { contract_address: guild_certificate };

        let current_balance = certificate_dispatcher.get_token_amount(
            certificate_id,
            token_standard,
            token,
            token_ids.at(index),
        );

        // if there is a change in guild balance remove or add from the owner
        // change in balance is calculated from Fee Policy
        if !differences.at(index).is_zero() {

            let new_amount = current_balance + differences[index];

            certificate_dispatcher.change_token_data(
                certificate_id,
                token_standard,
                token,
                token_ids.at(index),
                new_amount,
            );
        } else {

            // we already know the account has enough balance in guild
            let new_amount = current_balance + differences.at(index);

            certificate_dispatcher.change_token_data(
                certificate_id,
                token_standard,
                token,
                token_ids.at(index),
                u256 { low: 0_u128, high: 0_u128},
            );
        }

        return loop_update_token_ids_balance(
            index + 1,
            guild_certificate,
            certificate_id,
            token_standard,
            token,
            token_ids_len,
            token_ids,
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
        let data = ArrayTrait::new();

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
            0,
            difference_balances_len,
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


        loop_direct_payment(0, direct_payments_len, direct_payments, owner, caller, admin)
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
        if (index == accrued_token_details.len()) {
            return ();
        }

        let contract_address = get_contract_address();

        let TokenDetails {token_standard, token_address, token_ids} = accrued_token_details.at(index);

        if (token_standard == TokenStandard.ERC1155) {
            let erc1155_dispatcher = IERC1155Dispatcher { contract_address: token_address };

            let data = ArrayTrait::new();
            erc1155_dispatcher.safeBatchTransferFrom(
                contract_address,
                caller,
                token_ids,
                caller_balance.at(index).token_balances,
                data,
            );

            erc1155_dispatcher.safeBatchTransferFrom(
                contract_address,
                owner,
                token_ids,
                owner_balances.at(index).token_balances,
                data,
            );

            erc1155_dispatcher.safeBatchTransferFrom(
                contract_address,
                admin,
                token_ids,
                admin_balances.at(index).token_balances,
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
        direct_payments_len: u32,
        direct_payments: Array<PaymentDetails>,
        owner: ContractAddress,
        caller: ContractAddress,
        admin: ContractAddress
    ) {
        if index == direct_payments_len {
            return ();
        }

        let PaymentDetails { payment_token_standard, payment_token, payment_amount} = direct_payments.at(index);

        if payment_token_standard == TokenStandard::ERC20 {
            let erc20_dispatcher = IERC20Dispatcher { contract_address: payment_token };
            if index == Recipient::OWNER {
                erc20_dispatcher.transfer(
                    owner,
                    payment_amount
                );
            }

            if index == Recipient::CALLER {
                erc20_dispatcher.transfer(
                    caller,
                    payment_amount
                );
            }

            if index == Recipient::ADMIN {
                erc20_dispatcher.transfer(
                    admin,
                    payment_amount
                );
            }
        }

        return loop_direct_payment(
            index + 1_u32,
            direct_payments_len - 1_u32,
            direct_payments,
            owner,
            caller,
            admin
        );
    }
}