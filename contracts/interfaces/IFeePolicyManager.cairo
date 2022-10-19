%lang starknet

@contract_interface
namespace IFeePolicyManager {
    func get_fee_policy(address: felt, selector: felt) -> (value: felt) {
    }

    func execute_with_policy(address: felt, selector: felt, calldata_len: felt, calldata: felt*) -> (res: felt) {
    }
}