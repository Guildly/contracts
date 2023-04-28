use starknet::ContractAddress;

const INITIALIZE_SELECTOR: felt252 = 1295919550572838631247819983596733806859788957403169325509326258146877103642;

#[contract]
mod Manager {
    use array::SpanTrait;
    use array::ArrayTrait;
    use starknet::ClassHash;
    use starknet::ClassHashIntoFelt252;
    use starknet::ContractAddress;
    use starknet::ContractAddressIntoFelt252;
    use core::traits::TryInto;
    use core::traits::Into;
    use starknet::syscalls::deploy_syscall;
    use starknet::call_contract_syscall;
    use starknet::get_caller_address;

    use openzeppelin::upgrades::library::Proxy;

    use guildly::certificate::ICertificate;
    use guildly::math_utils::MathUtils;
    use guildly::constants::Roles;

    use super::INITIALIZE_SELECTOR;

    struct Storage {
        _salt: felt252,
        _proxy_class_hash: ClassHash,
        _guild_class_hash: ClassHash,
        _module_controller: ContractAddress,
        _fee_policy_manager: ContractAddress,
        _is_guild: LegacyMap<ContractAddress, bool>,
    }

    #[abi]
    trait IManager {
        fn get_is_guild(address: ContractAddress) -> bool;
    }

    //
    // Events
    //

    #[event]
    fn GuildDeploy(name: felt252, master: ContractAddress, contract_address: ContractAddress) {}

    //
    // Initialize & upgrade
    //

    #[external]
    fn initializer(
        proxy_class_hash: ClassHash,
        guild_class_hash: ClassHash,
        fee_policy_manager: ContractAddress,
        proxy_admin: ContractAddress
    ) {
        _proxy_class_hash::write(proxy_class_hash);
        _guild_class_hash::write(guild_class_hash);
        _fee_policy_manager::write(fee_policy_manager);
        // initialize proxy
        Proxy::initializer(proxy_admin)
    }

    #[external]
    fn upgrade(implementation: ContractAddress) {
        Proxy::assert_only_admin();
        Proxy::_set_implementation_hash(implementation)
    }

    #[external]
    fn deploy_guild(name: felt252, guild_certificate: ContractAddress) -> ContractAddress {
        let current_salt = _salt::read();
        let proxy_class_hash = _proxy_class_hash::read();
        let guild_class_hash = _guild_class_hash::read();
        let fee_policy_manager = _fee_policy_manager::read();
        let caller_address = get_caller_address();
        let proxy_admin = Proxy::get_admin();

        let mut deploy_calldata = ArrayTrait::new();
        deploy_calldata.append(guild_class_hash.into());
        let (contract_address, _) = deploy_syscall(
            proxy_class_hash, current_salt, deploy_calldata.span(), false, 
        ).unwrap_syscall();
        _salt::write(current_salt + 1);

        _is_guild::write(contract_address, true);

        GuildDeploy(name, caller_address, contract_address);

        let mut initialize_calldata = ArrayTrait::new();
        initialize_calldata.append(name);
        initialize_calldata.append(caller_address.into());
        initialize_calldata.append(guild_certificate.into());
        initialize_calldata.append(fee_policy_manager.into());
        initialize_calldata.append(proxy_admin);

        call_contract_syscall(contract_address, INITIALIZE_SELECTOR, initialize_calldata.span(), );

        return contract_address;
    }

    #[view]
    fn get_is_guild(address: ContractAddress) -> bool {
        _is_guild::read(address)
    }
}
