"""Rewards system test file"""
import pytest
import asyncio
import os

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

GUILD_CONTRACT = os.path.join("contracts/reward_system", "guild_contract_reward.cairo")
GUILD_CONTRACT_UPGRADE = os.path.join(
    "contracts/proxy_upgrade", "guild_contract_upgrade.cairo"
)
GUILD_MANAGER = os.path.join("contracts", "guild_manager.cairo")
GUILD_CERTIFICATE = os.path.join("contracts", "guild_certificate.cairo")
POINTS_CONTRACT = os.path.join("contracts/reward_system", "experience_points.cairo")
GAME_CONTRACT = os.path.join("contracts/reward_system", "game_contract.cairo")
TEST_NFT = os.path.join("contracts", "test_nft.cairo")
PROXY = os.path.join("contracts", "proxy.cairo")

signer1 = Signer(123456789987654321)
signer2 = Signer(987654321123456789)
signer3 = Signer(567899876512344321)

CONTRACTS_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "contracts")
OZ_CONTRACTS_PATH = os.path.join(
    os.path.dirname(__file__), "..", "..", "lib", "cairo_contracts", "src"
)
here = os.path.abspath(os.path.dirname(__file__))

CAIRO_PATH = [CONTRACTS_PATH, OZ_CONTRACTS_PATH, here]

@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope="module")
async def contract_factory():
    starknet = await Starknet.empty()
    account1 = await starknet.deploy(
        "contracts/tests/Account.cairo",
        cairo_path=CAIRO_PATH,
        constructor_calldata=[signer1.public_key],
    )
    account2 = await starknet.deploy(
        "contracts/tests/Account.cairo",
        cairo_path=CAIRO_PATH,
        constructor_calldata=[signer2.public_key],
    )
    account3 = await starknet.deploy(
        "contracts/tests/Account.cairo",
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

    guild_manager_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            guild_manager_class_hash.class_hash,
        ],
    )

    sender = TransactionSender(account1)

    await sender.send_transaction(
        [
            (
                guild_manager_proxy.contract_address,
                "initializer",
                [
                    guild_proxy_class_hash.class_hash,
                    guild_contract_class_hash.class_hash,
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

    test_nft = await starknet.deploy(
        source=TEST_NFT,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            str_to_felt("Test NFT"),
            str_to_felt("TNFT"),
            account1.contract_address,
        ],
    )

    test_nft_2 = await starknet.deploy(
        source=TEST_NFT,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            str_to_felt("Test NFT"),
            str_to_felt("TNFT"),
            account1.contract_address,
        ],
    )

    points_contract = await starknet.deploy(
        source=POINTS_CONTRACT,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            str_to_felt("Experience Points"),
            str_to_felt("EP"),
            account1.contract_address,
        ],
    )

    game_contract = await starknet.deploy(
        source=GAME_CONTRACT,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            test_nft.contract_address,
            points_contract.contract_address,
        ],
    )

    return (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract,
        points_contract
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
        test_nft,
        test_nft_2,
        game_contract,
        points_contract
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
async def test_permissions(contract_factory):
    """Test setting permissions in the guild."""
    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract,
        points_contract
    ) = contract_factory

    sender = TransactionSender(account1)

    await sender.send_transaction(
        [
            (
                test_nft.contract_address,
                "mint",
                [account1.contract_address, *to_uint(1)],
            )
        ],
        [signer1]
    )

    await sender.send_transaction(
        [
            (
                test_nft.contract_address,
                "approve",
                [guild_proxy.contract_address, *to_uint(1)],
            )
        ],
        [signer1]
    )

    await sender.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "deposit",
                [
                    1,
                    test_nft.contract_address,
                    *to_uint(1),
                    *to_uint(1)
                ],
            )
        ],
        [signer1]
    )

    await sender.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "initialize_permissions",
                [
                    2,
                    game_contract.contract_address,
                    get_selector_from_name("kill_goblin"),
                    test_nft.contract_address,
                    get_selector_from_name("symbol")
                ],
            )
        ],
        [signer1]
    )

    calls = [(
        game_contract.contract_address,
        "kill_goblin",
        []
    )]

    (call_array, calldata) = from_call_to_call_array(calls)

    await sender.send_transaction(
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
        [signer1]
    )

    execution_info = await game_contract.get_goblin_kill_count(
        guild_proxy.contract_address
    ).call()
    assert execution_info.result == (1,)


    execution_info = await sender.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "get_tx_account",
                []
            )
        ],
        [signer1]
    )

    print(execution_info.call_info.retdata)

    execution_info = await points_contract.balanceOf(
        guild_proxy.contract_address, to_uint(1)
    ).call()

    assert execution_info.result == (to_uint(9),)

