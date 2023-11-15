#[cfg(test)]
mod tests {
    use array::ArrayTrait;
    use result::ResultTrait;
    use option::OptionTrait;
    use traits::TryInto;
    use starknet::{
        ContractAddress, Felt252TryIntoContractAddress, contract_address_const
    };

    use snforge_std::{declare, PreparedContract, deploy};

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
    use guildly::fee_policy_manager::interfaces::{IFeePolicyManagerDispatcher, IFeePolicyManagerDispatcherTrait};

    use openzeppelin::token::erc20::{
        ERC20,
        interface::{IERC20Dispatcher, IERC20DispatcherTrait}
    };

    fn PROXY_ADMIN() -> ContractAddress {
        contract_address_const::<1>()
    }

    fn CALLER() -> ContractAddress {
        contract_address_const::<0x1>()
    }

    fn ACCOUNT_2() -> ContractAddress {
        contract_address_const::<0x2>()
    }

    #[derive(Drop)]
    struct Contracts {
        guild_manager_address: ContractAddress,
        guild_address: ContractAddress,
        certificate_address: ContractAddress,
        fee_policy_manager_address: ContractAddress,
        // eth_address: ContractAddress,
        // nft_address: ContractAddress
    }

    fn deploy_contract(name: felt252) -> ContractAddress {
        let class_hash = declare(name);
        let prepared = PreparedContract {
            class_hash, constructor_calldata: @ArrayTrait::new()
        };
        deploy(prepared).unwrap()
    }

    fn setup() -> Contracts {
        let guild_class_hash = declare('Guild');
        let guild_manager_address = deploy_contract('GuildManager');
        let fee_policy_manager_address = deploy_contract('FeePolicyManager');
        let certificate_address = deploy_contract('Certificate');

        // Deploy mock ETH
        let eth_class_hash = declare('ERC20');
        let mut eth_calldata = ArrayTrait::<felt252>::new();
        eth_calldata.append('Eth');
        eth_calldata.append('ETH');
        eth_calldata.append(1000000000000000000);
        eth_calldata.append(1);
        let eth_prepared = PreparedContract {
            class_hash: eth_class_hash, constructor_calldata: @eth_calldata
        };
        eth_calldata.print();
        // let eth_address = deploy(eth_prepared).unwrap();

        // Deploy mock NFT
        // let nft_class_hash = declare('ERC721');
        // let mut nft_calldata = ArrayTrait::<felt252>::new();
        // nft_calldata.append('NFT');
        // nft_calldata.append('NFT');
        // nft_calldata.append(1);
        // nft_calldata.append(1);
        // let nft_prepared = PreparedContract {
        //     class_hash: nft_class_hash, constructor_calldata: @nft_calldata
        // };
        // let nft_address = deploy(nft_prepared).unwrap();

        // Deploy & init Guild Manager
        let guild_manager_dispatcher = IGuildManagerDispatcher { contract_address: guild_manager_address };
        guild_manager_dispatcher.initialize(
            guild_class_hash,
            fee_policy_manager_address,
            PROXY_ADMIN()
        );

        // Deploy Guild
        let guild_address = guild_manager_dispatcher.deploy_guild('Guild', certificate_address);
        let guild_dispatcher = IGuildDispatcher { contract_address: guild_address };

        // Deploy & init Fee Policy Manager
        let fee_policy_manager_dispatcher = IFeePolicyManagerDispatcher { contract_address: fee_policy_manager_address };
        fee_policy_manager_dispatcher.initialize(
            PROXY_ADMIN()
        );

        // Deploy & init Certificate
        let certificate_dispatcher = ICertificateDispatcher { contract_address: certificate_address };
        certificate_dispatcher.initialize(
            'Certificate',
            'GC',
            guild_manager_address,
            PROXY_ADMIN()
        );
        return Contracts { guild_manager_address, guild_address, certificate_address, fee_policy_manager_address };
    }

    #[test]
    fn it_works() {
        let result = 2 + 2;
        assert(result == 4, 'result is not 4');
    }

    // #[test]
    // #[should_panic(expected: ('Call is not permitted', ))]
    // fn set_permissions() {
    //     let contracts = setup();
    //     let guild_dispatcher = IGuildDispatcher { contract_address: contracts.guild_address };

    //     let mut permissions = ArrayTrait::<Permission>::new();
    //     permissions.append(Permission { to: contracts.certificate_address, selector: 1528802474226268325865027367859591458315299653151958663884057507666229546336 });

    //     guild_dispatcher.initialize_permissions(permissions);
    //     let calldata = ArrayTrait::<felt252>::new();
    //     let mut allowed_calls = ArrayTrait::<Call>::new();
    //     allowed_calls.append(Call { to: contracts.certificate_address, selector: 1528802474226268325865027367859591458315299653151958663884057507666229546336, calldata });
    //     guild_dispatcher.execute(allowed_calls, 0);

    //     let new_calldata = ArrayTrait::<felt252>::new();
    //     let mut banned_calls = ArrayTrait::<Call>::new();
    //     banned_calls.append(Call { to: contracts.certificate_address, selector: 944713526212149105522785400348068751682982210605126537021911324578866405028, calldata: new_calldata });
    //     guild_dispatcher.execute(banned_calls, 0);
    // }

    #[test]
    fn add_members() {
        let contracts = setup();
        // let guild_dispatcher = IGuildDispatcher { contract_address: contracts.guild_address };

        // guild_dispatcher.add_member(ACCOUNT_2(), Roles::ADMIN);
    }

    // #[test]
    // fn deposit() {
    //     let contracts = setup();
    //     let guild_dispatcher = IGuildDispatcher { contract_address: contracts.guild_address };
    //     // let eth_dispatcher = IERC20Dispatcher { contract_address: contracts.eth_address };

    //     // guild_dispatcher.deposit(1, contracts.eth_address, )
    // }
}