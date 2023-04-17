use starknet::ContractAddress;

#[abi]
trait IFeePolicy {
    fn guild_burn(account: ContractAddress, guild: ContractAddress);
}