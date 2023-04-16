use serde::Serde;
use array::ArrayTrait;
use array::SpanTrait;
use starknet::ContractAddress;
use starknet::contract_address::ContractAddressSerde;
use openzeppelin::utils::check_gas;

//
// Structs
//

struct Call {
    to: ContractAddress,
    selector: ContractAddress,
    calldata: Array<felt252>
}

struct Permission {
    to: ContractAddress,
    selector: ContractAddress,
}

struct Token {
    token_standard: felt252,
    token: ContractAddress,
    token_id: u256,
    amount: u256,
}

#[contract]
mod Guild {
    use box::BoxTrait;
    use array::SpanTrait;
    use array::ArrayTrait;
    use option::OptionTrait;
    use zeroable::Zeroable;
    use ecdsa::check_ecdsa_signature;
    use starknet::get_tx_info;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::contract_address::ContractAddressPartialEq;
    use starknet::contract_address::ContractAddressZeroable;

    use guild_contracts::token::erc20::IERC20;
    use guild_contracts::token::erc721::IERC721;
    use guild_contracts::introspection::erc165::ERC165Contract;
    use guild_contracts::utils::check_gas;
    use openzeppelin::upgrades::library::Proxy;

    use guild_contracts::token::erc1155::IERC1155;
    use guild_contracts::certificate::ICertificate;
    use guild_contracts::fee_policies::IFeePolicyManager;
    use guild_contracts::fee_policies::IFeePolicy;
    use guild_contracts::access_control::accesscontrol_library::AccessControl;
    use guild_contracts::constants::Roles;
    use guild_contracts::constants::TokenStandard;
    use guild_contracts::math_utils::MathUtils;
    use guild_contracts::fee_policies::lib::PaymentDetails;
    use guild_contracts::fee_policies::lib::FeePolicies;
    use guild_contracts::fee_policies::lib::TokenDetails;
    use guild_contracts::fee_policies::lib::TokenBalances;
    use guild_contracts::fee_policies::lib::TokenDifferences;
    use guild_contracts::fee_policies::lib::Recipient;
    use guild_contracts::utils::helpers::find_value;
    use guild_contracts::token::constants::IERC721_RECEIVER_ID;
    use guild_contracts::token::constants::IERC1155_RECEIVER_ID;
    use guild_contracts::token::constants::ON_ERC1155_RECEIVED_SELECTOR;
    use guild_contracts::token::constants::IACCOUNT_ID;

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

    //
    // Events
    //

    #[event]
    fn WhitelistMember(account: ContractAddress, role: ContractAddress) {
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
        assert(is_blacklisted = false, "Guild Contract: Account is blacklisted")
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
        IGuildCertificate { contract_address: guild_certificate }.mint(master, contract_address);

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
        _current_nonce::read();
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
        IGuildCertificate { contract_address: guild_certificate }.mint(account, contract_address);
        AccessControl::grant_role(role, account);

        WhitelistMember(account, role)
    }

    #[external]
    fn leave() {
        let guild_certificate = _guild_certificate::read();
        let contract_address = get_contract_address();
        let caller_address = get_caller_address();

        let certificate_id = IGuildCertificate{ contract_address: guild_certificate }.get_certificate_id(
            caller_address, contract_address
        );

        let check = IGuildCertificate{ contract_address: guild_certificate }.check_tokens_exist(
            certificate_id
        );

        assert(check == FALSE, "Guild Contract: Cannot leave, account has items in guild");

        IGuildCertificate { contract_address: guild_certificate }.guild_burn(caller_address, contract_address);

        let roles = AccessControl::get_roles(caller_address);
        AccessControl::revoke_role(roles, caller_address)
    }

    #[external]
    fn remove_member(account: ContractAddress) {
        let caller_address = get_caller_address();
        let contract_address = get_contract_address();
        let guild_certificate = _guild_certificate::read();

        AccessControl::has_role(GuildRoles.ADMIN, caller_address);
        let certificate_id = IGuildCertificate{ contract_address: guild_certificate }.get_certificate_id(
            account, contract_address
        );
        let check = IGuildCertificate{ contract_address: guild_certificate }.check_tokens_exist(
            certificate_id
        );

        assert(1 == false, 'Member holds items in guild.');
        IGuildCertificate { contract_address: guild_certificate }.guild_burn(account, contract_address);
        let roles = AccessControl::get_roles(account);
        AccessControl::revoke_role(roles, account);
        _is_blacklisted::write(account, TRUE);
        }

