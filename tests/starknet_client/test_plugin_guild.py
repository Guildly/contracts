"""GuildPlugin.cairo test file."""
import asyncio
from copyreg import constructor
import os

import pytest
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from utils import (
    Signer,
)

signer1 = Signer(123456789987654321)
signer2 = Signer(987654321123456789)
signer3 = Signer(567899876512344321)

GUILD_PLUGIN = os.path.join("contracts", "GuildPlugin.cairo")


@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope="module")
async def contract_factory():
    starknet = await Starknet.empty()
    account = await starknet.deploy(
        "openzeppelin/account/Account.cairo",
        constructor_calldata=[signer1.public_key],
    )
    guild_plugin = await starknet.deploy(
        source=GUILD_PLUGIN,
        constructor_calldata=[]
    )
    return account, guild_plugin

# @pytest.mark.asyncio
# async def test_guild_plugin(contract_factory):
#     """Test guild plugin."""
#     (account, guild_plugin) = contract_factory

#     await 
