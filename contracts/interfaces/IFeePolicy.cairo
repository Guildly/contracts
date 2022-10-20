%lang starknet

@contract_interface
namespace IFeePolicy {
    func initial_balance(to: felt, selector: felt) -> (
        pre_balance_len: felt, pre_balance: felt*
    ) {
    }
    func final_balance(to: felt, selector: felt, calldata_len: felt, calldata: felt*) -> (
        post_balance_len: felt, post_balance: felt*
    ) {
    }
}
