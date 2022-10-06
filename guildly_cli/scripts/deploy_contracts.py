from starkware.crypto.signature.signature import private_to_stark_key, sign
from starkware.starknet.core.os.transaction_hash.transaction_hash import (
    TransactionHashPrefix,
    calculate_transaction_hash_common,
)
from starkware.starknet.compiler.compile import compile_starknet_files

from starkware.crypto.signature.signature import private_to_stark_key
from starkware.starknet.definitions.general_config import StarknetChainId
from starkware.starknet.public.abi import get_selector_from_name

from nile.core.account import Account

import os
import subprocess
import time

import sys

from guildly_cli.scripts.caller_invoke import wrapped_send
from guildly_cli.scripts.utils import wrapped_declare

# deploy account, dummy contract, owner contract
# sign transaction to set value to 1
# send call to owner contract to ultimately call set value (should error out)
# transfer NFT to owner contract
# sign transaction to set value to 3 (should error)
# send call to owner contract to ultimately call set value to 2 (should work)

TRANSACTION_VERSION = 0


def to_uint(a):
    """Takes in value, returns uint256-ish tuple."""
    return (a & ((1 << 128) - 1), a >> 128)


def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")

def strhex_as_strfelt(strhex: str):
    """Converts a string in hex format to a string in felt format"""
    if strhex is not None:
        return str(int(strhex, 16))
    else:
        print("strhex address is None.")


def from_call_to_call_array(calls):
    """Transform from Call to CallArray."""
    call_array = []
    calldata = []
    for _, call in enumerate(calls):
        assert len(call) == 3, "Invalid call parameters"
        entry = (
            int(call[0], 16),
            get_selector_from_name(call[1]),
            len(calldata),
            len(call[2]),
        )
        call_array.append(entry)
        calldata.extend(call[2])
    return (call_array, calldata)


def get_transaction_hash(account, call_array, calldata, nonce, max_fee):
    """Calculate the transaction hash."""
    execute_calldata = [
        len(call_array),
        *[x for t in call_array for x in t],
        len(calldata),
        *calldata,
        nonce,
    ]

    return calculate_transaction_hash_common(
        TransactionHashPrefix.INVOKE,
        TRANSACTION_VERSION,
        account,
        get_selector_from_name("__execute__"),
        execute_calldata,
        max_fee,
        StarknetChainId.TESTNET.value,
        [],
    )


def sign_transaction(sender, calls, nonce, max_fee=0):
    """Sign a transaction for an Account."""
    (call_array, calldata) = from_call_to_call_array(calls)
    print("callarray:", call_array)
    print("calldata:", calldata)
    message_hash = get_transaction_hash(
        int(sender, 16), call_array, calldata, nonce, max_fee
    )
    print("message_hash:", message_hash)
    print("public key:", private_to_stark_key(1234))
    sig_r, sig_s = sign(msg_hash=message_hash, priv_key=1234)
    return (call_array, calldata, sig_r, sig_s)


def run(nre):
    account = Account("STARKNET_PRIVATE_KEY", nre.network)

    # proxy_class_hash = account.declare("proxy", "0", alias="proxy")
    # guild_contract_class_hash = account.declare("guild_contract", "0", alias="guild_contract")
    # guild_manager_class_hash = account.declare("guild_manager", "0", alias="guild_manager")
    # guild_certificate_class_hash = account.declare("guild_certificate", "0", alias="guild_certificate")

    proxy_class_hash = wrapped_declare(account, "proxy", nre.network, alias="proxy")
    guild_contract_class_hash = wrapped_declare(account, "guild_contract", nre.network, alias="guild_contract")
    guild_manager_class_hash = wrapped_declare(account, "guild_manager", nre.network, alias="guild_manager")
    guild_certificate_class_hash = wrapped_declare(account, "guild_certificate", nre.network, alias="guild_certificate")

    guild_proxy_manager_address, guild_proxy_manager_abi = nre.deploy(
        "proxy",
        arguments=[
            guild_manager_class_hash,
        ],
        alias="proxy_guild_manager"
    )

    print(guild_proxy_manager_abi, guild_proxy_manager_address)

    guild_proxy_certificate_address, guild_proxy_certificate_abi = nre.deploy(
        "proxy",
        arguments=[
            guild_certificate_class_hash,
        ],
        alias="guild_certificate",
    )

    print(guild_proxy_certificate_abi, guild_proxy_certificate_address)

    # wait 120s - this will reduce on mainnet
    # print('🕒 Waiting for deploy before invoking')
    # time.sleep(120)

    # wrapped_send(
    #     account,
    #     guild_proxy_manager_address,
    #     "initializer", 
    #     calldata=[
    #         strhex_as_strfelt(proxy_class_hash),
    #         strhex_as_strfelt(guild_contract_class_hash),
    #         strhex_as_strfelt(account.address)
    #     ]
    # )

    # wrapped_send(
    #     account,
    #     guild_proxy_certificate_address,
    #     "initializer", 
    #     calldata=[
    #         str(str_to_felt("Guild Certificate")),
    #         str(str_to_felt("GC")),
    #         strhex_as_strfelt(guild_proxy_manager_address),
    #         strhex_as_strfelt(account.address)
    #     ],
    # )

    test_nft_address, test_nft_abi = nre.deploy(
        "test_nft",
        arguments=[
            str(str_to_felt("Test NFT")),
            str(str_to_felt("TNFT")),
            strhex_as_strfelt(account.address),
        ],
        alias="test_nft"
    )
    print(test_nft_abi, test_nft_address)
    points_contract_address, points_abi = nre.deploy(
        "experience_points",
        arguments=[
            str(str_to_felt("Experience Points")),
            str(str_to_felt("EP")),
            "18",
            str(0),
            str(0),
            strhex_as_strfelt(account.address),
            strhex_as_strfelt(account.address),
        ],
        alias="points_contract"
    )
    print(points_abi, points_contract_address)
    test_game_contract_address, test_game_abi = nre.deploy(
        "game_contract", 
        arguments=[
            test_nft_address, 
            points_contract_address
        ],
        alias="game_contract"
    )
    print(test_game_abi, test_game_contract_address)
