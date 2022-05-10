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
OWNER_CONTRACT = os.path.join("contracts", "owner_contract.cairo")
TARGET = os.path.join("contracts", "target.cairo")


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
            signer1.public_key,
        ],
    )
    target = await starknet.deploy(source=TARGET, constructor_calldata=[])
    account = await starknet.deploy(
        "openzeppelin/account/Account.cairo",
        constructor_calldata=[signer3.public_key],
    )
    owner_contract = await starknet.deploy(
        source=OWNER_CONTRACT, constructor_calldata=[]
    )

    return token_gated_account, target, account, owner_contract


@pytest.mark.asyncio
async def test_token_gated_account(contract_factory):
    """Test using token gated account from deployer."""
    (token_gated_account, target, account, owner_contract) = contract_factory

    await signer1.send_transaction(
        account=token_gated_account,
        to=target.contract_address,
        selector_name="set_value",
        calldata=[1],
    )

    execution_info = await target.get_value().call()
    assert execution_info.result == (1,)


@pytest.mark.asyncio
async def test_revert_new_signer(contract_factory):
    """Test other signer without NFT."""
    (token_gated_account, target, account, owner_contract) = contract_factory

    with pytest.raises(StarkException):
        await signer2.send_transaction(
            account=token_gated_account,
            to=target.contract_address,
            selector_name="set_value",
            calldata=[2],
        )


@pytest.mark.asyncio
async def test_signer_nft_transfer(contract_factory):
    """Test other signer with NFT."""
    (token_gated_account, target, account, owner_contract) = contract_factory

    await signer1.send_transaction(
        account=token_gated_account,
        to=token_gated_account.contract_address,
        selector_name="transferFrom",
        calldata=[signer1.public_key, signer2.public_key, 0, 0],
    )

    await signer2.send_transaction(
        account=token_gated_account,
        to=target.contract_address,
        selector_name="set_value",
        calldata=[3],
    )

    execution_info = await target.get_value().call()
    assert execution_info.result == (3,)

    # execution_info = await signer3.send_transaction(
    #     account=account,
    #     to=token_gated_account.contract_address,
    #     selector_name="test_function",
    #     calldata=[],
    # )

    execution_info = await signer2.send_transaction(
        account=token_gated_account,
        to=token_gated_account.contract_address,
        selector_name="test_function",
        calldata=[],
    )
    print(execution_info.result.response)
    print(token_gated_account.contract_address)
    print(account.contract_address)
    assert 1 == 2


# @pytest.mark.asyncio
# async def test_account_nft_transfer(contract_factory):
#     """Test account with NFT"""
#     (token_gated_account, target, account, owner_contract) = contract_factory

#     await signer2.send_transaction(
#         account=token_gated_account,
#         to=token_gated_account.contract_address,
#         selector_name="transferFrom",
#         calldata=[signer2.public_key, account.contract_address, 0, 0],
#     )

#     callarray, calldata = from_call_to_call_array(
#         [(target.contract_address, "set_value", [4])]
#     )

#     # callarray = [(target.contract_address, get_selector_from_name("set_value"), 0, 1)]
#     # calldata = [4]

#     execution_info = await token_gated_account.get_nonce().call()
#     (nonce,) = execution_info.result

#     print(callarray, calldata, nonce)

#     await signer3.send_account_transaction(
#         account=account,
#         to=token_gated_account.contract_address,
#         selector_name="__execute__",
#         calldata=[callarray, calldata, nonce],
#     )


# execution_info = await signer3.send_transaction(
#     account=account,
#     to=token_gated_account.contract_address,
#     selector_name="test_function",
#     calldata=[],
# )
# print(execution_info)
# assert 1 == 2


@pytest.mark.asyncio
async def test_contract_nft_transfer(contract_factory):
    """Test contract with NFT"""
    (token_gated_account, target, account, owner_contract) = contract_factory

    await signer2.send_transaction(
        account=token_gated_account,
        to=token_gated_account.contract_address,
        selector_name="transferFrom",
        calldata=[signer2.public_key, owner_contract.contract_address, 0, 0],
    )

    await signer3.send_transaction(
        account=account,
        to=owner_contract.contract_address,
        selector_name="set_dummy_value",
        calldata=[token_gated_account.contract_address, target.contract_address, 4],
    )

    execution_info = await target.get_value().call()
    assert execution_info.result == (4,)
