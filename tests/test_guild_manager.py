"""GuildManager.cairo test file."""
import pytest
import asyncio
import os

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract
from utils import (
    str_to_felt,
    to_uint,
    Signer,
    from_call_to_call_array
)

GUILD_CONTRACT = os.path.join("contracts", "GuildContract.cairo")
GUILD_MANAGER = os.path.join("contracts", "GuildManager.cairo")
GUILD_CERTIFICATE = os.path.join("contracts", "GuildCertificate.cairo")

signer1 = Signer(123456789987654321)
signer2 = Signer(987654321123456789)
signer3 = Signer(567899876512344321)


@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope="module")
async def contract_factory():
    starknet = await Starknet.empty()
    account1 = await starknet.deploy(
        "openzeppelin/account/Account.cairo",
        constructor_calldata=[signer1.public_key]
    )
    account2 = await starknet.deploy(
        "openzeppelin/account/Account.cairo",
        constructor_calldata=[signer2.public_key]
    )
    account3 = await starknet.deploy(
        "openzeppelin/account/Account.cairo",
        constructor_calldata=[signer3.public_key]
    )
    guild_contract_class_hash = await starknet.declare(
        source=GUILD_CONTRACT
    )
    guild_manager = await starknet.deploy(
        source=GUILD_MANAGER,
        constructor_calldata=[
            guild_contract_class_hash.class_hash
        ]
    )
    guild_certificate = await starknet.deploy(
        source=GUILD_CERTIFICATE,
        constructor_calldata=[
            str_to_felt("Guild certificate"),
            str_to_felt("GC"),
            guild_manager.contract_address
        ],
    )
    return starknet, account1, account2, account3, guild_manager, guild_certificate

@pytest.mark.asyncio
async def test_deploy(contract_factory):
    """Test deployment of guild."""
    (starknet, account1, account2, account3, guild_manager, guild_certificate) = contract_factory

    await signer1.send_transaction(
        account=account1,
        to=guild_manager.contract_address,
        selector_name="deploy_guild_contract",
        calldata=[
            str_to_felt("Test"),
            account1.contract_address,
            guild_certificate.contract_address
        ]
    )

    execution_info = await guild_manager.get_guild_contracts().call()
    guild_address = execution_info.result.guilds[0]

    await signer1.send_transaction(
        account=account1,
        to=guild_address,
        selector_name="whitelist_members",
        calldata=[
            2,
            account2.contract_address,
            3,
            account3.contract_address,
            3
        ],
    )

    await signer2.send_transaction(
        account=account2,
        to=guild_address,
        selector_name="join",
        calldata=[],
    )