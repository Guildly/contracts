mod interfaces;

#[starknet::contract]
mod Certificate {
    use zeroable::Zeroable;
    use starknet::{
        ContractAddress, contract_address::ContractAddressZeroable, get_caller_address,
        get_contract_address, class_hash::ClassHash
    };
    use array::SpanTrait;
    use array::ArrayTrait;
    use openzeppelin::token::erc721::erc721::ERC721;
    use openzeppelin::upgrades::upgradeable::Upgradeable;
    // use introspection::erc165::ERC165;

    use guildly::guild_manager::guild_manager::{
        interfaces::{IGuildManagerDispatcher, IGuildManagerDispatcherTrait}
    };

    #[storage]
    struct Storage {
        _guild_manager: ContractAddress,
        _certificate_id_count: u256,
        _certificate_id: LegacyMap<(ContractAddress, ContractAddress), u256>,
        _certificate_owner: LegacyMap<u256, ContractAddress>,
        _guild: LegacyMap<u256, ContractAddress>,
        _token_owner: LegacyMap<(felt252, ContractAddress, u256), u256>,
        _certificate_token_amount: LegacyMap<(u256, felt252, ContractAddress, u256), u256>,
        _certificate_tokens_len: LegacyMap<u256, u32>,
        _proxy_admin: ContractAddress
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        MintCertificate: MintCertificate,
        BurnCertificate: BurnCertificate,
    }

    #[external(v0)]
    fn supportsInterface(self: @ContractState, interfaceId: felt252) -> felt252 {
        // ERC165::supports_interface(interfaceId)
        1
    }

    #[external(v0)]
    fn name(self: @ContractState) -> felt252 {
        let mut erc721_state = ERC721::unsafe_new_contract_state();
        ERC721::ERC721MetadataImpl::name(@erc721_state)
    }

    #[external(v0)]
    fn symbol(self: @ContractState) -> felt252 {
        let mut erc721_state = ERC721::unsafe_new_contract_state();
        ERC721::ERC721MetadataImpl::symbol(@erc721_state)
    }

    #[external(v0)]
    fn balance_of(self: @ContractState, owner: ContractAddress) -> u256 {
        let mut erc721_state = ERC721::unsafe_new_contract_state();
        ERC721::ERC721Impl::balance_of(@erc721_state, owner)
    }

    #[external(v0)]
    fn owner_of(self: @ContractState, tokenId: u256) -> ContractAddress {
        let mut erc721_state = ERC721::unsafe_new_contract_state();
        ERC721::ERC721Impl::owner_of(@erc721_state, tokenId)
    }

    #[external(v0)]
    fn getUrl(self: @ContractState) -> Array<felt252> {
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

    #[external(v0)]
    fn tokenURI(self: @ContractState, tokenId: u256) -> Array<felt252> {
        getUrl(self)
    }

    #[external(v0)]
    fn get_certificate_id(
        self: @ContractState, owner: ContractAddress, guild: ContractAddress
    ) -> u256 {
        self._certificate_id.read((owner, guild))
    }

    #[external(v0)]
    fn get_certificate_owner(self: @ContractState, certificate_id: u256) -> ContractAddress {
        self._certificate_owner.read(certificate_id)
    }

    #[external(v0)]
    fn get_token_amount(
        self: @ContractState,
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        token_id: u256
    ) -> u256 {
        self._certificate_token_amount.read((certificate_id, token_standard, token, token_id))
    }

    #[external(v0)]
    fn get_token_owner(
        self: @ContractState, token_standard: felt252, token: ContractAddress, token_id: u256
    ) -> ContractAddress {
        let owner_certificate = self._token_owner.read((token_standard, token, token_id));
        self._certificate_owner.read(owner_certificate)
    }

    #[external(v0)]
    fn initialize(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        guild_manager: ContractAddress,
        proxy_admin: ContractAddress
    ) {
        let mut erc721_state = ERC721::unsafe_new_contract_state();
        ERC721::InternalImpl::initializer(ref erc721_state, name, symbol);
        self._guild_manager.write(guild_manager);
        self._proxy_admin.write(proxy_admin);
    }

    #[external(v0)]
    fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
        let mut upgradable_state = Upgradeable::unsafe_new_contract_state();
        Upgradeable::InternalImpl::_upgrade(ref upgradable_state, new_class_hash)
    }

    #[external(v0)]
    fn setTokenURI(ref self: ContractState, tokenId: u256, tokenURI: felt252) {
        _assert_only_guild(@self);
        let mut erc721_state = ERC721::unsafe_new_contract_state();
        ERC721::InternalImpl::_set_token_uri(ref erc721_state, tokenId, tokenURI)
    }

