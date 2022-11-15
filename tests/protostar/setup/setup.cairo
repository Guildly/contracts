%lang starknet

from tests.protostar.setup.interfaces import GuildManager, Certificate

from contracts.guild_contract import Permission
from contracts.utils.guild_structs import ModuleIds

from contracts.token.constants import (
    IERC1155_ID,
    IERC1155_METADATA_ID,
    IERC1155_RECEIVER_ID,
    IACCOUNT_ID,
    ON_ERC1155_RECEIVED_SELECTOR,
    ON_ERC1155_BATCH_RECEIVED_SELECTOR,
)

struct Contracts {
    account1: felt,
    account2: felt,
    account3: felt,
    guild: felt,
    guild_manager: felt,
    certificate: felt,
    test_nft: felt,
    points_contract: felt,
    game_contract: felt,
}

const PK1 = 11111;
const PK2 = 22222;
const PK3 = 33333;

const CERTIFICATE_NAME = 'Guild Certificate';
const CERTIFICATE_SYMBOL = 'GC';

const GUILD_NAME = 'Test Guild';

func deploy_all{syscall_ptr: felt*, range_check_ptr}() -> Contracts {
    alloc_locals;
    tempvar contracts: Contracts;
    local proxy_class_hash;
    local guild_class_hash;
    %{
        ids.contracts.account1 = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", 
            [ids.PK1]
        ).contract_address
        mock_start = mock_call(ids.contracts.account1, 'supportsInterface', [1])
        mock_start = mock_call(ids.contracts.account1, 'onERC1155BatchReceived', [ids.ON_ERC1155_BATCH_RECEIVED_SELECTOR])

        ids.contracts.account2 = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", 
            [ids.PK2]
        ).contract_address
        mock_start = mock_call(ids.contracts.account2, 'supportsInterface', [1])
        mock_start = mock_call(ids.contracts.account2, 'onERC1155BatchReceived', [ids.ON_ERC1155_BATCH_RECEIVED_SELECTOR])

        ids.contracts.account3 = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", 
            [ids.PK3]
        ).contract_address
        mock_start = mock_call(ids.contracts.account3, 'supportsInterface', [1])
        mock_start = mock_call(ids.contracts.account3, 'onERC1155BatchReceived', [ids.ON_ERC1155_BATCH_RECEIVED_SELECTOR])

        declared = declare("./contracts/guild_contract.cairo")
        ids.guild_class_hash = declared.class_hash

        declared = declare("./contracts/proxy.cairo")
        ids.proxy_class_hash = declared.class_hash

        declared = declare("./contracts/guild_manager.cairo")
        ids.contracts.guild_manager = deploy_contract("./contracts/proxy.cairo", 
            [declared.class_hash]
        ).contract_address

        declared = declare("./contracts/guild_certificate.cairo")
        ids.contracts.certificate = deploy_contract("./contracts/proxy.cairo", 
            [declared.class_hash]
        ).contract_address

        ids.contracts.test_nft = deploy_contract("./contracts/test_nft.cairo", [
            1,
            1,
            ids.contracts.account1
        ]).contract_address

        ids.contracts.points_contract = deploy_contract("./contracts/experience_points.cairo", [
            1,
            1,
            18,
            0,
            0,
            ids.contracts.account1,
            ids.contracts.account1
        ]).contract_address

        ids.contracts.game_contract = deploy_contract("./contracts/game_contract.cairo", [
            ids.contracts.test_nft,
            ids.contracts.points_contract
        ]).contract_address
    %}
    GuildManager.initializer(contracts.guild_manager, proxy_class_hash, guild_class_hash, contracts.account1);
    Certificate.initializer(contracts.certificate, CERTIFICATE_NAME, CERTIFICATE_SYMBOL, contracts.guild_manager, contracts.account1);
    %{
        stop_prank = start_prank(ids.contracts.account1, ids.contracts.guild_manager)
    %}
    let (local guild_address) = GuildManager.deploy_guild(contracts.guild_manager, GUILD_NAME, contracts.certificate);
    %{
        ids.contracts.guild = ids.guild_address
        stop_prank()
    %}
    return contracts;
}