%lang starknet

@view 
func get_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    calldata_len: felt, calldata: felt*
) -> (
    used_token: felt,
    used_token_id: Uint256,
    used_token_standard: felt,
    accrued_token: felt,
    accrued_token_ids_len: felt,
    accrued_token_ids: Uint256*,
    accrued_token_standard: felt,
) {
    let (caller) = get_caller_address();
    let (planet_id) = IERC721.ownerToPlanet(erc721_address, caller);
    return (
        planet_address,
        planet_id,
        1,

}
