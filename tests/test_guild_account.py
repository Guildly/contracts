"""GuildAccount.cairo test file."""
import asyncio
from copyreg import constructor
from importlib.abc import ExecutionLoader
import os
from secrets import token_bytes
from unittest.mock import call

import pytest
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from utils import str_to_felt, to_uint, Signer, from_call_to_call_array

signer1 = Signer(123456789987654321)
signer2 = Signer(987654321123456789)
signer3 = Signer(567899876512344321)

GUILD_CERTIFICATE = os.path.join("contracts", "GuildCertificate.cairo")
GUILD_ACCOUNT = os.path.join("contracts", "GuildAccount.cairo")
GAME_CONTRACT = os.path.join("contracts", "game_contract.cairo")
TEST_NFT = os.path.join("contracts", "TestNFT.cairo")


@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()


@pytest.fixture(scope="module")
async def contract_factory():
    starknet = await Starknet.empty()
    account1 = await starknet.deploy(
        "openzeppelin/account/Account.cairo",
        constructor_calldata=[signer1.public_key],
    )
    account2 = await starknet.deploy(
        "openzeppelin/account/Account.cairo", constructor_calldata=[signer2.public_key]
    )
    guild_certificate = await starknet.deploy(
        source=GUILD_CERTIFICATE,
        constructor_calldata=[
            str_to_felt("Token Gated Account"),
            str_to_felt("TGA"),
            account1.contract_address,
        ],
    )
    guild_account = await starknet.deploy(
        source=GUILD_ACCOUNT,
        constructor_calldata=[
            guild_certificate.contract_address,
        ],
    )
    # Transfer ownership
    await signer1.send_transaction(
        account=account1,
        to=guild_certificate.contract_address,
        selector_name="transfer_ownership",
        calldata=[guild_account.contract_address],
    )
    await signer1.send_transaction(
        account=account1,
        to=guild_account.contract_address,
        selector_name="initialize_owners",
        calldata=[
            2,
            account1.contract_address,
            account2.contract_address,
        ],
    )

    test_nft = await starknet.deploy(
        source=TEST_NFT,
        constructor_calldata=[
            str_to_felt("Test NFT"),
            str_to_felt("TNFT"),
            account1.contract_address,
        ],
    )

    game_contract = await starknet.deploy(
        source=GAME_CONTRACT, constructor_calldata=[test_nft.contract_address]
    )

    await signer1.send_transaction(
        account=account1,
        to=test_nft.contract_address,
        selector_name="mint",
        calldata=[account1.contract_address, *to_uint(1)],
    )

    return account1, account2, guild_account, test_nft, game_contract


@pytest.mark.asyncio
async def test_guild_account(contract_factory):
    """Test guild account."""
    (account1, account2, guild_account, test_nft, game_contract) = contract_factory

    await signer1.send_transaction(
        account=account1,
        to=test_nft.contract_address,
        selector_name="transferFrom",
        calldata=[
            account1.contract_address,
            guild_account.contract_address,
            *to_uint(1),
        ],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_account.contract_address,
        selector_name="execute_transaction",
        calldata=[
            game_contract.contract_address,
            get_selector_from_name("set_value_with_nft"),
            3,
            *[1, *to_uint(1)],
        ],
    )

    execution_info = await game_contract.get_value().call()
    assert execution_info.result == (1,)


# @pytest.mark.asyncio
# async def test_game_function(contract_factory):
#     """Test using a game contract function with member."""
#     (guild_account, account, test_nft, game_contract) = contract_factory

#     await signer2.send_transaction(
#         account=account,
#         to=test_nft.contract_address,
#         selector_name="transferFrom",
#         calldata=[
#             account.contract_address,
#             guild_account.contract_address,
#             *to_uint(1),
#         ],
#     )

#     await signer1.send_transaction(
#         account=guild_account,
#         to=game_contract.contract_address,
#         selector_name="set_value_with_nft",
#         calldata=[1, *to_uint(1)],
#     )

#     execution_info = await game_contract.get_value().call()
#     assert execution_info.result == (1,)


# @pytest.mark.asyncio
# async def test_add_guild_member(contract_factory):
#     """Test add guild member."""
#     (guild_account, account, test_nft, game_contract) = contract_factory

#     await signer1.send_transaction(
#         account=account,
#         to=guild_account.contract_address,
#         selector_name="add_guild_member",
#         calldata=[account2.contract_address],
#     )


# @pytest.mark.asyncio
# async def test_set_permissioned_calls(contract_factory):
#     """Tests setting an allowed call for the guild to check."""
#     (guild_account, account, test_nft, game_contract) = contract_factory

#     await signer2.send_transaction(
#         account=guild_account,
#     )
