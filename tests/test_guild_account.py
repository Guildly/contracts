"""TokenGatedAccount.cairo test file."""
import asyncio
from copyreg import constructor
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

TOKEN_GATED_ACCOUNT = os.path.join("contracts", "TokenGatedAccount.cairo")
TEST_NFT = os.path.join("contracts", "TestNFT.cairo")

@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope="module")
async def contract_factory():
    starknet = await Starknet.empty()
    token_gated_account = await starknet.deploy(
        source=TOKEN_GATED_ACCOUNT,
        constructor_calldata=[
            str_to_felt("Token Gated Account"),
            str_to_felt("TGA"),
            signer1.public_key
            ],
    )
    account = await starknet.deploy(
        "openzeppelin/account/Account.cairo",
        constructor_calldata=[signer1.public_key],
    )
    test_nft = await starknet.deploy(
        source=TEST_NFT,
        constructor_calldata=[
            str_to_felt("Test NFT"),
            str_to_felt("TNFT"),
            account.contract_address
        ]
    )

    await signer1.send_transaction(
        account=account,
        to=test_nft.contract_address,
        selector_name="mint",
        calldata=[account.contract_address, to_uint(1)]
    )

    return token_gated_account, account, test_nft

@pytest.mark.asyncio
async def test_guild_account(contract_factory):
    """Test guild account."""
    (
        token_gated_account,
        account,
        test_nft
    ) = contract_factory

    await signer1.send_transaction(
        account=account,
        to=test_nft.contract_address,
        selector_name="transferFrom",
        calldata=[account.contract_address, token_gated_account, to_uint(1)]
    )

    

    execution_info = await target.get_value().call()
    assert execution_info.result == (1,)