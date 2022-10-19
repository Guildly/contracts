%lang starknet


@storage_var
func fee_structure(contract_address: felt, selector: felt) -> (res: felt) {
}


@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt
)

@view
func get_fee_structure{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_address: felt, selector: felt
) -> (caller_split: felt, owner_split: felt, guild_split: felt) {

}

@external
func set_fee_structure{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_address: felt, selector: felt, caller_split: felt, owner_split: felt, guild_split: felt
) {

}