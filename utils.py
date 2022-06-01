"""Utilities for testing Cairo contracts."""
import math
from starkware.crypto.signature.signature import private_to_stark_key, sign
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starknet.core.os.transaction_hash.transaction_hash import (
    calculate_transaction_hash_common,
    TransactionHashPrefix,
)
from starkware.starknet.definitions.general_config import StarknetChainId

TRANSACTION_VERSION = 0


def to_uint(a):
    """Takes in value, returns uint256-ish tuple."""
    return (a & ((1 << 128) - 1), a >> 128)


def uint(a):
    return (a, 0)


def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")

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


class Signer:
    """
    Utility for sending signed transactions to an Account on Starknet.
    Parameters
    ----------
    private_key : int
    Examples
    ---------
    Constructing a Signer object
    >>> signer = Signer(1234)
    Sending a transaction
    >>> await signer.send_transaction(account,
                                      account.contract_address,
                                      'set_public_key',
                                      [other.public_key]
                                     )
    """

    def __init__(self, private_key):
        self.private_key = private_key
        self.public_key = private_to_stark_key(private_key)

    def sign(self, message_hash):
        return sign(msg_hash=message_hash, priv_key=self.private_key)

    async def send_transaction(
        self, account, to, selector_name, calldata, nonce=None, max_fee=0
    ):
        return await self.send_transactions(
            account, [(to, selector_name, calldata)], nonce, max_fee
        )

    async def send_transactions(self, account, calls, nonce=None, max_fee=0):
        if nonce is None:
            execution_info = await account.get_nonce().call()
            (nonce,) = execution_info.result

        (call_array, calldata) = from_call_to_call_array(calls)

        message_hash = get_transaction_hash(
            account.contract_address, call_array, calldata, nonce, max_fee
        )
        sig_r, sig_s = self.sign(message_hash)

        return await account.__execute__(call_array, calldata, nonce).invoke(
            signature=[sig_r, sig_s]
        )


def from_call_to_call_array(calls):
    call_array = []
    calldata = []
    for i, call in enumerate(calls):
        assert len(call) == 3, "Invalid call parameters"
        entry = (call[0], get_selector_from_name(call[1]), len(calldata), len(call[2]))
        call_array.append(entry)
        calldata.extend(call[2])
    return (call_array, calldata)


def get_transaction_hash(account, call_array, calldata, nonce, max_fee):
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
