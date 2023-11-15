use array::ArrayTrait;
use starknet::ContractAddress;
use guildly::guild::guild::guild::Call;
use guildly::fee_policy::fee_policy::fee_policy::{TokenDetails, TokenBalances, TokenDifferences};

#[starknet::interface]
trait IFeePolicy<TContractState> {
    fn get_tokens(
        self: @TContractState, to: ContractAddress, selector: felt252, calldata: Array<felt252>
    ) -> (Array<TokenDetails>, Array<TokenDetails>);
    fn check_owner_balances(
        self: @TContractState, feedata: Span<felt252>, owner_balances: Array<u256>
    ) -> bool;
    fn get_balances(self: @TContractState) -> Array<TokenBalances>;
}
