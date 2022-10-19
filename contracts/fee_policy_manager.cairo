%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin


@storage_var
func fee_policy(contract_address: felt, selector: felt) -> (res: felt) {
}

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt
) {

}

@view
func get_fee_policy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_address: felt, selector: felt
) -> (caller_split: felt, owner_split: felt, guild_split: felt) {

}

@external
func set_fee_policy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_address: felt, selector: felt, caller_split: felt, owner_split: felt, guild_split: felt, policy_address: felt
) {
    
}

func execute_with_policy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_address: felt, function_selector: felt, calldata_size: felt, calldata: felt
) {

    let (tx_info) = get_tx_info();

    let (caller) = tx_info.caller_address;

    let (reward_tokens_len: felt, reward_tokens: felt*, caller_split: felt, owner_split: felt, guild_split: felt) = loop_check_fee_structure(contract_address, function_selector);

    // Initial balances
    let (balances_len: felt, balances: felt*) = loop_check_balance(reward_tokens_len, reward_tokens);

    // Actually execute it
    let res = call_contract(
        contract_address=this_call.to,
        function_selector=this_call.selector,
        calldata_size=this_call.calldata_len,
        calldata=this_call.calldata,
    );

    // after balance
    let (balances_len: felt, balances: felt*) = loop_check_balance(reward_tokens_len, reward_tokens);


}