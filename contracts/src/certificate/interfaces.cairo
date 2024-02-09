use array::ArrayTrait;
use starknet::ContractAddress;

#[starknet::interface]
trait ICertificate<TContractState> {
    fn initialize(
        ref self: TContractState,
        name: felt252,
        symbol: felt252,
        guild_manager: ContractAddress,
        proxy_admin: ContractAddress
    );
    fn mint(ref self: TContractState, to: ContractAddress, guild: ContractAddress);
    fn burn(ref self: TContractState, account: ContractAddress, guild: ContractAddress);
    fn guild_burn(ref self: TContractState, account: ContractAddress, guild: ContractAddress);
    fn add_token_data(
        ref self: TContractState,
        certificate_id: u256,
        token_standard: u8,
        token: ContractAddress,
        token_id: u256,
        amount: u256
    );
    fn change_token_data(
        ref self: TContractState,
        certificate_id: u256,
        token_standard: u8,
        token: ContractAddress,
        token_id: u256,
        new_amount: u256
    );
    // VIEWS
    fn balance_of(self: @TContractState, owner: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, certificate_id: u256) -> ContractAddress;

    fn get_certificate_id(
        self: @TContractState, owner: ContractAddress, guild: ContractAddress
    ) -> u256;
    fn get_token_amount(
        self: @TContractState,
        certificate_id: u256,
        token_standard: u8,
        token: ContractAddress,
        token_id: u256
    ) -> u256;
    fn get_certificate_owner(self: @TContractState, certificate_id: u256) -> ContractAddress;
    fn get_token_owner(
        self: @TContractState, token_standard: u8, token: ContractAddress, token_id: u256
    ) -> ContractAddress;
    fn check_token_exists(
        self: @TContractState,
        certificate_id: u256,
        token_standard: u8,
        token: ContractAddress,
        token_id: u256
    ) -> bool;
    fn check_tokens_exist(self: @TContractState, certificate_id: u256) -> bool;
}
