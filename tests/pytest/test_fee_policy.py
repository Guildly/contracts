"""Rewards system test file"""
import pytest
import asyncio
import os

from starkware.starknet.business_logic.state.state import BlockInfo
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract
from starkware.starkware_utils.error_handling import StarkException
from tests.pytest.utils.TransactionSender import (
    TransactionSender,
    from_call_to_call_array,
)

from tests.pytest.utils.Signer import Signer
from tests.pytest.utils.utilities import str_to_felt, to_uint
from tests.pytest.utils.realm_data import build_realm_data, pack_realm

GUILD_CONTRACT = os.path.join("contracts", "guild_contract.cairo")
GUILD_MANAGER = os.path.join("contracts", "guild_manager.cairo")
GUILD_CERTIFICATE = os.path.join("contracts", "guild_certificate.cairo")
TEST_NFT = os.path.join("contracts", "test_nft.cairo")
PROXY = os.path.join("contracts", "proxy.cairo")
MODULE_CONTROLLER = os.path.join("contracts", "ModuleController.cairo")
FEE_POLICY_MANAGER = os.path.join("contracts", "fee_policy_manager.cairo")
RESOURCES_FEE_POLICY = os.path.join("contracts/fee_policies/realms", "claim_resources.cairo")

signer1 = Signer(123456789987654321)
signer2 = Signer(987654321123456789)
signer3 = Signer(567899876512344321)

CONTRACTS_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "contracts")
OZ_CONTRACTS_PATH = os.path.join(
    os.path.dirname(__file__), "..", "..", "lib", "cairo_contracts", "src"
)
REALMS_CONTRACTS_PATH = os.path.join(
    os.path.dirname(__file__), "..", "..", "lib", "realms_contracts"
)
here = os.path.abspath(os.path.dirname(__file__))

CAIRO_PATH = [CONTRACTS_PATH, OZ_CONTRACTS_PATH, REALMS_CONTRACTS_PATH, here]

def set_block_number(self, starknet, block_number):
    starknet.state.state.block_info = BlockInfo(
        block_number,
        self.block_info.block_timestamp,
        self.block_info.gas_price,
        self.block_info.sequencer_address,

    )

def set_block_timestamp(starknet, block_timestamp):
    starknet.state.state.block_info = BlockInfo(
        starknet.state.state.block_info.block_number,
        block_timestamp,
        starknet.state.state.block_info.gas_price,
        starknet.state.state.block_info.sequencer_address,
        starknet.state.state.block_info.starknet_version,
    )

