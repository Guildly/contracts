// SPDX-License-Identifier: MIT
%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin, SignatureBuiltin
from starkware.cairo.common.cairo_keccak.keccak import keccak_felts
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.cairo.common.memcpy import memcpy

from starkware.starknet.common.syscalls import (
    call_contract,
    get_caller_address,
    get_contract_address,
    get_tx_info,
)

from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.IERC721 import IERC721
from contracts.interfaces.IERC1155 import IERC1155
from contracts.interfaces.IGuildCertificate import IGuildCertificate

from contracts.access_control.accesscontrol_library import AccessControl
from contracts.lib.role import GuildRoles
from contracts.lib.token_standard import TokenStandard
from contracts.lib.math_utils import MathUtils
from contracts.utils.helpers import find_value

from starkware.cairo.common.uint256 import Uint256, uint256_lt, uint256_add, uint256_eq, uint256_sub

from openzeppelin.upgrades.library import Proxy

from contracts.token.constants import (
    IERC721_RECEIVER_ID,
    IERC1155_RECEIVER_ID,
    ON_ERC1155_RECEIVED_SELECTOR,
    IACCOUNT_ID,
)

//
// Structs
//

struct Call {
    to: felt,
    selector: felt,
    calldata_len: felt,
    calldata: felt*,
}

// Tmp struct introduced while we wait for Cairo
// to support passing '[Call]' to __execute__
struct CallArray {
    to: felt,
    selector: felt,
    data_offset: felt,
    data_len: felt,
}

struct Permission {
    to: felt,
    selector: felt,
}

struct Token {
    token_standard: felt,
    token: felt,
    token_id: Uint256,
    amount: Uint256,
}

//
// Events
//

@event
func MemberAdded(account: felt, role: felt) {
}

@event
func MemberRemoved(account: felt) {
}

@event
func MemberRoleUpdated(account: felt, new_role: felt) {
}

@event
func PermissionsSet(account: felt, permissions_len: felt, permissions: Permission*) {
}

@event
func TransactionExecuted(account: felt, hash: felt, response_len: felt, response: felt*) {
}

@event
func Deposited(
    account: felt,
    certificate_id: Uint256,
    token_standard: felt,
    token: felt,
    token_id: Uint256,
    amount: Uint256,
) {
}

@event
func Withdrawn(
    account: felt,
    certificate_id: Uint256,
    token_standard: felt,
    token: felt,
    token_id: Uint256,
    amount: Uint256,
) {
}

//
// Storage variables
//

@storage_var
func _name() -> (res: felt) {
}

@storage_var
func _is_permissions_initialized() -> (res: felt) {
}

@storage_var
func _is_blacklisted(account: felt) -> (res: felt) {
}

@storage_var
func _is_permission(permission: Permission) -> (res: felt) {
}

@storage_var
func _guild_certificate() -> (res: felt) {
}

@storage_var
func _current_nonce() -> (res: felt) {
}

//
// Guards
//

func require_not_blacklisted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) {
    let (is_blacklisted) = _is_blacklisted.read(account);

    with_attr error_message("Guild Contract: Account is blacklisted") {
        assert is_blacklisted = FALSE;
    }

    return ();
}

//
// Initialize & upgrade
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, master: felt, guild_certificate: felt, proxy_admin: felt
) {
    _name.write(name);
    _guild_certificate.write(guild_certificate);

    let (contract_address) = get_contract_address();

    IGuildCertificate.mint(
        contract_address=guild_certificate, to=master, guild=contract_address
    );

    Proxy.initializer(proxy_admin);
    AccessControl._set_admin(master);

    ERC165.register_interface(IACCOUNT_ID);
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
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    let (success) = ERC165.supports_interface(interfaceId);
    return (success,);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = _name.read();
    return (name,);
}

@view
func guild_certificate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    guild_certificate: felt
) {
    let (guild_certificate) = _guild_certificate.read();
    return (guild_certificate,);
}

@view
func is_permissions_initialized{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (res: felt) {
    let (initialized) = _is_permissions_initialized.read();
    return (res=initialized);
}

@view
func get_nonce{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = _current_nonce.read();
    return (res=res);
}

//
// Externals
//

@external
func add_member{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    account: felt, role: felt
) {
    let (guild_certificate) = _guild_certificate.read();
    let (contract_address) = get_contract_address();
    let (caller_address) = get_caller_address();

    require_not_blacklisted(caller_address);

    IGuildCertificate.mint(
        contract_address=guild_certificate,
        to=account,
        guild=contract_address
    );

    AccessControl.grant_role(role, account);

    MemberAdded.emit(account, role);

    return ();
}

@external
func leave{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}() {
    let (guild_certificate) = _guild_certificate.read();
    let (contract_address) = get_contract_address();
    let (caller_address) = get_caller_address();

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate, owner=caller_address, guild=contract_address
    );

    let (check) = IGuildCertificate.check_tokens_exist(
        contract_address=guild_certificate, certificate_id=certificate_id
    );

    with_attr error_message("Guild Contract: Cannot leave, account has items in guild") {
        assert check = FALSE;
    }

    IGuildCertificate.guild_burn(
        contract_address=guild_certificate, account=caller_address, guild=contract_address
    );

    let roles: felt = AccessControl.get_roles(caller_address);
    AccessControl.revoke_role(roles, caller_address);

    return ();
}

