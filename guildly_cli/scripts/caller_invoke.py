import re
import subprocess

from nile.core.call_or_invoke import call_or_invoke
from nile.common import get_nonce

def parse_send(x):
    """Extract information from send command."""
    # address is 64, tx_hash is 64 chars long
    try:
        address, tx_hash = re.findall("0x[\\da-f]{1,64}", str(x))
        return address, tx_hash
    except ValueError:
        print(f"could not get tx_hash from message {x}")
    return 0x0, 0x0

def get_tx_status(network, tx_hash: str) -> dict:
    """Returns transaction receipt in dict."""
    command = [
        "nile",
        "debug",
        "--network",
        network,
        tx_hash,
    ]
    out_raw = subprocess.check_output(command).strip().decode("utf-8")
    return out_raw

def wrapped_send(account, to, method, calldata):
    """Send command with some extra functionality such as tx status check and built-in timeout.
    (only supported for non-localhost networks)
    tx statuses:
    RECEIVED -> PENDING -> ACCEPTED_ON_L2
    """
    print("------- SEND ----------------------------------------------------")
    print(f"invoking {method} from {to} with {calldata}")
    out = send(account, to, method, [calldata])
    _, tx_hash = parse_send(out)
    get_tx_status(account.network, tx_hash,)
    print("------- SEND ----------------------------------------------------")

def send(account, to, method, calldata, nonce=None):
    calldata = [[int(x) for x in c] for c in calldata]

    if nonce is None:
        nonce = get_nonce(account.address, account.network)

    (calldata, sig_r, sig_s) = account.signer.sign_transaction(
        sender=account.address,
        calls=[[to, method, c] for c in calldata],
        nonce=nonce,
        max_fee=8989832783197500,
    )

    return call_or_invoke(
        contract=account.address,
        type="invoke",
        method="__execute__",
        params=calldata,
        network=account.network,
        signature=[str(sig_r), str(sig_s)],
        max_fee='8989832783197500',
    )