@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope="module")
async def contract_factory():
    starknet = await Starknet.empty()
    account1 = await starknet.deploy(
        "openzeppelin/account/presets/Account.cairo",
        cairo_path=CAIRO_PATH,
        constructor_calldata=[signer1.public_key],
    )
    account2 = await starknet.deploy(
        "openzeppelin/account/presets/Account.cairo",
        cairo_path=CAIRO_PATH,
        constructor_calldata=[signer2.public_key],
    )
    account3 = await starknet.deploy(
        "openzeppelin/account/presets/Account.cairo",
        cairo_path=CAIRO_PATH,
        constructor_calldata=[signer3.public_key],
    )
    guild_contract_class_hash = await starknet.declare(
        source=GUILD_CONTRACT,
        cairo_path=CAIRO_PATH,
    )
    guild_manager_class_hash = await starknet.declare(
        source=GUILD_MANAGER,
        cairo_path=CAIRO_PATH,
    )
    guild_certificate_class_hash = await starknet.declare(
        source=GUILD_CERTIFICATE,
        cairo_path=CAIRO_PATH,
    )
    guild_proxy_class_hash = await starknet.declare(
        source=PROXY,
        cairo_path=CAIRO_PATH,
    )
    module_controller_class_hash = await starknet.declare(
        source=MODULE_CONTROLLER,
        cairo_path=CAIRO_PATH
    )
    fee_policy_manager_class_hash = await starknet.declare(
        source=FEE_POLICY_MANAGER,
        cairo_path=CAIRO_PATH
    )
    resources_policy_class_hash = await starknet.declare(
        source=RESOURCES_FEE_POLICY,
        cairo_path=CAIRO_PATH
    )

    # Set up all realms contracts needed
    realms_module_controller_class_hash = await starknet.declare(
        source="contracts/settling_game/ModuleController.cairo",
        cairo_path=CAIRO_PATH
    )
    realms_class_hash = await starknet.declare(
        source="contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo",
        cairo_path=CAIRO_PATH
    )
    s_realms_class_hash = await starknet.declare(
        source="contracts/settling_game/tokens/S_Realms_ERC721_Mintable.cairo",
        cairo_path=CAIRO_PATH
    )
    resources_token_class_hash = await starknet.declare(
        source="contracts/settling_game/tokens/Resources_ERC1155_Mintable_Burnable.cairo",
        cairo_path=CAIRO_PATH
    )
    resources_class_hash = await starknet.declare(
        source="contracts/settling_game/modules/resources/Resources.cairo",
        cairo_path=CAIRO_PATH
    )
    settling_class_hash = await starknet.declare(
        source="contracts/settling_game/modules/settling/Settling.cairo",
        cairo_path=CAIRO_PATH
    )
    buildings_class_hash = await starknet.declare(
        source="contracts/settling_game/modules/buildings/Buildings.cairo",
        cairo_path=CAIRO_PATH
    )
    food_class_hash = await starknet.declare(
        source="contracts/settling_game/modules/food/Food.cairo",
        cairo_path=CAIRO_PATH
    )
    calculator_class_hash = await starknet.declare(
        source="contracts/settling_game/modules/calculator/Calculator.cairo",
        cairo_path=CAIRO_PATH
    )
    goblin_town_class_hash = await starknet.declare(
        source="contracts/settling_game/modules/goblintown/GoblinTown.cairo",
        cairo_path=CAIRO_PATH
    )


    module_controller_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            module_controller_class_hash.class_hash
        ]
    )

    sender = TransactionSender(account1)

    await sender.send_transaction(
        [
            (
                module_controller_proxy.contract_address,
                "initializer",
                [
                    account1.contract_address,
                    account1.contract_address
                ]
            )
        ],
        [signer1]
    )

    fee_policy_manager_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            fee_policy_manager_class_hash.class_hash
        ]
    )

    await sender.send_transaction(
        [
            (
                fee_policy_manager_proxy.contract_address,
                "initializer",
                [
                    module_controller_proxy.contract_address,
                    account1.contract_address
                ]
            )
        ],
        [signer1]
    )

    guild_manager_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            guild_manager_class_hash.class_hash,
        ],
    )

    await sender.send_transaction(
        [
            (
                guild_manager_proxy.contract_address,
                "initializer",
                [
                    guild_proxy_class_hash.class_hash,
                    guild_contract_class_hash.class_hash,
                    module_controller_proxy.contract_address,
                    account1.contract_address,
                ],
            )
        ],
        [signer1],
    )

    guild_certificate_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            guild_certificate_class_hash.class_hash,
        ],
    )

    await sender.send_transaction(
        [
            (
                guild_certificate_proxy.contract_address,
                "initializer",
                [
                    str_to_felt("Guild certificate"),
                    str_to_felt("GC"),
                    guild_manager_proxy.contract_address,
                    account1.contract_address,
                ],
            )
        ],
        [signer1],
    )

    resources_policy_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            resources_policy_class_hash.class_hash
        ]
    )

    await sender.send_transaction(
        [
            (
                resources_policy_proxy.contract_address,
                "initializer",
                [
                    1, # resources address
                    1, # realms_address
                    guild_certificate_proxy.contract_address,
                    fee_policy_manager_proxy.contract_address,
                    account1.contract_address,
                ],
            )
        ],
        [signer1],
    )

    execution_info = await sender.send_transaction(
        [
            (
                guild_manager_proxy.contract_address,
                "deploy_guild_proxy_contract",
                [str_to_felt("Test Guild"), guild_certificate_proxy.contract_address],
            )
        ],
        [signer1],
    )

    guild_proxy_address = execution_info.call_info.retdata[1]

    guild_contract_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            guild_contract_class_hash.class_hash,
        ],
    )

    guild_proxy = StarknetContract(
        state=starknet.state,
        abi=guild_proxy_class_hash.abi,
        contract_address=guild_proxy_address,
        deploy_call_info=guild_contract_proxy.deploy_call_info,
    )

    await sender.send_transaction(
        [
            (
                module_controller_proxy.contract_address,
                "set_address_for_module_id",
                [
                    1,
                    fee_policy_manager_proxy.contract_address
                ],
            ),
        ],
        [signer1],
    )
    
    # deploy realms contracts

    realms_module_controller_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            realms_module_controller_class_hash.class_hash
        ]
    )

    await sender.send_transaction(
        [
            (
                realms_module_controller_proxy.contract_address,
                "initializer",
                [
                    account1.contract_address,
                    account1.contract_address
                ],
            )
        ],
        [signer1],
    )

    realms_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            realms_class_hash.class_hash
        ],
    )

    await sender.send_transaction(
        [
            (
                realms_proxy.contract_address,
                "initializer",
                [
                    str_to_felt("Realm"),
                    str_to_felt("R"),
                    account1.contract_address
                ],
            )
        ],
        [signer1],
    )

    s_realms_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            s_realms_class_hash.class_hash
        ],
    )

    await sender.send_transaction(
        [
            (
                s_realms_proxy.contract_address,
                "initializer",
                [
                    str_to_felt("SRealm"), 
                    str_to_felt("SR"), 
                    account1.contract_address, 
                    realms_module_controller_proxy.contract_address
                ],
            )
        ],
        [signer1],
    )

    resources_token_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            resources_token_class_hash.class_hash
        ],
    )

    await sender.send_transaction(
        [
            (
                resources_token_proxy.contract_address,
                "initializer",
                [
                    1,  
                    account1.contract_address,
                    realms_module_controller_proxy.contract_address
                ],
            )
        ],
        [signer1],
    )

    resources_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            resources_class_hash.class_hash
        ],
    )

    await sender.send_transaction(
        [
            (
                resources_proxy.contract_address,
                "initializer",
                [
                    realms_module_controller_proxy.contract_address,
                    account1.contract_address
                ],
            )
        ],
        [signer1],
    )

    settling_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            settling_class_hash.class_hash
        ],
    )

    await sender.send_transaction(
        [
            (
                settling_proxy.contract_address,
                "initializer",
                [
                    realms_module_controller_proxy.contract_address,
                    account1.contract_address
                ],
            )
        ],
        [signer1],
    )
    
    buildings_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            buildings_class_hash.class_hash
        ],
    )

    await sender.send_transaction(
        [
            (
                buildings_proxy.contract_address,
                "initializer",
                [
                    realms_module_controller_proxy.contract_address,
                    account1.contract_address
                ],
            )
        ],
        [signer1],
    )

    food_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            food_class_hash.class_hash
        ],
    )

    await sender.send_transaction(
        [
            (
                food_proxy.contract_address,
                "initializer",
                [
                    realms_module_controller_proxy.contract_address,
                    account1.contract_address
                ],
            )
        ],
        [signer1],
    )

    calculator_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            calculator_class_hash.class_hash
        ],
    )

    await sender.send_transaction(
        [
            (
                calculator_proxy.contract_address,
                "initializer",
                [
                    realms_module_controller_proxy.contract_address,
                    account1.contract_address
                ],
            )
        ],
        [signer1],
    )


    goblin_town_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            goblin_town_class_hash.class_hash
        ],
    )

    await sender.send_transaction(
        [
            (
                goblin_town_proxy.contract_address,
                "initializer",
                [
                    realms_module_controller_proxy.contract_address,
                    account1.contract_address
                ],
            )
        ],
        [signer1],
    )

    await sender.send_transaction(
        [
            (
                realms_module_controller_proxy.contract_address,
                "set_address_for_module_id",
                [
                    1,
                    settling_proxy.contract_address
                ],
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_address_for_module_id",
                [
                    2,
                    resources_proxy.contract_address
                ],
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_address_for_module_id",
                [
                    3,
                    buildings_proxy.contract_address
                ],
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_address_for_module_id",
                [
                    4,
                    calculator_proxy.contract_address
                ],
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_address_for_module_id",
                [
                    13,
                    food_proxy.contract_address
                ],
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_address_for_module_id",
                [
                    14,
                    goblin_town_proxy.contract_address
                ],
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_address_for_module_id",
                [
                    1003,
                    realms_proxy.contract_address
                ],
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_address_for_module_id",
                [
                    1004,
                    resources_token_proxy.contract_address
                ],
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_address_for_module_id",
                [
                    1006,
                    s_realms_proxy.contract_address
                ],
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_write_access",
                [
                    1,
                    1006
                ]
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_write_access",
                [
                    14,
                    2
                ]
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_write_access",
                [
                    2,
                    1
                ]
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_write_access",
                [
                    2,
                    3
                ]
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_write_access",
                [
                    3,
                    13
                ]
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_write_access",
                [
                    13,
                    4
                ]
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_address_for_external_contract",
                [
                    2,
                    realms_proxy.contract_address
                ]
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_address_for_external_contract",
                [
                    3,
                    s_realms_proxy.contract_address
                ]
            ),
            (
                realms_module_controller_proxy.contract_address,
                "set_address_for_external_contract",
                [
                    4,
                    resources_token_proxy.contract_address
                ]
            )
        ],
        [signer1],
    )

    realm_data = pack_realm(build_realm_data(4, 5, 2, 1, 4, 2, 8, 13, 6, 0, 0, 0, 1, 4))

    await sender.send_transaction(
        [
            (
                realms_proxy.contract_address,
                "set_realm_data",
                [
                    *to_uint(1),
                    1,
                    realm_data
                ]
            ),
            (
                realms_proxy.contract_address,
                "mint",
                [
                    account1.contract_address
                ],
            ),
            (
                realms_proxy.contract_address,
                "approve",
                [
                    settling_proxy.contract_address,
                    *to_uint(1)
                ],
            ),
            (
                settling_proxy.contract_address,
                "settle",
                [
                    *to_uint(1),
                ]
            )
        ],
        [signer1],
    )

    return (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        module_controller_proxy,
        fee_policy_manager_proxy,
        resources_policy_proxy,
        realms_proxy,
        s_realms_proxy,
        resources_token_proxy,
        resources_proxy,
        settling_proxy,
        goblin_town_proxy
    )

