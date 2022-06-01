from starkware.crypto.signature.signature import private_to_stark_key, sign
from starkware.starknet.core.os.transaction_hash.transaction_hash import (
    TransactionHashPrefix,
    calculate_transaction_hash_common,
)
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.definitions.general_config import StarknetChainId
import subprocess

TRANSACTION_VERSION = 0

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
    guild_certificate_address = "0x02b13b166b3f60af4c099824a12079487daa583b4cae2f7ace2c38980c971e99"
    guild_address = "0x0328e6f96f084a95741a1feec94caed55e176fcedbd3c8284192e32dc93fcdeb"
    test_nft = "0x021416f966fb396dd5e603d6cb07250811b354bf6e421d256fa682f55c9a3073"

    command = [
        "starknet",
        "call",
        "--address",
        "0x0342732d1e1b6deb415d06154b7339c73bf8a6a1ba347208f71616dd5b20e3c3",
        "--abi",
        "/Users/supsam/Documents/cairo/game_guilds/artifacts/abis/Account.json",
        "--function",
        "get_nonce",
    ]

    command.append("--network=alpha-goerli")

    nonce = int(subprocess.check_output(command).strip().decode("utf-8"))
    
    print("nonce:",nonce)

    (call_array, calldata, sig_r, sig_s) = sign_transaction(
            sender="0x0342732d1e1b6deb415d06154b7339c73bf8a6a1ba347208f71616dd5b20e3c3", 
            calls=[[guild_certificate_address, "transfer_ownership", [int(guild_address, 0)]]], nonce=nonce
        )

    params = []
    params.append(str(len(call_array)))
    params.extend([str(elem) for sublist in call_array for elem in sublist])
    params.append(str(len(calldata)))
    params.extend([str(param) for param in calldata])
    params.append(str(nonce))

    print(params)


    command = [
        "starknet",
        "invoke",
        "--address",
        "0x0342732d1e1b6deb415d06154b7339c73bf8a6a1ba347208f71616dd5b20e3c3",
        "--abi",
        "/Users/supsam/Documents/cairo/game_guilds/artifacts/abis/Account.json",
        "--function",
        "__execute__",
    ]

    command.append("--network=alpha-goerli")

    command.append("--inputs")
    command.extend(params)

    command.append("--signature")
    command.extend([str(sig_r), str(sig_s)])

    val= subprocess.check_output(command).strip().decode("utf-8")
    
    print(val)  