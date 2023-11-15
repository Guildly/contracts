use array::ArrayTrait;
use starknet::{ContractAddress, ClassHash, contract_address_const};
use guildly::fee_policy_manager::fee_policy_manager::Token;
use guildly::guild::guild::guild::{Call, Permission};

#[starknet::interface]
trait IGuild<TContractState> {
    // initialize & upgrade ---------------------------------------------------
    fn initialize(
        ref self: TContractState,
        name: felt252,
        master: ContractAddress,
        guild_certificate: ContractAddress,
        fee_policy_manager: ContractAddress,
        proxy_admin: ContractAddress
    );
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
    // externals ---------------------------------------------------
    fn add_member(ref self: TContractState, account: ContractAddress, role: felt252);
    fn leave(ref self: TContractState);
    fn remove_member(ref self: TContractState, account: ContractAddress);
    fn force_transfer_item(ref self: TContractState, token: Token, account: ContractAddress);
    fn update_roles(ref self: TContractState, account: ContractAddress, roles: felt252);
    fn deposit(
        ref self: TContractState,
        token_standard: u8,
        token: ContractAddress,
        token_id: u256,
        amount: u256
    );
    fn withdraw(
        ref self: TContractState,
        token_standard: u8,
        token: ContractAddress,
        token_id: u256,
        amount: u256
    );
    fn execute(ref self: TContractState, calls: Array<Call>, nonce: felt252);
    fn initialize_permissions(ref self: TContractState, permissions: Array<Permission>);
    fn set_permissions(ref self: TContractState, permissions: Array<Permission>);
    fn set_fee_policy(
        ref self: TContractState,
        fee_policy: ContractAddress,
        caller_split: usize,
        owner_split: usize,
        admin_split: usize,
        payment_type: felt252,
        payment_details: Array<Token>
    );
    // view ------------------------------------------------------
    fn supports_interface(self: @TContractState, interfaceId: usize) -> bool;
    fn name(self: @TContractState) -> felt252;
    fn guild_certificate(self: @TContractState) -> ContractAddress;
    fn is_permissions_initialized(self: @TContractState) -> bool;
    fn get_nonce(self: @TContractState) -> felt252;
    fn has_role(self: @TContractState, role: felt252, account: ContractAddress) -> bool;
}
