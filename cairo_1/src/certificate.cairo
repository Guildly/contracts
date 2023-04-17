use array::ArrayTrait;
use starknet::ContractAddress;
//
// Structs
//
#[derive(Serde)]
struct Token {
    token_standard: felt252,
    token: ContractAddress,
    token_id: u256,
    amount: u256,
}

#[abi]
trait ICertificate {
    fn balance_of(owner: ContractAddress) -> u256;
    fn owner_of(certificate_id: u256) -> ContractAddress;

    fn get_certificate_id(owner: ContractAddress, guild: ContractAddress) -> u256;
    fn get_token_amount(
        certificate_id: u256, token_standard: felt252, token: ContractAddress, token_id: u256
    ) -> u256;
    fn get_certificate_owner(certificate_id: u256) -> ContractAddress;
    fn get_token_owner(
        token_standard: felt252, token: ContractAddress, token_id: u256
    ) -> ContractAddress;
    fn check_token_exists(
        certificate_id: u256, token_standard: felt252, token: ContractAddress, token_id: u256
    ) -> bool;
    fn check_tokens_exist(certificate_id: u256) -> bool;
    fn mint(to: ContractAddress, guild: ContractAddress);
    fn burn(account: ContractAddress, guild: ContractAddress);
    fn guild_burn(account: ContractAddress, guild: ContractAddress);
    fn add_token_data(
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        token_id: u256,
        amount: u256
    );
    fn change_token_data(
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        token_id: u256,
        new_amount: u256
    );
}

#[contract]
mod Certificate {
    use zeroable::Zeroable;
    use starknet::ContractAddress;
    use array::SpanTrait;
    use array::ArrayTrait;
    use openzeppelin::token::erc721::ERC721;
    use openzeppelin::upgrades::Proxy;
    use openzeppelin::Ownable;
    use openzeppelin::introspection::erc165::ERC165;

    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::contract_address::ContractAddressPartialEq;
    use starknet::contract_address::ContractAddressZeroable;

    use guild_contracts::math_utils::MathUtils;
    use guild_contracts::helpers::Helpers;

    use super::Token;
    //
    // Events
    //

    #[event]
    fn MintCertificate(account: ContractAddress, guild: ContractAddress, id: u256) {}

    #[event]
    fn BurnCertificate(account: ContractAddress, guild: ContractAddress, id: u256) {}

    //
    // Storage variables
    //

    struct Storage {
        _guild_manager: ContractAddress,
        _certificate_id_count: u256,
        _certificate_id: LegacyMap<(ContractAddress, ContractAddress), u256>,
        _certificate_owner: LegacyMap<u256, ContractAddress>,
        _guild: LegacyMap<u256, ContractAddress>,
        _token_owner: LegacyMap<(felt252, ContractAddress, u256), u256>,
        _certificate_token_amount: LegacyMap<(u256, felt252, ContractAddress, u256), u256>,
        _certificate_tokens_len: LegacyMap<u256, u32>,
    }


    #[abi]
    trait IManager {
        fn get_is_guild(address: ContractAddress) -> bool;
    }

    //
    // Guards
    //

    #[internal]
    fn assert_only_guild() {
        let caller = get_caller_address();
        let guild_manager = _guild_manager::read();
        let check_guild = IManagerDispatcher { contract_address: guild_manager }.get_is_guild(caller);
        assert(check_guild, 'Guild is not valid')
    }

    //
    // Getters
    //

    #[view]
    fn supportsInterface(interfaceId: felt252) -> felt252 {
        ERC165::supports_interface(interfaceId)
    }

    #[view]
    fn name() -> felt252 {
        ERC721::name()
    }

    #[view]
    fn symbol() -> felt252 {
        ERC721::symbol()
    }

    #[view]
    fn balance_of(owner: felt252) -> u256 {
        ERC721::balance_of(owner)
    }

    #[view]
    fn owner_of(tokenId: u256) -> ContractAddress {
        ERC721::owner_of(tokenId)
    }

    #[view]
    fn getUrl() -> Array<felt252> {
        let mut url = ArrayTrait::new();
        url.append(104);
        url.append(116);
        url.append(116);
        url.append(112);
        url.append(115);
        url.append(58);
        url.append(47);
        url.append(47);
        url.append(103);
        url.append(97);
        url.append(116);
        url.append(101);
        url.append(119);
        url.append(97);
        url.append(121);
        url.append(46);
        url.append(112);
        url.append(105);
        url.append(110);
        url.append(97);
        url.append(116);
        url.append(97);
        url.append(46);
        url.append(99);
        url.append(108);
        url.append(111);
        url.append(117);
        url.append(100);
        url.append(47);
        url.append(105);
        url.append(112);
        url.append(102);
        url.append(115);
        url.append(47);
        url.append(81);
        url.append(109);
        url.append(85);
        url.append(110);
        url.append(52);
        url.append(66);
        url.append(90);
        url.append(116);
        url.append(122);
        url.append(52);
        url.append(116);
        url.append(119);
        url.append(51);
        url.append(114);
        url.append(122);
        url.append(112);
        url.append(90);
        url.append(72);
        url.append(112);
        url.append(84);
        url.append(50);
        url.append(111);
        url.append(69);
        url.append(111);
        url.append(54);
        url.append(103);
        url.append(117);
        url.append(119);
        url.append(50);
        url.append(70);
        url.append(120);
        url.append(115);
        url.append(105);
        url.append(80);
        url.append(69);
        url.append(121);
        url.append(118);
        url.append(102);
        url.append(82);
        url.append(70);
        url.append(110);
        url.append(85);
        url.append(74);
        url.append(87);
        url.append(122);
        url.append(90);
        return url;
    }

