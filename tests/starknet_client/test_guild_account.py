"""GuildAccount.cairo test file."""
import asyncio
from copyreg import constructor
from ctypes.wintypes import POINT
from importlib.abc import ExecutionLoader
import os
from secrets import token_bytes
from unittest.mock import call

import pytest
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from utils import (
    str_to_felt,
    to_uint,
    Signer,
    from_call_to_call_array
)

signer1 = Signer(123456789987654321)
signer2 = Signer(987654321123456789)
signer3 = Signer(567899876512344321)

GUILD_CERTIFICATE = os.path.join("contracts", "GuildCertificate.cairo")
GUILD_ACCOUNT = os.path.join("contracts", "GuildAccount.cairo")
POINTS_CONTRACT = os.path.join("contracts", "ExperiencePoints.cairo")
GAME_CONTRACT = os.path.join("contracts", "GameContract.cairo")
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
            str_to_felt("Guild certificate"),
            str_to_felt("GC"),
            account1.contract_address,
        ],
    )
    guild_account = await starknet.deploy(
        source=GUILD_ACCOUNT,
        constructor_calldata=[
            str_to_felt("Test Guild"),
            account1.contract_address,
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
        selector_name="whitelist_members",
        calldata=[
            2,
            account1.contract_address,
            3,
            account2.contract_address,
            3
        ],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_account.contract_address,
        selector_name="join",
        calldata=[],
    )

    await signer2.send_transaction(
        account=account2,
        to=guild_account.contract_address,
        selector_name="join",
        calldata=[],
    )

    test_nft = await starknet.deploy(
        source=TEST_NFT,
        constructor_calldata=[
            str_to_felt("Test NFT"),
            str_to_felt("TNFT"),
            account1.contract_address,
        ],
    )

    points_contract = await starknet.deploy(
        source=POINTS_CONTRACT, constructor_calldata=[
            str_to_felt("Experience Points"),
            str_to_felt("EP"),
            18,
            *to_uint(0),
            account1.contract_address,
            account1.contract_address
        ]
    )

    game_contract = await starknet.deploy(
        source=GAME_CONTRACT, constructor_calldata=[
            test_nft.contract_address, 
            points_contract.contract_address
        ]
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

    with pytest.raises(StarkException):
        await signer1.send_transaction(
            account=account1,
            to=guild_account.contract_address,
            selector_name="execute_transactions",
            calldata=[
                game_contract.contract_address,
                get_selector_from_name("set_character_name"),
                2,
                *[
                    str_to_felt("Bob"), 
                    account1.contract_address
                ],
            ],
        )


@pytest.mark.asyncio
async def test_permissions(contract_factory):
    """
        Tests intiializing permissions. Tests the permission checking and initialization
        protection.
    """
    (account1, account2, guild_account, test_nft, game_contract) = contract_factory

    await signer1.send_transaction(
        account=account1,
        to=guild_account.contract_address,
        selector_name="initialize_permissions",
        calldata=[
            2,
            game_contract.contract_address,
            get_selector_from_name("set_character_name"),
            test_nft.contract_address,
            get_selector_from_name("symbol")
        ],
    )

    # execution_info = await guild_account.get_permissions().call()
    # assert execution_info.result == (
    #     [
    #         game_contract.contract_address,
    #         get_selector_from_name("set_value_with_nft"),
    #         test_nft.contract_address,
    #         get_selector_from_name("symbol")
    #     ],
    # )

    calls = [(
        game_contract.contract_address, 
        "set_character_name",
        [*[
            str_to_felt("Bob"), 
            account1.contract_address
            ]
        ]
    )]

    (call_array, calldata) = from_call_to_call_array(calls)

    await signer1.send_transaction(
        account=account1,
        to=guild_account.contract_address,
        selector_name="execute_transactions",
        calldata=[
            len(call_array),
            *[x for t in call_array for x in t],
            len(calldata),
            *calldata,
            0
        ],
    )

    execution_info = await game_contract.get_character_name(account1.contract_address).call()
    assert execution_info.result == (str_to_felt("Bob"),)

    with pytest.raises(StarkException):
        await signer1.send_transaction(
            account=account1,
            to=guild_account.contract_address,
            selector_name="initialize_permissions",
            calldata=[
                1,
                test_nft.contract_address,
                get_selector_from_name("name"),
            ],
        )


@pytest.mark.asyncio
async def test_non_permissioned(contract_factory):
    """Test calling function that has not been permissioned."""
    (account1, account2, guild_account, test_nft, game_contract) = contract_factory

    calls = [(
        test_nft.contract_address, 
        "name",
        [0]
    )]

    (call_array, calldata) = from_call_to_call_array(calls)

    with pytest.raises(StarkException):
        await signer1.send_transaction(
            account=account1,
            to=guild_account.contract_address,
            selector_name="execute_transactions",
            calldata=[
                len(call_array),
                *[x for t in call_array for x in t],
                len(calldata),
                *calldata,
                1
            ],
        )

    calls = [(
        test_nft.contract_address, 
        "get_character_name",
        [0]
    )]

    (call_array, calldata) = from_call_to_call_array(calls)

    with pytest.raises(StarkException):
        await signer1.send_transaction(
            account=account1,
            to=guild_account.contract_address,
            selector_name="execute_transactions",
            calldata=[
                len(call_array),
                *[x for t in call_array for x in t],
                len(calldata),
                *calldata,
                1
            ],
        )


@pytest.mark.asyncio
async def test_deposit_and_withdraw(contract_factory):
    """Test deposit and withdraw owned asset."""
    (account1, account2, guild_account, test_nft, game_contract) = contract_factory

    await signer1.send_transaction(
        account=account1,
        to=test_nft.contract_address,
        selector_name="mint",
        calldata=[account1.contract_address, *to_uint(2)],
    )

    await signer1.send_transaction(
        account=account1,
        to=test_nft.contract_address,
        selector_name="mint",
        calldata=[account1.contract_address, *to_uint(3)],
    )

    await signer1.send_transaction(
        account=account1,
        to=test_nft.contract_address,
        selector_name="approve",
        calldata=[guild_account.contract_address, *to_uint(2)],
    )

    await signer1.send_transaction(
        account=account1,
        to=test_nft.contract_address,
        selector_name="approve",
        calldata=[guild_account.contract_address, *to_uint(3)],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_account.contract_address,
        selector_name="deposit_ERC721",
        calldata=[test_nft.contract_address, *to_uint(2)],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_account.contract_address,
        selector_name="deposit_ERC721",
        calldata=[test_nft.contract_address, *to_uint(3)],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_account.contract_address,
        selector_name="withdraw_ERC721",
        calldata=[test_nft.contract_address, *to_uint(2)],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_account.contract_address,
        selector_name="withdraw_ERC721",
        calldata=[test_nft.contract_address, *to_uint(3)],
    )


@pytest.mark.asyncio
async def test_withdraw_non_held(contract_factory):
    """Test whether withdrawing non deposited nft fails."""
    (account1, account2, guild_account, test_nft, game_contract) = contract_factory

    with pytest.raises(StarkException):
        await signer1.send_transaction(
            account=account1,
            to=guild_account.contract_address,
            selector_name="withdraw_ERC721",
            calldata=[test_nft.contract_address, *to_uint(1)],
        )

@pytest.mark.asyncio
async def test_multicall(contract_factory):
    """Test executing a multicall from account."""
    (account1, account2, guild_account, test_nft, game_contract) = contract_factory

    calls = [
        (
            test_nft.contract_address,
            "mint",
            [account1.contract_address, *to_uint(4)]
        ),
        (
            test_nft.contract_address,
            "approve",
            [guild_account.contract_address, *to_uint(4)] 
        )
    ]

    await signer1.send_transactions(
        account=account1,
        calls=calls,
    )

    calls = [
        (
            game_contract.contract_address,
            "set_character_name",
            [str_to_felt("Adam"), account1.contract_address] 
        ),
        (
            test_nft.contract_address,
            "symbol",
            []
        )
    ]

    (call_array, calldata) = from_call_to_call_array(calls)

    await signer1.send_transaction(
        account=account1,
        to=guild_account.contract_address,
        selector_name="execute_transactions",
        calldata=[
            len(call_array),
            *[x for t in call_array for x in t],
            len(calldata),
            *calldata,
            1
        ],
    )