@pytest.mark.asyncio
async def test_adding_members(contract_factory):
    """Test adding members to guild."""
    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        module_controller_proxy,
        fee_policy_manager_proxy,
        resources_policy_proxy,
        realms_proxy,
        s_realms_proxy,
        resources_token_proxy,
        resources_proxy,
        settling_proxy,
        goblin_town_proxy
    ) = contract_factory

    sender = TransactionSender(account1)

    await sender.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "whitelist_member",
                [account2.contract_address, 3],
            ),
            (
                guild_proxy.contract_address,
                "whitelist_member",
                [account3.contract_address, 2],
            ),
        ],
        [signer1],
    )

    await TransactionSender(account2).send_transaction(
        [(guild_proxy.contract_address, "join", [])], [signer2]
    )

    await TransactionSender(account3).send_transaction(
        [(guild_proxy.contract_address, "join", [])], [signer3]
    )

@pytest.mark.asyncio
async def test_fee_policy(contract_factory):
    """Test setting fee policy for the guild."""
    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        module_controller_proxy,
        fee_policy_manager_proxy,
        resources_policy_proxy,
        realms_proxy,
        s_realms_proxy,
        resources_token_proxy,
        resources_proxy,
        settling_proxy,
        goblin_town_proxy
    ) = contract_factory

    sender = TransactionSender(account1)

    await sender.send_transaction(
        [
            (
                fee_policy_manager_proxy.contract_address,
                "add_policy",
                [1, 1, get_selector_from_name("claim_resources")],
            )
        ],
        [signer1]
    )

    await sender.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "set_fee_policy",
                [1, 50, 50]
            )
        ],
        [signer1]
    )