    #[view]
    fn tokenURI(tokenId: u256) -> Array<felt252> {
        getUrl()
    }

    #[view]
    fn get_certificate_id(owner: ContractAddress, guild: ContractAddress) -> u256 {
        _certificate_id::read((owner, guild))
    }

    #[view]
    fn get_certificate_owner(certificate_id: u256) -> ContractAddress {
        _certificate_owner::read(certificate_id)
    }

    #[view]
    fn get_token_amount(
        certificate_id: u256, token_standard: felt252, token: ContractAddress, token_id: u256
    ) -> u256 {
        _certificate_token_amount::read((certificate_id, token_standard, token, token_id))
    }

    #[view]
    fn get_token_owner(
        token_standard: felt252, token: ContractAddress, token_id: u256
    ) -> ContractAddress {
        let owner_certificate = _token_owner::read((token_standard, token, token_id));
        _certificate_owner::read(owner_certificate)
    }

    //
    // Initialize & upgrade
    //

    #[external]
    fn initializer(
        name: felt252, symbol: felt252, guild_manager: ContractAddress, proxy_admin: ContractAddress
    ) {
        ERC721::initializer(name, symbol);
        _guild_manager::write(guild_manager);
        Proxy::initializer(proxy_admin)
    }

    #[external]
    fn upgrade(implementation: ContractAddress) {
        Proxy::assert_only_admin();
        Proxy::_set_implementation_hash(implementation)
    }

    //
    // External
    //

    #[external]
    fn setTokenURI(tokenId: u256, tokenURI: felt252) {
        assert_only_guild();
        ERC721::_set_token_uri(tokenId, tokenURI)
    }

    #[external]
    fn transfer_ownership(new_owner: ContractAddress) {
        Ownable::transfer_ownership(new_owner)
    }

    #[external]
    fn mint(to: ContractAddress, guild: ContractAddress) {
        let certificate_count = _certificate_id_count::read();
        let new_certificate_id = certificate_count + u256 { low: 1_u128, high: 0_u128 };
        _certificate_id_count::write(new_certificate_id);

        _certificate_id::write((to, guild), new_certificate_id);
        _certificate_owner::write(new_certificate_id, to);
        _guild::write(new_certificate_id, guild);

        ERC721::_mint(to, new_certificate_id);

        MintCertificate(to, guild, new_certificate_id)
    }

    #[external]
    fn burn(account: ContractAddress, guild: ContractAddress) {
        let certificate_id = _certificate_id::read((account, guild));
        ERC721::assert_only_token_owner(certificate_id);
        _guild::write(certificate_id, ContractAddressZeroable::zero());
        ERC721::_burn(certificate_id);
        BurnCertificate(account, guild, certificate_id)
    }

    #[external]
    fn guild_burn(account: ContractAddress, guild: ContractAddress) {
        assert_only_guild();
        let certificate_id = _certificate_id::read((account, guild));
        _guild::write(certificate_id, ContractAddressZeroable::zero());
        ERC721::_burn(certificate_id);
        BurnCertificate(account, guild, certificate_id)
    }

    #[external]
    fn add_token_data(
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        token_id: u256,
        amount: u256
    ) {
        assert_only_guild();
        _certificate_token_amount::write((certificate_id, token_standard, token, token_id), amount);
        let tokens_len = _certificate_tokens_len::read(certificate_id);
        _token_owner::write((token_standard, token, token_id), certificate_id);
        _certificate_tokens_len::write(certificate_id, tokens_len + 1)
    }

    #[external]
    fn change_token_data(
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        token_id: u256,
        new_amount: u256
    ) {
        assert_only_guild();
        let tokens_len = _certificate_tokens_len::read(certificate_id);
        if (new_amount == u256 { low: 0_u128, high: 0_u128 }) {
            _certificate_tokens_len::write(certificate_id, tokens_len - 1_u32);
            _token_owner::write((token_standard, token, token_id), u256 { low: 0_u128, high: 0_u128 });
        }
        _certificate_token_amount::write(
            (certificate_id, token_standard, token, token_id), new_amount
        )
    }

    #[view]
    fn check_token_exists(
        certificate_id: u256, token_standard: felt252, token: ContractAddress, token_id: u256
    ) -> bool {
        assert_only_guild();
        let amount = _certificate_token_amount::read(
            (certificate_id, token_standard, token, token_id)
        );
        amount > u256 { low: 0_u128, high: 0_u128 }
    }

    #[view]
    fn check_tokens_exist(certificate_id: u256) -> bool {
        let tokens_len = _certificate_tokens_len::read(certificate_id);
        tokens_len > 0_u32
    }
}
