// SPDX-License-Identifier: MIT
%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub, uint256_lt, uint256_eq
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.interfaces.IGuildManager import IGuildManager

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.erc165.library import ERC165

from openzeppelin.access.ownable.library import Ownable

from contracts.lib.math_utils import MathUtils
from contracts.utils.helpers import find_value, find_uint256_value

from openzeppelin.upgrades.library import Proxy

//
// Structs
//

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
func MintCertificate(account: felt, role: felt, guild: felt, id: Uint256) {
}

@event
func BurnCertificate(account: felt, role: felt, guild: felt, id: Uint256) {
}

//
// Storage variables
//

@storage_var
func _guild_manager() -> (res: felt) {
}

@storage_var
func _certificate_id_count() -> (res: Uint256) {
}

@storage_var
func _certificate_id(owner: felt, guild: felt) -> (res: Uint256) {
}

@storage_var
func _role(certificate_id: Uint256) -> (res: felt) {
}

@storage_var
func _guild(certificate_id: Uint256) -> (res: felt) {
}

@storage_var
func token_owner(token_standard: felt, token: felt, token_id: Uint256) -> (res: felt) {
}

@storage_var
func _certificate_token_amount(
    certificate_id: Uint256, token_standard: felt, token: felt, token_id: Uint256
) -> (res: Uint256) {
}

@storage_var
func _certificate_tokens_data_len(certificate_id: Uint256) -> (res: felt) {
}

@storage_var
func _certificate_tokens_data(certificate_id: Uint256, index: felt) -> (res: Token) {
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
    let (name) = ERC721.name();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = ERC721.symbol();
    return (symbol,);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    let (balance: Uint256) = ERC721.balance_of(owner);
    return (balance,);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    let (owner: felt) = ERC721.owner_of(tokenId);
    return (owner,);
}

@view
func getUrl() -> (url_len: felt, url: felt*) {
    alloc_locals;
    let (url) = alloc();
    assert [url] = 104;
    assert [url + 1] = 116;
    assert [url + 2] = 116;
    assert [url + 3] = 112;
    assert [url + 4] = 115;
    assert [url + 5] = 58;
    assert [url + 6] = 47;
    assert [url + 7] = 47;
    assert [url + 8] = 103;
    assert [url + 9] = 97;
    assert [url + 10] = 116;
    assert [url + 11] = 101;
    assert [url + 12] = 119;
    assert [url + 13] = 97;
    assert [url + 14] = 121;
    assert [url + 15] = 46;
    assert [url + 16] = 112;
    assert [url + 17] = 105;
    assert [url + 18] = 110;
    assert [url + 19] = 97;
    assert [url + 20] = 116;
    assert [url + 21] = 97;
    assert [url + 22] = 46;
    assert [url + 23] = 99;
    assert [url + 24] = 108;
    assert [url + 25] = 111;
    assert [url + 26] = 117;
    assert [url + 27] = 100;
    assert [url + 28] = 47;
    assert [url + 29] = 105;
    assert [url + 30] = 112;
    assert [url + 31] = 102;
    assert [url + 32] = 115;
    assert [url + 33] = 47;
    assert [url + 34] = 81;
    assert [url + 35] = 109;
    assert [url + 36] = 85;
    assert [url + 37] = 110;
    assert [url + 38] = 52;
    assert [url + 39] = 66;
    assert [url + 40] = 90;
    assert [url + 41] = 116;
    assert [url + 42] = 122;
    assert [url + 43] = 52;
    assert [url + 44] = 116;
    assert [url + 45] = 119;
    assert [url + 46] = 51;
    assert [url + 47] = 114;
    assert [url + 48] = 122;
    assert [url + 49] = 112;
    assert [url + 50] = 90;
    assert [url + 51] = 72;
    assert [url + 52] = 112;
    assert [url + 53] = 84;
    assert [url + 54] = 50;
    assert [url + 55] = 111;
    assert [url + 56] = 69;
    assert [url + 57] = 111;
    assert [url + 58] = 54;
    assert [url + 59] = 103;
    assert [url + 60] = 117;
    assert [url + 61] = 119;
    assert [url + 62] = 50;
    assert [url + 63] = 70;
    assert [url + 64] = 120;
    assert [url + 65] = 115;
    assert [url + 66] = 105;
    assert [url + 67] = 80;
    assert [url + 68] = 69;
    assert [url + 69] = 121;
    assert [url + 70] = 118;
    assert [url + 71] = 102;
    assert [url + 72] = 82;
    assert [url + 73] = 70;
    assert [url + 74] = 110;
    assert [url + 75] = 85;
    assert [url + 76] = 74;
    assert [url + 77] = 87;
    assert [url + 78] = 122;
    assert [url + 79] = 90;
    return (80, url);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (tokenURI_len: felt, tokenURI: felt*) {
    let (tokenURI_len, tokenURI) = getUrl();
    return (tokenURI_len, tokenURI);
}

@view
func get_certificate_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, guild: felt
) -> (certificate_id: Uint256) {
    let (value) = _certificate_id.read(owner, guild);
    return (value,);
}

