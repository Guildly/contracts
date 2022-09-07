// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.1.0 (token/erc721/ERC721_Mintable_Burnable.cairo)

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.erc165.library import ERC165

from openzeppelin.access.ownable.library import Ownable

@storage_var
func _token_id_count() -> (res: Uint256) {
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, owner: felt
) {
    ERC721.initializer(name, symbol);
    Ownable.initializer(owner);
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
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    let (approved: felt) = ERC721.get_approved(tokenId);
    return (approved,);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved,);
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
    assert [url + 36] = 90;
    assert [url + 37] = 100;
    assert [url + 38] = 51;
    assert [url + 39] = 120;
    assert [url + 40] = 70;
    assert [url + 41] = 110;
    assert [url + 42] = 51;
    assert [url + 43] = 74;
    assert [url + 44] = 107;
    assert [url + 45] = 57;
    assert [url + 46] = 53;
    assert [url + 47] = 121;
    assert [url + 48] = 53;
    assert [url + 49] = 68;
    assert [url + 50] = 121;
    assert [url + 51] = 89;
    assert [url + 52] = 111;
    assert [url + 53] = 109;
    assert [url + 54] = 121;
    assert [url + 55] = 77;
    assert [url + 56] = 114;
    assert [url + 57] = 102;
    assert [url + 58] = 102;
    assert [url + 59] = 75;
    assert [url + 60] = 117;
    assert [url + 61] = 90;
    assert [url + 62] = 72;
    assert [url + 63] = 85;
    assert [url + 64] = 100;
    assert [url + 65] = 50;
    assert [url + 66] = 102;
    assert [url + 67] = 100;
    assert [url + 68] = 82;
    assert [url + 69] = 56;
    assert [url + 70] = 112;
    assert [url + 71] = 66;
    assert [url + 72] = 117;
    assert [url + 73] = 77;
    assert [url + 74] = 69;
    assert [url + 75] = 82;
    assert [url + 76] = 74;
    assert [url + 77] = 84;
    assert [url + 78] = 66;
    assert [url + 79] = 109;
    return (80, url);
}

@view
func token_id_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: Uint256
) {
    let (token_id_count) = _token_id_count.read();
    return (token_id_count,);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (tokenURI_len: felt, tokenURI: felt*) {
    let (tokenURI_len, tokenURI) = getUrl();
    return (tokenURI_len, tokenURI);
}

//
// Externals
//

@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    ERC721.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    ERC721.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ERC721._mint(to, tokenId);
    let (token_id_count) = _token_id_count.read();
    let (new_token_id, _) = uint256_add(token_id_count, Uint256(1, 0));
    _token_id_count.write(new_token_id);
    return ();
}

@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(tokenId: Uint256) {
    ERC721.assert_only_token_owner(tokenId);
    ERC721._burn(tokenId);
    return ();
}
