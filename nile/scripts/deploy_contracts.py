from starkware.crypto.signature.signature import private_to_stark_key, sign
from starkware.starknet.core.os.transaction_hash.transaction_hash import (
    TransactionHashPrefix,
    calculate_transaction_hash_common,
)

from starkware.crypto.signature.signature import private_to_stark_key
from starkware.starknet.definitions.general_config import StarknetChainId
from starkware.starknet.public.abi import get_selector_from_name

from nile.core.call_or_invoke import call_or_invoke
import os
import subprocess

# deploy account, dummy contract, owner contract
# sign transaction to set value to 1
# send call to owner contract to ultimately call set value (should error out)
# transfer NFT to owner contract
# sign transaction to set value to 3 (should error)
# send call to owner contract to ultimately call set value to 2 (should work)

TRANSACTION_VERSION = 0

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
        print("callarray:",call_array)
        print("calldata:",calldata)
        message_hash = get_transaction_hash(
            int(sender, 16), call_array, calldata, nonce, max_fee
        )
        print("message_hash:",message_hash)
        print("public key:",private_to_stark_key(1234))
        sig_r, sig_s = sign(msg_hash=message_hash, priv_key=1234)
        return (call_array, calldata, sig_r, sig_s)

def run(nre):
    # guild_certificate_address, guild_certificate_abi = nre.deploy(
    #     "GuildCertificate", 
    #     arguments=[
    #         str(str_to_felt("Test Certificate")),
    #         str(str_to_felt("TC")),
    #         "0x0342732d1e1b6deb415d06154b7339c73bf8a6a1ba347208f71616dd5b20e3c3"
    #     ],
    #     alias="guild_certificate")
    # print(guild_certificate_abi, guild_certificate_address)
    # guild_address, guild_abi = nre.deploy(
    #     "GuildAccount", 
    #     arguments=[
    #         str(str_to_felt("Test Guild")),
    #         "0x0342732d1e1b6deb415d06154b7339c73bf8a6a1ba347208f71616dd5b20e3c3",
    #         guild_certificate_address
    #     ],
    #     alias="guild")
    # print(guild_abi, guild_address)
    test_nft_address, test_nft_abi = nre.deploy(
        "TestNFT", 
        arguments=[
            str(str_to_felt("Test NFT")),
            str(str_to_felt("TNFT")),
            "0x0342732d1e1b6deb415d06154b7339c73bf8a6a1ba347208f71616dd5b20e3c3",
        ],
        alias="test_nft_2")
    print(test_nft_abi, test_nft_address)

    # guild_certificate_address = "0x03840a86c21d02cb182ee63fe34097a3934f958ee948a36a4d8d06fd8f08337a"
    # guild_address = "0x0544ca787ac6f35fe1196badf06c4b247ea04ad3da10035d021ef05af86708c0"
    # test_nft = "0x05215426511f653271f75fb1995157b8b4703691a62bd648044125cd9bb02284"

    # command = [
    #     "starknet",
    #     "call",
    #     "--address",
    #     "0x0342732d1e1b6deb415d06154b7339c73bf8a6a1ba347208f71616dd5b20e3c3",
    #     "--abi",
    #     "/Users/supsam/Documents/cairo/game_guilds/artifacts/abis/Account.json",
    #     "--function",
    #     "get_nonce",
    # ]

    # # command.append("--feeder_gateway_url=http://127.0.0.1:5000/")
    # command.append("--network=alpha-goerli")


    # nonce = int(subprocess.check_output(command).strip().decode("utf-8"))
    
    # print("nonce:",nonce)

    # (call_array, calldata, sig_r, sig_s) = sign_transaction(
    #         sender="0x0342732d1e1b6deb415d06154b7339c73bf8a6a1ba347208f71616dd5b20e3c3", 
    #         calls=[[guild_certificate_address, "transfer_ownership", [int(guild_address, 0)]]], nonce=nonce
    #     )

    # params = []
    # params.append(str(len(call_array)))
    # params.extend([str(elem) for sublist in call_array for elem in sublist])
    # params.append(str(len(calldata)))
    # params.extend([str(param) for param in calldata])
    # params.append(str(nonce))

    # print(params)


    # command = [
    #     "starknet",
    #     "invoke",
    #     "--address",
    #     "0x0342732d1e1b6deb415d06154b7339c73bf8a6a1ba347208f71616dd5b20e3c3",
    #     "--abi",
    #     "/Users/supsam/Documents/cairo/game_guilds/artifacts/abis/Account.json",
    #     "--function",
    #     "__execute__",
    # ]

    # # command.append("--gateway_url=http://127.0.0.1:5000/")
    # command.append("--network=alpha-goerli")

    # command.append("--inputs")
    # command.extend(params)

    # command.append("--signature")
    # command.extend([str(sig_r), str(sig_s)])

    # val= subprocess.check_output(command).strip().decode("utf-8")
    
    # print(val)    