@view
func get_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    certificate_id: Uint256
) -> (role: felt) {
    let (value) = _role.read(certificate_id);
    return (value,);
}

@view
func get_guild{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    certificate_id: Uint256
) -> (guild: felt) {
    let (guild) = _guild.read(certificate_id);
    return (guild,);
}

@view
func get_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    certificate_id: Uint256
) -> (tokens_len: felt, tokens: Token*) {
    alloc_locals;
    let (tokens: Token*) = alloc();

    let (tokens_len) = _certificate_tokens_data_len.read(certificate_id);

    _get_tokens(
        tokens_index=0, tokens_len=tokens_len, tokens=tokens, certificate_id=certificate_id
    );

    return (tokens_len, tokens);
}

@view
func get_token_amount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    certificate_id: Uint256, token_standard: felt, token: felt, token_id: Uint256
) -> (amount: Uint256) {
    let (amount) = _certificate_token_amount.read(certificate_id, token_standard, token, token_id);
    return (amount,);
}

@view
func get_token_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_standard: felt, token: felt, token_id: Uint256
) -> (owner: felt) {
    let (owner) = token_owner.read(token_standard, token, token_id);
    return (owner,);
}

//
// Initialize & upgrade
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, guild_manager: felt, proxy_admin: felt
) {
    ERC721.initializer(name, symbol);
    _guild_manager.write(guild_manager);
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
// External
//

@external
func setTokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokenId: Uint256, tokenURI: felt
) {
    assert_only_guild();
    ERC721._set_token_uri(tokenId, tokenURI);
    return ();
}

@external
func transfer_ownership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_owner: felt
) {
    Ownable.transfer_ownership(new_owner);
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, guild: felt, role: felt
) {
    assert_only_guild();

    let (certificate_count) = _certificate_id_count.read();
    let (new_certificate_id, _) = uint256_add(certificate_count, Uint256(1, 0));
    _certificate_id_count.write(new_certificate_id);

    _certificate_id.write(to, guild, new_certificate_id);
    _role.write(new_certificate_id, role);
    _guild.write(new_certificate_id, guild);

    ERC721._mint(to, new_certificate_id);

    MintCertificate.emit(to, role, guild, new_certificate_id);

    return ();
}

@external
func update_role{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    certificate_id: Uint256, role: felt
) {
    assert_only_guild();

    _role.write(certificate_id, role);
    return ();
}

@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    account: felt, guild: felt
) {
    alloc_locals;
    let (certificate_id: Uint256) = _certificate_id.read(account, guild);
    let (role) = _role.read(certificate_id);
    ERC721.assert_only_token_owner(certificate_id);
    _role.write(certificate_id, 0);
    _guild.write(certificate_id, 0);
    ERC721._burn(certificate_id);
    BurnCertificate.emit(account, role, guild, certificate_id);
    return ();
}

@external
func guild_burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    account: felt, guild: felt
) {
    alloc_locals;
    assert_only_guild();
    let (certificate_id: Uint256) = _certificate_id.read(account, guild);
    let (role) = _role.read(certificate_id);
    _role.write(certificate_id, 0);
    _guild.write(certificate_id, 0);
    ERC721._burn(certificate_id);
    BurnCertificate.emit(account, role, guild, certificate_id);
    return ();
}

@external
func add_token_data{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    certificate_id: Uint256, token_standard: felt, token: felt, token_id: Uint256, amount: Uint256
) {
    assert_only_guild();

    _certificate_token_amount.write(certificate_id, token_standard, token, token_id, amount);

    let (tokens_len) = _certificate_tokens_data_len.read(certificate_id);

    let data = Token(token_standard, token, token_id, amount);
    _certificate_tokens_data.write(certificate_id, tokens_len, data);

    _certificate_tokens_data_len.write(certificate_id, tokens_len + 1);

    return ();
}

