%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from contracts.fee_policies.realms.library import get_resources

@storage_var
func resources_contract() -> (address: felt) {
}

@storage_var
func realms_contract() -> (res: felt) {
}

const RESOURCES_LENGTH = 22;


@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    resources_address: felt,
    realms_address: felt,
) {
    resources_contract.write(resources_address);
    realms_contract.write(realms_address);
    return ();
}

// BUILDING

@view
func get_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, selector: felt, calldata_len: felt, calldata: felt*
) -> (
    used_token: felt,
    used_token_id: Uint256,
    used_token_standard: felt,
    accrued_token: felt,
    accrued_token_ids_len: felt,
    accrued_token_ids: Uint256*,
    accrued_token_standard: felt,
) {
    let realm_id_low = calldata[0];
    let realm_id_high = calldata[1];
    let realm_id = Uint256(
        realm_id_low,
        realm_id_high
    );
    let (realms_address) = realms_contract.read();
    let (resources_address) = resources_contract.read();
    let (token_ids: Uint256*) = get_resources();

    return (
        realms_address,
        realm_id,
        1,
        resources_address,
        RESOURCES_LENGTH,
        token_ids,
        2
    );
}