        RemoveMember(account)
    }

    #[external]
    fn force_transfer_item(token: Token, account: ContractAddress) {
        let contract_address = get_contract_address();
        let guild_certificate = _guild_certificate::read();

        AccessControl::has_role(GuildRoles.ADMIN, caller_address);

        let certificate_id = IGuildCertificate { contract_address=guild_certificate }.get_certificate_id(
            owner=account, guild=contract_address
        );


        assert(token.amount > 0_uint256, 'Amount must be > 0.');

        if (token.token_standard == TokenStandard.ERC721) {
            IERC721 { contract_address=token.token }.transferFrom(
                from_=contract_address,
                to=account,
                tokenId=token.token_id,
            );
            IGuildCertificate { contract_address=guild_certificate }.change_token_data(
                certificate_id=certificate_id,
                token_standard=token.token_standard,
                token=token.token,
                token_id=token.token_id,
                new_amount=Uint256(0, 0),
            );
        } 

        if (token.token_standard == TokenStandard.ERC1155) {
            let data = ArrayTrait::new();
            data[0] = 0;
            IERC1155 { contract_address=token.token }.safeTransferFrom(
                from_=contract_address,
                to=account,
                tokenId=token.token_id,
                amount=token.amount,
                data=data,
            );
            IGuildCertificate { contract_address=guild_certificate }.change_token_data(
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

        let certificate_id = IGuildCertificate{ contract_address: guild_certificate }.get_certificate_id(
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

        let certificate_id = IGuildCertificate{ contract_address: guild_certificate }.get_certificate_id(
            caller_address, contract_address
        );

        let check_exists = IGuildCertificate{ contract_address: guild_certificate }.check_token_exist(
            certificate_id, token_standard, token, token_id
        );

        if (token_standard == TokenStandard.ERC721) {
            assert(check_exists, "Guild Contract: Caller certificate already holds ERC721 token");
            IERC721 { contract_address: token}.transferFrom(
                caller_address, contract_address, token_id
            );
            IGuildCertificate { contract_address: guild_certificate}.add_token_data(
                certificate_id,
                token_standard,
                token,
                token_id,
                amount,
            );
        }

        let initial_amount = IGuildCertificate { contract_address: guild_certificate }.get_token_amount(
            certificate_id,
            token_standard,
            token,
            token_id,
        );

        let (new_amount, _) = uint256_add(initial_amount, amount);

        if (token_standard == TokenStandard.ERC1155) {
            let data = ArrayTrait::new();
            data[0] = 0;
            IERC1155 { contract_address: token }.safeTransferFrom(
                caller_address,
                contract_address,
                token_id,
                amount,
                data
            );
            if (check_exists == TRUE) {
                IGuildCertificate { contract_address: guild_certificate }.change_token_data(
                    certificate_id,
                    token_standard,
                    token,
                    token_id,
                    new_amount,
                );
            } else {
                IGuildCertificate { contract_address: guild_certificate }.add_token_data(
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
            assert(amount == 1_u256, "Guild Contract: ERC721 amount must be 1");
        }

        let guild_certificate = _guild_certificate.read();
        let contract_address = get_contract_address();

        let certificate_id = IGuildCertificate { contract_address: guild_certificate }.get_certificate_id(
            caller_address, contract_address
        );

        let check_exists = IGuildCertificate { contract_address: guild_certificate }.check_token_exists(
            certificate_id,
            token_standard,
            token,
            token_id,
        );

        assert(check_exists, "Guild Contract: Caller certificate doesn't hold tokens");

        if (token_standard == TokenStandard.ERC721) {
            IERC721 { contract_address: token }.transferFrom(
                contract_address, caller_address, token_id
            );
            IGuildCertificate { contract_address: guild_certificate }.change_token_data(
                certificate_id,
                token_standard,
                token,
                token_id,
                0_u256,
            );
        }

        let initial_amount = IGuildCertificate { contract_address: guild_certificate }.get_token_amount(
            certificate_id,
            token_standard,
            token,
            token_id,
        );

        let new_amount = initial_amount - amount;

        if (token_standard == TokenStandard.ERC1155) {
            let data = ArrayTrait::new();
            data[0] = 0;
            IERC1155 { contract_address: token }.safeTransferFrom(
                contract_address,
                caller_address,
                token_id,
                amount,
                data,
            );
            IGuildCertificate { contract_address: guild_certificate }.change_token_data(
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

        let Call{to, selector, calldata } = call;

        // Check the tranasction is permitted
        check_permitted_call(to, selector);

        let fee_policy = IFeePolicyManager{ contract_address: fee_policy_manager }.get_fee_policy(
            contract_address, to, selector
        );

        if (!fee_policy.is_zero()) {
            let (
                used_token_details: Array<TokenDetails>,
                accrued_token_details: Array<TokenDetails>
            ) = IFeePolicy{ contract_address: fee_policy }.get_tokens(
                this_call.to, this_call.selector, this_call.calldata_len, this_call.calldata
            );

            let TokenDetails{used_token_standard, used_token, used_token_ids } = used_token_details;
            let TokenDetails{accrued_token_standard, accrued_token, accrued_token_ids } = accrued_token_details;

            let (owner) = IGuildCertificate{ contract_address: guild_certificate }.get_token_owner(
                used_token_standard, 
                used_token, 
                used_token_ids
            );

            let owner_balances = ArrayTrait::new();

            let certificate_id= IGuildCertificate{ contract_address: guild_certificate }.get_certificate_id(
                caller, contract_address
            );

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

            let has_balance = IFeePolicy{ contract_address: fee_policy }.check_owner_balances(
                calldata,
                owner_balances
            );

            assert(has_balance, "Guild Contract: Owner doesn't have required token balances according to Policy");

            let pre_balances = IFeePolicy{ contract_address: fee_policy }.get_balances();

            // Actually execute it
            let res = starknet::call_contract_syscall(to, selector, calldata.span()).unwrap_syscall();

            let post_balances = IFeePolicy{ contract_address: fee_policy }.get_balances();

            assert(pre_balances.len() = post_balances.len(), "Guild Contract: Policy balances length do not match");

            let difference_balances = ArrayTrait::new();

            FeePolicies::calculate_differences(
                pre_balances,
                post_balances,
                difference_balances,
            );

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
                accrued_token_details_len,
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
        assert(!permissions_initialized, "Guild Contract: Permissions already initialized");
        set_permissions(permissions);
        _is_permissions_initialized::write(TRUE)
    }

    #[external]
    fn set_permissions(permissions: Array<Permission>) {
        _set_permissions(permissions_index=0, permissions_len=permissions_len, permissions=permissions);
        let caller = get_caller_address();
        SetPermissions(caller, permissions_len, permissions)
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

        IFeePolicyManager.set_fee_policy(
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
    fn _set_permissions(permissions_index: felt252, permissions_len: felt252 permissions: Array<Permission>) {
        if (permissions_index == permissions_len) {
            return ();
        }

        _is_permission::write(permissions[permissions_index], true);

        return _set_permissions(
            permissions_index + 1,
            permissions_len,
            permissions,
        );
    }

    #[internal]
    fn check_permitted_call(to: felt252, selector: felt252) {
        let execute_call = Permission(to, selector);
        let is_permitted = _is_permission::read(execute_call);
        assert(is_permitted, "Guild Contract: Contract is not permitted")
    }

    #[internal]
    fn loop_get_guild_balances(
        index: felt252,
        guild_certificate: ContractAddress,
        certificate_id: u256,
        accrued_token_details: Array<TokenDetails>,
        owner_balances: Array<u256>
    ) {
        if (index == accrued_token_details.len()) {
            return ();
        }
        let TokenDetails{token_standard, token_address, token_ids } = accrued_token_details;

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
        index: felt252,
        guild_certificate: ContractAddress,
        certificate_id: u256,
        token_standard: felt252,
        token: felt252,
        token_ids: Array<u256>,
        owner_balances: Array<u256>
    ) {
        if (index == token_ids.len()) {
            return ();
        }
        
        let amount = IGuildCertificate.get_token_amount(
            guild_certificate,
            certificate_id,
            token_standard,
            token,
            token_ids[index],
        );

        assert owner_balances[index] = amount;

        return loop_get_token_ids_balance(
            index + 1,
            guild_certificate,
            certificate_id,
            token_standard,
            token,
            token_ids_len,
            token_ids,
            owner_balances
        );
    }

    #[internal]
    fn loop_update_balances{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
        index: felt,
        guild_certificate: felt,
        certificate_id: Uint256,
        token_details_len: felt,
        token_details: TokenDetails*,
        differences: felt*
    ) {
        if (index == token_details_len) {
            return ();
        }
        
        let token_standard = token_details[index].token_standard;
        let token = token_details[index].token;

        loop_update_token_ids_balance(
            0,
            guild_certificate,
            certificate_id,
            token_standard,
            token,
            token_details[index].token_ids_len,
            token_details[index].token_ids,
            differences
        );

        return loop_update_balances(
            index + 1,
            guild_certificate,
            certificate_id,
            token_details_len,
            token_details,
            differences
        );

    }

    #[internal]
    fn loop_update_token_ids_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
        index: felt,
        guild_certificate: felt,
        certificate_id: Uint256,
        token_standard: felt,
        token: felt,
        token_ids_len: felt,
        token_ids: Uint256*,
        differences: felt*
    ) {
        if (index == token_ids_len) {
            return ();
        }

        let current_balance = IGuildCertificate{ contract_address: guild_certificate }.get_token_amount(
            certificate_id,
            token_standard,
            token,
            token_ids[index],
        );

        // if there is a change in guild balance remove or add from the owner
        // change in balance is calculated from Fee Policy
        if (!differences[index].is_zero()) {

            let new_amount = current_balance + differences[index];

            IGuildCertificate{ contract_address: guild_certificate }.change_token_data(
                certificate_id,
                token_standard,
                token,
                token_ids[index],
                new_amount,
            );
        } else {

            // we already know the account has enough balance in guild
            let new_amount = current_balance + differences[index];

            IGuildCertificate{ contract_address: guild_certificate }.change_token_data(
                certificate_id,
                token_standard,
                token,
                token_ids[index],
                new_amount=0_u256,
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
            differences + Uint256.SIZE
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
        data[0] = 1;

        let contract_address = get_contract_address();

        let fee_policy_manager = _fee_policy_manager::read();

        let (caller_split, owner_split, admin_split) = IFeePolicyManager{ contract_address: fee_policy_manager }.get_policy_distribution(
            contract_address, fee_policy
        );

        let direct_payments = IFeePolicyManager{ contract_address: fee_policy_manager }.get_direct_payments(
            contract_address, fee_policy
        );

        let caller_balances = ArrayTrait::new();
        let owner_balances = ArrayTrait::new();
        let admin_balances = ArrayTrait::new();

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
            accrued_token_details_len, 
            accrued_token_details,
            owner,
            difference_balances_len,
            owner_balances,
            caller,
            difference_balances_len,
            caller_balances,
            admin,
            difference_balances_len,
            admin_balances
        );


        loop_direct_payment(0, direct_payments_len, direct_payments, owner, caller, admin)
    }

    #[internal]
    fn loop_distribute_reward(
        index: felt,
        accrued_token_details: Array<TokenDetails>,
        owner: felt,
        owner_balances: Array<TokenBalances>,
        caller: felt,
        caller_balances: Array<TokenBalances>,
        admin: felt,
        admin_balances: Array<TokenBalances>
    ) {
        if (index == accrued_token_details.len()) {
            return ();
        }

        let contract_address = get_contract_address();

        let TokenDetails{token_standard, token_address, token_ids} = accrued_token_details[index];

        if (token_standard == TokenStandard.ERC1155) {

            let (data) = ArrayTrait::new();
            data[0] = 1;
            IERC1155{ contract_address: token_address }.safeBatchTransferFrom(
                contract_address,
                caller,
                token_ids,
                amounts=caller_balances[index].token_balances,
                data=data,
            );

            IERC1155{ contract_address: token_address }.safeBatchTransferFrom(
                contract_address,
                owner,
                token_ids,
                amounts=owner_balances[index].token_balances,
                data=data,
            );

            IERC1155{ contract_address: token_address }.safeBatchTransferFrom(
                contract_address,
                admin,
                token_ids,
                admin_balances[index].token_balances,
                data,
            );

        }

        return loop_distribute_reward(
            index + 1,
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
        index: felt252,
        direct_payments_len: felt252,
        direct_payments: Array<PaymentDetails>,
        owner: ContractAddress,
        caller: ContractAddress,
        admin: ContractAddress
    ) {
        if (index == direct_payments_len) {
            return ();
        }

        let PaymentDetails{ payment_token_standard, payment_token, payment_amount} = direct_payments[index];

        if (payment_token_standard == TokenStandard.ERC20) {
            if (index == Recipient.OWNER) {
                IERC20{ contract_address: payment_token }.transfer(
                    owner,
                    payment_amount
                );
            }

            if (index == Recipient.CALLER) {

                IERC20{ contract_address: payment_token }.transfer(
                    caller,
                    payment_amount
                );
            }

            if (index == Recipient.ADMIN) {

                IERC20{ contract_address: payment_token }.transfer(
                    admin,
                    payment_amount
                );
            }
        }

        return loop_direct_payment(
            index + 1,
            direct_payments_len,
            direct_payments,
            owner,
            caller,
            admin
        );
    }
}