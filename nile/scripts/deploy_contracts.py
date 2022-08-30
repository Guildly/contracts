from starkware.crypto.signature.signature import private_to_stark_key, sign
from starkware.starknet.core.os.transaction_hash.transaction_hash import (
    TransactionHashPrefix,
    calculate_transaction_hash_common,
)

from starkware.crypto.signature.signature import private_to_stark_key
from starkware.starknet.definitions.general_config import StarknetChainId
from starkware.starknet.public.abi import get_selector_from_name

from nile.core.call_or_invoke import call_or_invoke
from nile.core.account import Account
import os
import subprocess

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
    proxy_class_hash = "0x25ec026985a3bf9d0cc1fe17326b245dfdc3ff89b8fde106542a3ea56c5a918"
    contract_class_hash = "0x6ed6e7a7d736638ff0fb8dbf33ccf74e767f6915bee2c57f785f419752679d4"
    account = "0x01AFbaf9bfD9F77C0e1cB3bf41Ba680A6d4B370eEC53Af8578b2bB73C7fF499C"

    # account = Account("ACCOUNT_PRIVATE_KEY", "goerli")

    guild_manager_address, guild_manager_abi = nre.deploy(
        "GuildManager",
        arguments=[
            proxy_class_hash,
            contract_class_hash, 
        ],
        alias="guild_manager"
    )
    print(guild_manager_abi, guild_manager_address)
    guild_certificate_address, guild_certificate_abi = nre.deploy(
        "GuildCertificate",
        arguments=[
            str(str_to_felt("Guild Certificate")),
            str(str_to_felt("GC")),
            guild_manager_address,
        ],
        alias="guild_certificate"
    )
    print(guild_certificate_abi, guild_certificate_address)
    test_nft_address, test_nft_abi = nre.deploy(
        "TestNFT",
        arguments=[
            str(str_to_felt("Test NFT")),
            str(str_to_felt("TNFT")),
            account,
        ],
        alias="test_nft"
    )
    print(test_nft_abi, test_nft_address)
    points_contract_address, points_abi = nre.deploy(
        "ExperiencePoints",
        arguments=[
            str(str_to_felt("Experience Points")),
            str(str_to_felt("EP")),
            "18",
            str(0),
            str(0),
            account,
            account,
        ],
        alias="points_contract"
    )
    print(points_abi, points_contract_address)
    test_game_contract_address, test_game_abi = nre.deploy(
        "GameContract", 
        arguments=[
            test_nft_address, 
            points_contract_address
        ],
        alias="game_contract"
    )
    print(test_game_abi, test_game_contract_address)
