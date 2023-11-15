use array::ArrayTrait;
use starknet::{ContractAddress, class_hash::ClassHash};
use guildly::fee_policy_manager::fee_policy_manager::{Token, PolicyTarget};

// #[starknet::interface]
// trait IFeePolicyManager {
//     fn has_fee_policy(guild: ContractAddress, fee_policy: ContractAddress) -> bool; 
//     fn get_fee_policy(guild: ContractAddress, to: ContractAddress, selector: felt252) -> ContractAddress;
//     fn get_policy_target(fee_policy: ContractAddress) -> PolicyTarget;
//     fn get_policy_distribution(guild: ContractAddress, fee_policy: ContractAddress) -> (usize, usize, usize);
//     fn get_direct_payments(guild: ContractAddress, fee_policy: ContractAddress) -> Array<Token>;
//     fn add_policy(policy: ContractAddress, to: ContractAddress, selector: felt252);
//     fn set_fee_policy(
//         policy_address: ContractAddress, 
//         caller_split: usize, 
//         owner_split: usize, 
//         admin_split: usize,
//         payment_details: Array<Token>
//     );
//     fn revoke_policy(policy_address: ContractAddress);
// }

#[starknet::interface]
trait IFeePolicyManager<TContractState> {
    // initialize & upgrade ---------------------------------------------------
    fn initialize(ref self: TContractState, proxy_admin: ContractAddress);
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
    // externals
    fn add_policy(
        ref self: TContractState, policy: ContractAddress, to: ContractAddress, selector: felt252
    );
    fn set_fee_policy(
        ref self: TContractState,
        policy_address: ContractAddress,
        caller_split: usize,
        owner_split: usize,
        admin_split: usize,
        payment_details: Array<Token>
    );
    fn revoke_policy(ref self: TContractState, policy_address: ContractAddress);
    // view ------------------------------------------------------
    fn get_fee_policy(
        self: @TContractState,
        guild_address: ContractAddress,
        to: ContractAddress,
        selector: felt252
    ) -> ContractAddress;
    fn get_policy_target(self: @TContractState, policy: ContractAddress) -> PolicyTarget;
    fn get_policy_distribution(
        self: @TContractState, guild_address: ContractAddress, fee_policy: ContractAddress
    ) -> (usize, usize, usize);
    fn get_direct_payments(
        self: @TContractState, guild_address: ContractAddress, fee_policy: ContractAddress
    ) -> Array<Token>;
}
