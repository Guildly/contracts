#[cfg(test)]
mod tests {
    use snforge_std::cheatcodes::contract_class::ContractClassTrait;
use array::ArrayTrait;
    use result::ResultTrait;
    use option::OptionTrait;
    use traits::TryInto;
    use starknet::{
        ContractAddress, Felt252TryIntoContractAddress, contract_address_const
    };

    use snforge_std::{declare, start_prank, CheatTarget};

    use guildly::certificate::interfaces::{ICertificateDispatcher, ICertificateDispatcherTrait};
    use guildly::guild::guild::{
        constants::{Roles, TokenStandard},
        guild::{ Call, Permission },
        interfaces::{ IGuildDispatcher, IGuildDispatcherTrait }
    };
    use guildly::guild_manager::{
        GuildManager, 
        guild_manager::interfaces::{IGuildManagerDispatcher, IGuildManagerDispatcherTrait}
    };

    use openzeppelin::token::erc20::{
        ERC20Component,
        interface::{IERC20Dispatcher, IERC20DispatcherTrait}
    };

    fn PROXY_ADMIN() -> ContractAddress {
        contract_address_const::<0x1>()
    }

    fn CALLER() -> ContractAddress {
        contract_address_const::<0x2>()
    }

    fn ACCOUNT_2() -> ContractAddress {
        contract_address_const::<0x3>()
    }

    #[derive(Drop)]
    struct Contracts {
        guild_manager_address: ContractAddress,
        guild_address: ContractAddress,
        certificate_address: ContractAddress,
        eth_address: ContractAddress,
        nft_address: ContractAddress
    }

    fn deploy_contract(name: felt252) -> ContractAddress {
        let contract = declare(name);
        contract.deploy(@ArrayTrait::new()).unwrap()
    }

    fn setup() -> Contracts {
        let guild_contract = declare('Guild');
        let guild_manager_address = deploy_contract('GuildManager');
        let certificate_address = deploy_contract('Certificate');

        // Deploy mock ETH
        let eth_contract = declare('ERC20');
        let mut eth_calldata = ArrayTrait::<felt252>::new();
        eth_calldata.append('Eth');
        eth_calldata.append('ETH');
        eth_calldata.append(1000000000000000000);
        eth_calldata.append(0);
        eth_calldata.append(1);
        let eth_address = eth_contract.deploy(@eth_calldata).unwrap();

        // Deploy mock NFT
        let nft_contract = declare('ERC721');
        let mut nft_calldata = ArrayTrait::<felt252>::new();
        nft_calldata.append('NFT');
        nft_calldata.append('NFT');
        nft_calldata.append(1);
        nft_calldata.append(0);
        nft_calldata.append(0);
        let nft_address = nft_contract.deploy(@nft_calldata).unwrap();

        // Deploy & init Guild Manager
        let guild_manager_dispatcher = IGuildManagerDispatcher { contract_address: guild_manager_address };
        guild_manager_dispatcher.initialize(
            guild_contract.class_hash,
            PROXY_ADMIN()
        );

        // Deploy Guild
        let guild_address = guild_manager_dispatcher.deploy_guild('Guild', certificate_address);
        let guild_dispatcher = IGuildDispatcher { contract_address: guild_address };

        // start_prank(CheatTarget::One(guild_address), PROXY_ADMIN());

        // guild_dispatcher.add_member(CALLER(), Roles::MEMBER);
        // guild_dispatcher.add_member(ACCOUNT_2(), Roles::MEMBER);

        // Deploy & init Certificate
        let certificate_dispatcher = ICertificateDispatcher { contract_address: certificate_address };
        certificate_dispatcher.initialize(
            'Certificate',
            'GC',
            guild_manager_address,
            PROXY_ADMIN()
        );
        return Contracts { guild_manager_address, guild_address, certificate_address, eth_address, nft_address };
    }

    #[test]
    fn it_works() {
        let result = 2 + 2;
        assert(result == 4, 'result is not 4');
    }

    #[test]
    #[should_panic(expected: ('Call is not permitted', ))]
    fn set_permissions() {
        let contracts = setup();
        let guild_dispatcher = IGuildDispatcher { contract_address: contracts.guild_address };

        let mut permissions = ArrayTrait::<Permission>::new();
        permissions.append(Permission { to: contracts.certificate_address, selector: 1528802474226268325865027367859591458315299653151958663884057507666229546336 });

        println!("hello");

        start_prank(CheatTarget::One(contracts.guild_address), PROXY_ADMIN());
        guild_dispatcher.initialize_permissions(permissions);
        println!("hey");
        let calldata = ArrayTrait::<felt252>::new();
        let mut allowed_calls = ArrayTrait::<Call>::new();
        allowed_calls.append(Call { to: contracts.certificate_address, selector: 1528802474226268325865027367859591458315299653151958663884057507666229546336, calldata });
        guild_dispatcher.execute(allowed_calls, 0);

        println!("hi");

        let new_calldata = ArrayTrait::<felt252>::new();
        let mut banned_calls = ArrayTrait::<Call>::new();
        banned_calls.append(Call { to: contracts.certificate_address, selector: 944713526212149105522785400348068751682982210605126537021911324578866405028, calldata: new_calldata });
        guild_dispatcher.execute(banned_calls, 1);
    }

    #[test]
    fn add_members() {
        let contracts = setup();
        let guild_dispatcher = IGuildDispatcher { contract_address: contracts.guild_address };
        start_prank(CheatTarget::One(contracts.guild_address), PROXY_ADMIN());
        guild_dispatcher.add_member(ACCOUNT_2(), Roles::MEMBER);
    }

    // #[test]
    // fn deposit() {
    //     let contracts = setup();
    //     let guild_dispatcher = IGuildDispatcher { contract_address: contracts.guild_address };
    //     guild_dispatcher.deposit(TokenStandard::ERC20, contracts.eth_address, u256 { low: 0_u128, high: 0_u128 }, u256 { low: 1_u128, high: 0_u128 })
    // }
}