@external
func change_token_data{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    certificate_id: Uint256,
    token_standard: felt,
    token: felt,
    token_id: Uint256,
    new_amount: Uint256,
) {
    assert_only_guild();

    _certificate_token_amount.write(certificate_id, token_standard, token, token_id, new_amount);

    let (tokens_data_len) = _certificate_tokens_data_len.read(certificate_id);

    let (tokens_data_index) = get_tokens_data_index(
        certificate_id=certificate_id, token_standard=token_standard, token=token, token_id=token_id
    );

    let data = Token(token_standard, token, token_id, new_amount);

    _certificate_tokens_data.write(certificate_id, tokens_data_index, data);

    return ();
}

@view
func check_token_exists{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    certificate_id: Uint256, token_standard: felt, token: felt, token_id: Uint256
) -> (bool: felt) {
    alloc_locals;
    assert_only_guild();
    let (amount) = _certificate_token_amount.read(certificate_id, token_standard, token, token_id);
    let (check_amount) = uint256_lt(Uint256(0, 0), amount);
    return (check_amount,);
}

@view
func check_tokens_exist{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    certificate_id: Uint256
) -> (bool: felt) {
    alloc_locals;
    assert_only_guild();
    let (checks: Uint256*) = alloc();

    let (tokens_data_len) = _certificate_tokens_data_len.read(certificate_id);

    _check_tokens_exist(
        tokens_data_index=0,
        tokens_data_len=tokens_data_len,
        certificate_id=certificate_id,
        checks=checks,
    );

    let (sum) = MathUtils.uint256_array_sum(tokens_data_len, checks);

    let (bool) = uint256_lt(Uint256(0, 0), sum);

    return (bool,);
}

func _get_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokens_index: felt, tokens_len: felt, tokens: Token*, certificate_id: Uint256
) {
    if (tokens_index == tokens_len) {
        return ();
    }

    let (token) = _certificate_tokens_data.read(certificate_id, tokens_index);

    assert tokens[tokens_index] = token;

    return _get_tokens(
        tokens_index=tokens_index + 1,
        tokens_len=tokens_len,
        tokens=tokens,
        certificate_id=certificate_id,
    );
}

func _check_tokens_exist{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokens_data_index: felt, tokens_data_len: felt, certificate_id: Uint256, checks: Uint256*
) {
    let (token_data) = _certificate_tokens_data.read(certificate_id, tokens_data_index);

    let amount = token_data.amount;

    assert checks[tokens_data_index] = amount;

    return ();
}

func get_tokens_data_index{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    certificate_id: Uint256, token_standard: felt, token: felt, token_id: Uint256
) -> (index: felt) {
    alloc_locals;
    let (checks: felt*) = alloc();
    let (tokens_data_len) = _certificate_tokens_data_len.read(certificate_id);

    _get_tokens_data_index(
        tokens_data_index=0,
        tokens_data_len=tokens_data_len,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id,
        checks=checks,
    );

    let (index) = find_value(arr_index=0, arr_len=tokens_data_len, arr=checks, value=0);

    return (index,);
}

func _get_tokens_data_index{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokens_data_index: felt,
    tokens_data_len: felt,
    certificate_id: Uint256,
    token_standard: felt,
    token: felt,
    token_id: Uint256,
    checks: felt*,
) {
    if (tokens_data_index == tokens_data_len) {
        return ();
    }

    let (token_data) = _certificate_tokens_data.read(certificate_id, tokens_data_index);

    let check_token_standard = token_data.token_standard - token_standard;
    let check_token = token_data.token - token;
    let (check_token_id) = uint256_sub(token_data.token_id, token_id);

    let add_1 = check_token_standard + check_token;
    let check_token_data = add_1 + check_token_id.low;
    // let (check_token_data, _) = uint256_add(Uint256(add_1,0), check_token_id)

    assert checks[tokens_data_index] = check_token_data;

    return _get_tokens_data_index(
        tokens_data_index=tokens_data_index + 1,
        tokens_data_len=tokens_data_len,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id,
        checks=checks,
    );
}