    #[external(v0)]
    fn mint(ref self: ContractState, to: ContractAddress, guild: ContractAddress) {
        let certificate_count = self._certificate_id_count.read();
        let new_certificate_id = certificate_count + u256 { low: 1_u128, high: 0_u128 };
        self._certificate_id_count.write(new_certificate_id);

        self._certificate_id.write((to, guild), new_certificate_id);
        self._certificate_owner.write(new_certificate_id, to);
        self._guild.write(new_certificate_id, guild);
        let mut erc721_state = ERC721::unsafe_new_contract_state();
        ERC721::InternalImpl::_mint(ref erc721_state, to, new_certificate_id);

        __event__MintCertificate(ref self, to, guild, new_certificate_id)
    }

    #[external(v0)]
    fn burn(ref self: ContractState, account: ContractAddress, guild: ContractAddress) {
        let certificate_id = self._certificate_id.read((account, guild));
        let mut erc721_state = ERC721::unsafe_new_contract_state();
        ERC721::InternalImpl::_owner_of(@erc721_state, certificate_id);
        self._guild.write(certificate_id, ContractAddressZeroable::zero());
        let mut erc721_state = ERC721::unsafe_new_contract_state();
        ERC721::InternalImpl::_burn(ref erc721_state, certificate_id);
        __event__BurnCertificate(ref self, account, guild, certificate_id)
    }

    #[external(v0)]
    fn guild_burn(ref self: ContractState, account: ContractAddress, guild: ContractAddress) {
        _assert_only_guild(@self);
        let certificate_id = self._certificate_id.read((account, guild));
        self._guild.write(certificate_id, ContractAddressZeroable::zero());
        let mut erc721_state = ERC721::unsafe_new_contract_state();
        ERC721::InternalImpl::_burn(ref erc721_state, certificate_id);
        __event__BurnCertificate(ref self, account, guild, certificate_id)
    }

    #[external(v0)]
    fn add_token_data(
        ref self: ContractState,
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        token_id: u256,
        amount: u256
    ) {
        _assert_only_guild(@self);
        self
            ._certificate_token_amount
            .write((certificate_id, token_standard, token, token_id), amount);
        let tokens_len = self._certificate_tokens_len.read(certificate_id);
        self._token_owner.write((token_standard, token, token_id), certificate_id);
        self._certificate_tokens_len.write(certificate_id, tokens_len + 1)
    }

    #[external(v0)]
    fn change_token_data(
        ref self: ContractState,
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        token_id: u256,
        new_amount: u256
    ) {
        _assert_only_guild(@self);
        let tokens_len = self._certificate_tokens_len.read(certificate_id);
        if (new_amount == u256 { low: 0_u128, high: 0_u128 }) {
            self._certificate_tokens_len.write(certificate_id, tokens_len - 1_u32);
            self
                ._token_owner
                .write((token_standard, token, token_id), u256 { low: 0_u128, high: 0_u128 });
        }
        self
            ._certificate_token_amount
            .write((certificate_id, token_standard, token, token_id), new_amount)
    }

    #[external(v0)]
    fn check_token_exists(
        self: @ContractState,
        certificate_id: u256,
        token_standard: felt252,
        token: ContractAddress,
        token_id: u256
    ) -> bool {
        _assert_only_guild(self);
        let amount = self
            ._certificate_token_amount
            .read((certificate_id, token_standard, token, token_id));
        amount > u256 { low: 0_u128, high: 0_u128 }
    }

    #[external(v0)]
    fn check_tokens_exist(ref self: ContractState, certificate_id: u256) -> bool {
        let tokens_len = self._certificate_tokens_len.read(certificate_id);
        tokens_len > 0_u32
    }

    fn _assert_only_guild(self: @ContractState) {
        let caller = get_caller_address();
        let guild_manager = self._guild_manager.read();
        let check_guild = IGuildManagerDispatcher {
            contract_address: guild_manager
        }.get_is_guild(caller);
        assert(check_guild, 'Guild is not valid')
    }

    #[derive(Drop, starknet::Event)]
    struct MintCertificate {
        account: ContractAddress,
        guild: ContractAddress,
        id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct BurnCertificate {
        account: ContractAddress,
        guild: ContractAddress,
        id: u256
    }

    fn __event__MintCertificate(
        ref self: ContractState, account: ContractAddress, guild: ContractAddress, id: u256
    ) {
        self.emit(Event::MintCertificate(MintCertificate { account, guild, id }));
    }

    fn __event__BurnCertificate(
        ref self: ContractState, account: ContractAddress, guild: ContractAddress, id: u256
    ) {
        self.emit(Event::BurnCertificate(BurnCertificate { account, guild, id }));
    }
}
