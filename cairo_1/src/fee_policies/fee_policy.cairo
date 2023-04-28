use array::ArrayTrait;
use starknet::ContractAddress;
use guildly::implementations::policy::TokenBalances;
use guildly::implementations::policy::TokenDetails;
use guildly::implementations::call::Call;

impl ArrayFeltCopy of Copy::<Array<felt252>>;

#[abi]
trait IFeePolicy {
    fn guild_burn(account: ContractAddress, guild: ContractAddress);
    fn get_tokens(call: Call) -> (
        Array<TokenDetails>,
        Array<TokenDetails>
    );
    fn check_owner_balances(calldata: Array<felt252>, owner_balances: Array<u256>) -> bool;
    fn get_balances() -> Array<TokenBalances>;
}