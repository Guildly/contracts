%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IFeePolicy {
    func get_tokens(
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
    }
}
