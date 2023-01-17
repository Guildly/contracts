%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.fee_policies.library import TokenArray, TokenBalancesArray

@contract_interface
namespace IFeePolicy {
    func get_tokens(
        to: felt, selector: felt, calldata_len: felt, calldata: felt*
    ) -> (
        used_token_array_len: felt,
        used_token_array: TokenArray*,
        used_token_ids_len: felt,
        used_token_ids: Uint256*,
        token_array_len: felt,
        token_array: TokenArray*,
        token_ids_len: felt,
        token_ids: Uint256*
    ) {
    }
    func get_balances() -> (
        token_balances_len: felt, 
        token_balances: TokenBalancesArray*,
        balances_len: felt,
        balances: Uint256*
    ) {
    }
    func check_owner_balances(
        calldata_len: felt, calldata: felt*, owner_balances_len: felt, owner_balances: Uint256*
    ) -> (bool: felt) {
    }
    func execute_payment_plan(
        pre_balances_len: felt, 
        pre_balances: Uint256*, 
        post_balances_len: felt, 
        post_balances: Uint256*
    ) -> (final_balances_len: felt, final_balances: Uint256*) {
    }
}