@external
func remove_member{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(account: felt) {
    alloc_locals;

    let (caller_address) = get_caller_address();
    let (contract_address) = get_contract_address();
    let (guild_certificate) = _guild_certificate.read();

    AccessControl.has_role(GuildRoles.ADMIN, caller_address);

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate, owner=account, guild=contract_address
    );

    let (check) = IGuildCertificate.check_tokens_exist(
        contract_address=guild_certificate, certificate_id=certificate_id
    );

    if (check == TRUE) {
        force_transfer_items(certificate_id, account);
        IGuildCertificate.guild_burn(
            contract_address=guild_certificate, account=account, guild=contract_address
        );
        let roles: felt = AccessControl.get_roles(account);
        AccessControl.revoke_role(roles, account);
        _is_blacklisted.write(account, TRUE);
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        IGuildCertificate.guild_burn(
            contract_address=guild_certificate, account=account, guild=contract_address
        );
        let roles: felt = AccessControl.get_roles(account);
        AccessControl.revoke_role(roles, account);
        _is_blacklisted.write(account, TRUE);
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    MemberRemoved.emit(account=account);
    return ();
}

@external
func update_roles{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    account: felt, new_roles: felt
) {
    alloc_locals;

    let (caller_address) = get_caller_address();
    let (contract_address) = get_contract_address();
    let (guild_certificate) = _guild_certificate.read();

    AccessControl.has_role(GuildRoles.ADMIN, caller_address);

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate, owner=account, guild=contract_address
    );

    let roles: felt = AccessControl.get_roles(account);
    AccessControl.revoke_role(roles, account);
    AccessControl.grant_role(new_roles, account);

    MemberRoleUpdated.emit(account, new_roles);

    return ();
}

