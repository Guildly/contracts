use starknet::{ContractAddress, class_hash::ClassHash};

#[starknet::interface]
trait IGuildManager<TContractState> {
    fn initialize(
        ref self: TContractState,
        guild_class_hash: ClassHash,
        fee_policy_manager: ContractAddress,
        proxy_admin: ContractAddress
    );
    fn upgrade(ref self: TContractState, implementation: ClassHash);
    fn deploy_guild(
        ref self: TContractState, name: felt252, guild_certificate: ContractAddress
    ) -> ContractAddress;
    fn get_is_guild(self: @TContractState, address: ContractAddress) -> bool;
}
