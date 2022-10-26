%lang starknet

from tests.protostar.setup.interfaces import Controller, GuildManager, Certificate, PolicyManager

from contracts.utils.guild_structs import ModuleIds

struct Contracts {
    account1: felt,
    account2: felt,
    account3: felt,
    controller: felt,
    guild: felt,
    guild_manager: felt,
    certificate: felt,
    policy_manager: felt,
    guild: felt,
}

const PK1 = 11111;
const PK2 = 22222;
const PK3 = 33333;

const CERTIFICATE_NAME = 'Guild Certificate';
const CERTIFICATE_SYMBOL = 'GC';

const GUILD_NAME = 'Test Guild';

@external
func deploy_all{syscall_ptr: felt*, range_check_ptr}() -> Contracts {
    tempvar contracts: Contracts;
    %{
        ids.contracts.account1 = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", 
            [ids.PK1]
        ).contract_address
        mock_start = mock_call(ids.account_address, 'supportsInterface', [1])
        mock_start = mock_call(ids.account_address, 'onERC1155BatchReceived', [ids.ON_ERC1155_BATCH_RECEIVED_SELECTOR])

        ids.contracts.account2 = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", 
            [ids.PK2]
        ).contract_address
        mock_start = mock_call(ids.account_address, 'supportsInterface', [1])
        mock_start = mock_call(ids.account_address, 'onERC1155BatchReceived', [ids.ON_ERC1155_BATCH_RECEIVED_SELECTOR])

        ids.contracts.account3 = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", 
            [ids.PK3]
        ).contract_address
        mock_start = mock_call(ids.account_address, 'supportsInterface', [1])
        mock_start = mock_call(ids.account_address, 'onERC1155BatchReceived', [ids.ON_ERC1155_BATCH_RECEIVED_SELECTOR])

        declared = declare("./contracts/ModuleController.cairo")
        ids.contracts.controller = deploy_contract("./contracts/proxy.cairo", 
            [declared.class_hash]
        ).contract_address

        ids.guild_contract = declare("./contracts/guild_contract.cairo")
        ids.proxy_contract = declare("./contracts/proxy.cairo")

        declared = declare("./contracts/guild_manager.cairo")
        ids.contracts.guild_manager = deploy_contract("./contracts/proxy.cairo", 
            [declared.class_hash]
        ).contract_address

        declared = declare("./contracts/guild_certificate.cairo")
        ids.contracts.certificate = deploy_contract("./contracts/proxy.cairo", 
            [declared.class_hash]
        ).contract_address

        declared = declare("./contracts/fee_policy_manager.cairo")
        ids.contracts.policy_manager = deploy_contract("./contracts/proxy.cairo", 
            [declared.class_hash]
        ).contract_address
    %}
    Controller.initializer(contracts.controller, contracts.account1, contracts.account1);
    GuildManager.initializer(contracts.guild_manager, proxy_contract.class_hash, guild_contract.class_hash, contracts.controller, contracts.account1);
    Certificate.initializer(contracts.certificate, CERTIFICATE_NAME, CERTIFICATE_SYMBOL, contracts.guild_manager, contracts.account1);
    PolicyManager.initializer(contracts.policy_manager, contracts.controller, contracts.account1);
    Controller.set_address_for_module_id(contracts.controller, ModuleIds.FeePolicyManager, contracts.policy_manager);
    %{
        stop_prank = start_prank(ids.contracts.account1, ids.contracts.guild_manager)
    %}
    let (guild_address) = GuildManager.deploy_guild(contracts.guild_manager, GUILD_NAME, contracts.certificate);
    contracts.guild = guild_address;
    %{
        stop_prank()
    %}
    return contracts;
}