@pytest.mark.asyncio
async def test_claim_resources(contract_factory):
    """Test claiming resources fee dist."""
    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        module_controller_proxy,
        fee_policy_manager_proxy,
        resources_policy_proxy,
        realms_proxy,
        s_realms_proxy,
        resources_token_proxy,
        resources_proxy,
        settling_proxy,
        goblin_town_proxy
    ) = contract_factory

    sender1 = TransactionSender(account1)
    sender2 = TransactionSender(account2)

    await sender1.send_transaction(
        [
            (
                s_realms_proxy.contract_address,
                "approve",
                [guild_proxy.contract_address, *to_uint(1)],
            ),
            (
                guild_proxy.contract_address,
                "deposit",
                [
                    1,
                    s_realms_proxy.contract_address,
                    *to_uint(1),
                    *to_uint(1)
                ],
            )
        ],
        [signer1]
    )

    await sender1.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "initialize_permissions",
                [
                    1,
                    resources_proxy.contract_address,
                    get_selector_from_name("claim_resources"),
                ],
            )
        ],
        [signer1]
    )

    # wait for rewards to accrue

    set_block_timestamp(starknet, starknet.state.state.block_info.block_timestamp + 1000000)

    calls = [(
        resources_proxy.contract_address,
        "claim_resources",
        [*to_uint(1)]
    )]

    (call_array, calldata) = from_call_to_call_array(calls)

    await sender2.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "execute_transactions",
                [
                    len(call_array),
                    *[x for t in call_array for x in t],
                    len(calldata),
                    *calldata,
                    0
                ],
            )
        ],
        [signer2]
    )

    owners_1 = []
    owners_2 = []
    for _ in range(22):
        owners_1.append(account1.contract_address)
        owners_2.append(account2.contract_address)

    execution_info = await sender1.send_transaction(
        [
            (
                resources_token_proxy.contract_address,
                "balanceOfBatch",
                [
                    22,
                    *owners_1,
                    22,
                    *[
                        *to_uint(1),
                        *to_uint(2),
                        *to_uint(3),
                        *to_uint(4),
                        *to_uint(5),
                        *to_uint(6),
                        *to_uint(7),
                        *to_uint(8),
                        *to_uint(9),
                        *to_uint(10),
                        *to_uint(11),
                        *to_uint(12),
                        *to_uint(13),
                        *to_uint(14),
                        *to_uint(15),
                        *to_uint(16),
                        *to_uint(17),
                        *to_uint(18),
                        *to_uint(19),
                        *to_uint(20),
                        *to_uint(21),
                        *to_uint(22),
                    ],
                ],
            )
        ],
        [signer1]
    )

    print(execution_info.call_info.retdata)

    execution_info = await sender2.send_transaction(
        [
            (
                resources_token_proxy.contract_address,
                "balanceOfBatch",
                [
                    22,
                    *owners_2,
                    22,
                    *[
                        *to_uint(1),
                        *to_uint(2),
                        *to_uint(3),
                        *to_uint(4),
                        *to_uint(5),
                        *to_uint(6),
                        *to_uint(7),
                        *to_uint(8),
                        *to_uint(9),
                        *to_uint(10),
                        *to_uint(11),
                        *to_uint(12),
                        *to_uint(13),
                        *to_uint(14),
                        *to_uint(15),
                        *to_uint(16),
                        *to_uint(17),
                        *to_uint(18),
                        *to_uint(19),
                        *to_uint(20),
                        *to_uint(21),
                        *to_uint(22),
                    ],
                ],
            )
        ],
        [signer2]
    )

    print(execution_info.call_info.retdata)

    assert 1 == 2

