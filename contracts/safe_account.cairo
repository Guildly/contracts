// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.4.0b (account/presets/Account.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_tx_info

from openzeppelin.account.library import Account, AccountCallArray
from openzeppelin.introspection.erc165.library import ERC165

const IACCOUNT_ID = 0xf10dbd44;
const IERC1155_RECEIVER_ID = 0x4e2312e0;
//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    publicKey: felt
) {
    Account.initializer(publicKey);
    ERC165.register_interface(IACCOUNT_ID);
    ERC165.register_interface(IERC1155_RECEIVER_ID);
    return ();
}

//
// Getters
//

@view
func getPublicKey{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    publicKey: felt
) {
    let (publicKey: felt) = Account.get_public_key();
    return (publicKey=publicKey);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return Account.supports_interface(interfaceId);
}

//
// Setters
//

@external
func setPublicKey{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newPublicKey: felt
) {
    Account.set_public_key(newPublicKey);
    return ();
}

//
// Business logic
//

@view
func isValidSignature{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr
}(hash: felt, signature_len: felt, signature: felt*) -> (isValid: felt) {
    let (isValid: felt) = Account.is_valid_signature(hash, signature_len, signature);
    return (isValid=isValid);
}

@external
func __validate__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr
}(call_array_len: felt, call_array: AccountCallArray*, calldata_len: felt, calldata: felt*) {
    let (tx_info) = get_tx_info();
    Account.is_valid_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature);
    return ();
}

@external
func __validate_declare__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr
}(class_hash: felt) {
    let (tx_info) = get_tx_info();
    Account.is_valid_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature);
    return ();
}

@external
func __execute__{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr,
}(call_array_len: felt, call_array: AccountCallArray*, calldata_len: felt, calldata: felt*) -> (
    response_len: felt, response: felt*
) {
    let (response_len, response) = Account.execute(
        call_array_len, call_array, calldata_len, calldata
    );
    return (response_len, response);
}