@external
func deposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    token_standard: felt, token: felt, token_id: Uint256, amount: Uint256
) {
    alloc_locals;

    local syscall_ptr: felt* = syscall_ptr;
    local pedersen_ptr: HashBuiltin* = pedersen_ptr;
    local range_check_ptr = range_check_ptr;

    let (caller_address) = get_caller_address();

    AccessControl.has_role(GuildRoles.OWNER, caller_address);

    let (check_not_zero) = uint256_lt(Uint256(0, 0), amount);

    with_attr error_message("Guild Contract: Amount cannot be 0") {
        assert check_not_zero = TRUE;
    }

    if (token_standard == TokenStandard.ERC721) {
        let (check_one) = uint256_eq(amount, Uint256(1, 0));
        with_attr error_message("Guild Contract: ERC721 amount must be 1") {
            assert check_one = TRUE;
        }
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    let (guild_certificate) = _guild_certificate.read();
    let (contract_address) = get_contract_address();

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate, owner=caller_address, guild=contract_address
    );

    let (check_exists) = IGuildCertificate.check_token_exists(
        contract_address=guild_certificate,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id,
    );

    if (token_standard == TokenStandard.ERC721) {
        with_attr error_message("Guild Contract: Caller certificate already holds ERC721 token") {
            assert check_exists = FALSE;
        }
        IERC721.transferFrom(
            contract_address=token, from_=caller_address, to=contract_address, tokenId=token_id
        );
        IGuildCertificate.add_token_data(
            contract_address=guild_certificate,
            certificate_id=certificate_id,
            token_standard=token_standard,
            token=token,
            token_id=token_id,
            amount=amount,
        );
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    let (initial_amount) = IGuildCertificate.get_token_amount(
        contract_address=guild_certificate,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id,
    );

    let (new_amount, _) = uint256_add(initial_amount, amount);

    if (token_standard == TokenStandard.ERC1155) {
        let (data: felt*) = alloc();
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        assert data[0] = 0;
        IERC1155.safeTransferFrom(
            contract_address=token,
            from_=caller_address,
            to=contract_address,
            tokenId=token_id,
            amount=amount,
            data_len=1,
            data=data,
        );
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        if (check_exists == TRUE) {
            IGuildCertificate.change_token_data(
                contract_address=guild_certificate,
                certificate_id=certificate_id,
                token_standard=token_standard,
                token=token,
                token_id=token_id,
                new_amount=new_amount,
            );
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            IGuildCertificate.add_token_data(
                contract_address=guild_certificate,
                certificate_id=certificate_id,
                token_standard=token_standard,
                token=token,
                token_id=token_id,
                amount=amount,
            );
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    Deposited.emit(
        account=caller_address,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id,
        amount=amount,
    );
    return ();
}

@external
func withdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    token_standard: felt, token: felt, token_id: Uint256, amount: Uint256
) {
    alloc_locals;

    let (caller_address) = get_caller_address();

    AccessControl.has_role(GuildRoles.OWNER, caller_address);

    local syscall_ptr: felt* = syscall_ptr;
    local pedersen_ptr: HashBuiltin* = pedersen_ptr;
    local range_check_ptr = range_check_ptr;

    if (token_standard == TokenStandard.ERC721) {
        let (check_one) = uint256_eq(amount, Uint256(1, 0));
        with_attr error_message("Guild Contract: ERC721 amount must be 1") {
            assert check_one = TRUE;
        }
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    let (guild_certificate) = _guild_certificate.read();
    let (contract_address) = get_contract_address();

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate, owner=caller_address, guild=contract_address
    );

    let (check_exists) = IGuildCertificate.check_token_exists(
        contract_address=guild_certificate,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id,
    );

    with_attr error_message("Guild Contract: Caller certificate doesn't hold tokens") {
        assert check_exists = TRUE;
    }

    if (token_standard == TokenStandard.ERC721) {
        IERC721.transferFrom(
            contract_address=token, from_=contract_address, to=caller_address, tokenId=token_id
        );
        IGuildCertificate.change_token_data(
            contract_address=guild_certificate,
            certificate_id=certificate_id,
            token_standard=token_standard,
            token=token,
            token_id=token_id,
            new_amount=Uint256(0, 0),
        );
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    let (initial_amount) = IGuildCertificate.get_token_amount(
        contract_address=guild_certificate,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id,
    );

    let (new_amount) = uint256_sub(initial_amount, amount);

    if (token_standard == TokenStandard.ERC1155) {
        let (data: felt*) = alloc();
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        assert data[0] = 0;
        IERC1155.safeTransferFrom(
            contract_address=token,
            from_=contract_address,
            to=caller_address,
            tokenId=token_id,
            amount=amount,
            data_len=1,
            data=data,
        );
        IGuildCertificate.change_token_data(
            contract_address=guild_certificate,
            certificate_id=certificate_id,
            token_standard=token_standard,
            token=token,
            token_id=token_id,
            new_amount=new_amount,
        );
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    Withdrawn.emit(
        account=caller_address,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id,
        amount=amount,
    );

    return ();
}

@external
func execute_transactions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    call_array_len: felt, call_array: CallArray*, calldata_len: felt, calldata: felt*, nonce: felt
) -> (retdata_len: felt, retdata: felt*) {
    alloc_locals;

    let (caller) = get_caller_address();

    AccessControl.has_role(GuildRoles.MEMBER, caller);

    let (calls: Call*) = alloc();

    from_call_array_to_call(call_array_len, call_array, calldata, calls);

    let calls_len = call_array_len;

    let (current_nonce) = _current_nonce.read();
    assert current_nonce = nonce;
    _current_nonce.write(value=current_nonce + 1);

    let (tx_info) = get_tx_info();

    let (response: felt*) = alloc();

    let (response_len) = execute_list(calls_len, calls, response);
    // emit event
    TransactionExecuted.emit(
        account=caller, hash=tx_info.transaction_hash, response_len=response_len, response=response
    );
    return (retdata_len=response_len, retdata=response);
}

func execute_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    calls_len: felt, calls: Call*, response: felt*
) -> (response_len: felt) {
    alloc_locals;

    // if no more calls
    if (calls_len == 0) {
        return (0,);
    }

    let this_call: Call = [calls];

    // Check the tranasction is permitted
    check_permitted_call(this_call.to, this_call.selector);

    // Actually execute it
    let res = call_contract(
        contract_address=this_call.to,
        function_selector=this_call.selector,
        calldata_size=this_call.calldata_len,
        calldata=this_call.calldata,
    );

    // copy the result in response
    memcpy(response, res.retdata, res.retdata_size);
    // do the next calls recursively
    let (response_len) = execute_list(
        calls_len - 1, calls + Call.SIZE, response + res.retdata_size
    );
    return (response_len + res.retdata_size,);
}

@external
func initialize_permissions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    permissions_len: felt, permissions: Permission*
) {
    AccessControl.assert_admin();

    let (check_initialized) = _is_permissions_initialized.read();

    with_attr error_message("Guild Contract: Permissions already initialized") {
        assert check_initialized = FALSE;
    }

    set_permissions(permissions_len=permissions_len, permissions=permissions);

    _is_permissions_initialized.write(TRUE);

    return ();
}

@external
func set_permissions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    permissions_len: felt, permissions: Permission*
) {
    alloc_locals;

    local syscall_ptr: felt* = syscall_ptr;
    local pedersen_ptr: HashBuiltin* = pedersen_ptr;
    local range_check_ptr = range_check_ptr;

    _set_permissions(permissions_index=0, permissions_len=permissions_len, permissions=permissions);

    let (caller) = get_caller_address();

    PermissionsSet.emit(account=caller, permissions_len=permissions_len, permissions=permissions);
    return ();
}

