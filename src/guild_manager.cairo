mod guild_manager;

#[starknet::contract]
mod GuildManager {
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent::InternalTrait;
use array::SpanTrait;
    use array::ArrayTrait;
    use core::traits::{TryInto, Into};
    use starknet::{
        ContractAddress, ContractAddressIntoFelt252, call_contract_syscall, get_caller_address,
        deploy_syscall, class_hash::ClassHash
    };
    use guildly::certificate::interfaces::ICertificate;
    // use guildly::guild::constants::Roles;
    use openzeppelin::upgrades::UpgradeableComponent;
    use guildly::utils::math_utils::MathUtils;
    use guildly::guild_manager::guild_manager::{INITIALIZE_SELECTOR, interfaces::IGuildManager};

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[storage]
    struct Storage {
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        _salt: felt252,
        _proxy_class_hash: ClassHash,
        _guild_class_hash: ClassHash,
        _module_controller: ContractAddress,
        _is_guild: LegacyMap<ContractAddress, bool>,
        _proxy_admin: ContractAddress
    }

    //
    // Events
    //

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        DeployedGuild: DeployedGuild, 
    }

    #[derive(Drop, starknet::Event)]
    struct DeployedGuild {
        name: felt252,
        master: ContractAddress,
        contract_address: ContractAddress
    }

    #[external(v0)]
    impl GuildManager of IGuildManager<ContractState> {
        //
        // Initialize & upgrade
        //
        fn initialize(
            ref self: ContractState,
            guild_class_hash: ClassHash,
            proxy_admin: ContractAddress
        ) {
            self._guild_class_hash.write(guild_class_hash);
            self._proxy_admin.write(proxy_admin)
        }
        fn upgrade(ref self: ContractState, implementation: ClassHash) {
            self.upgradeable._upgrade(implementation)
        }
        //
        // Externals
        //
        fn deploy_guild(
            ref self: ContractState, name: felt252, guild_certificate: ContractAddress
        ) -> ContractAddress {
            let current_salt = self._salt.read();
            let guild_class_hash = self._guild_class_hash.read();
            let caller_address = get_caller_address();

            let mut deploy_calldata = ArrayTrait::new();
            let (contract_address, _) = deploy_syscall(
                guild_class_hash, current_salt, deploy_calldata.span(), false, 
            ).unwrap();
            self._salt.write(current_salt + 1);

            self._is_guild.write(contract_address, true);

            self
                .emit(
                    Event::DeployedGuild(
                        DeployedGuild { name, master: caller_address, contract_address }
                    )
                );

            let mut initialize_calldata = ArrayTrait::new();
            initialize_calldata.append(name);
            initialize_calldata.append(caller_address.into());
            initialize_calldata.append(guild_certificate.into());
            initialize_calldata.append(caller_address.into());

            call_contract_syscall(
                contract_address, INITIALIZE_SELECTOR, initialize_calldata.span(), 
            );

            return contract_address;
        }
        fn get_is_guild(self: @ContractState, address: ContractAddress) -> bool {
            self._is_guild.read(address)
        }
    }
}
