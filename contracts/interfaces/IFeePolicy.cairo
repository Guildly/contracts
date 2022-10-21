%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IFeePolicy {
    func initial_balance(to: felt, selector: felt) -> (
        pre_balances_len: felt, pre_balances: felt*
    ) {
    }
    func fee_distributions(
        to: felt,
        selector: felt,
        calldata_len: felt,
        calldata: felt*,
        pre_balances_len: felt,
        pre_balances: felt*,
        caller_split: felt,
        owner_split: felt
    ) -> (
        owner: felt,
        caller_amounts_len: felt,
        caller_amounts: Uint256*,
        owner_amounts_len: felt,
        owner_amounts: Uint256*,
        token_address: felt,
        token_ids_len: felt,
        token_ids: Uint256*,
        token_standard: felt
    ) {
    }
}