func _set_permissions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    permissions_index: felt, permissions_len: felt, permissions: Permission*
) {
    if (permissions_index == permissions_len) {
        return ();
    }

    _is_permission.write(permissions[permissions_index], TRUE);

    return _set_permissions(
        permissions_index=permissions_index + 1,
        permissions_len=permissions_len,
        permissions=permissions,
    );
}

func check_permitted_call{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, selector: felt
) {
    alloc_locals;
    let execute_call = Permission(to, selector);

    let (is_permitted) = _is_permission.read(execute_call);

    with_attr error_mesage("Guild Contract: Contract is not permitted") {
        assert is_permitted = TRUE;
    }
    return ();
}

func from_call_array_to_call{syscall_ptr: felt*}(
    call_array_len: felt, call_array: CallArray*, calldata: felt*, calls: Call*
) {
    // if no more calls
    if (call_array_len == 0) {
        return ();
    }

    // parse the current call
    assert [calls] = Call(
        to=[call_array].to,
        selector=[call_array].selector,
        calldata_len=[call_array].data_len,
        calldata=calldata + [call_array].data_offset
        );

    // parse the remaining calls recursively
    return from_call_array_to_call(
        call_array_len - 1, call_array + CallArray.SIZE, calldata, calls + Call.SIZE
    );
}

func force_transfer_items{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    certificate_id: Uint256, account: felt
) {
    let (guild_certificate) = _guild_certificate.read();

    let (tokens_len, tokens: Token*) = IGuildCertificate.get_tokens(
        contract_address=guild_certificate, certificate_id=certificate_id
    );

    return _force_transfer_items(
        tokens_index=0, tokens_len=tokens_len, tokens=tokens, account=account
    );
}

func _force_transfer_items{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokens_index: felt, tokens_len: felt, tokens: Token*, account: felt
) {
    alloc_locals;
    if (tokens_index == tokens_len) {
        return ();
    }

    let token = tokens[tokens_index];

    let (check_amount) = uint256_lt(Uint256(0, 0), token.amount);

    let (contract_address) = get_contract_address();
    let (guild_certificate) = _guild_certificate.read();

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate, owner=account, guild=contract_address
    );

    if (check_amount == TRUE) {
        if (token.token_standard == TokenStandard.ERC721) {
            IERC721.transferFrom(
                contract_address=token.token,
                from_=contract_address,
                to=account,
                tokenId=token.token_id,
            );
            IGuildCertificate.change_token_data(
                contract_address=guild_certificate,
                certificate_id=certificate_id,
                token_standard=token.token_standard,
                token=token.token,
                token_id=token.token_id,
                new_amount=Uint256(0, 0),
            );
            tempvar contract_address = contract_address;
            tempvar guild_certificate = guild_certificate;
            tempvar certificate_id: Uint256 = certificate_id;
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar contract_address = contract_address;
            tempvar guild_certificate = guild_certificate;
            tempvar certificate_id: Uint256 = certificate_id;
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }

        if (token.token_standard == TokenStandard.ERC1155) {
            let (data: felt*) = alloc();
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar guild_certificate = guild_certificate;
            tempvar certificate_id: Uint256 = certificate_id;
            assert data[0] = 0;
            IERC1155.safeTransferFrom(
                contract_address=token.token,
                from_=contract_address,
                to=account,
                tokenId=token.token_id,
                amount=token.amount,
                data_len=1,
                data=data,
            );
            IGuildCertificate.change_token_data(
                contract_address=guild_certificate,
                certificate_id=certificate_id,
                token_standard=token.token_standard,
                token=token.token,
                token_id=token.token_id,
                new_amount=Uint256(0, 0),
            );
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    return _force_transfer_items(
        tokens_index=tokens_index + 1, tokens_len=tokens_len, tokens=tokens, account=account
    );
}

//
// Receivers
//

@external
func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, _from: felt, id: Uint256, data_len: felt, data: felt*
) -> (value: felt) {
    return (value=IERC1155_RECEIVER_ID);
}

@external
func onERC1155Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, _from: felt, id: Uint256, value: Uint256, data_len: felt, data: felt*
) -> (value: felt) {
    return (value=ON_ERC1155_RECEIVED_SELECTOR);
}
