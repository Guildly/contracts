from nile.core.call_or_invoke import call_or_invoke

def send(account, to, method, calldata, nonce=None):
    calldata = [[int(x) for x in c] for c in calldata]

    if nonce is None:
        nonce = int(
            call_or_invoke(account.address, "call", "get_nonce", [], account.network)
        )

    (call_array, calldata, sig_r, sig_s) = account.signer.sign_transaction(
        sender=account.address,
        calls=[[to, method, c] for c in calldata],
        nonce=nonce,
        max_fee='8989832783197500',
    )

    params = []
    params.append(str(len(call_array)))
    params.extend([str(elem) for sublist in call_array for elem in sublist])
    params.append(str(len(calldata)))
    params.extend([str(param) for param in calldata])
    params.append(str(nonce))

    return call_or_invoke(
        contract=account.address,
        type="invoke",
        method="__execute__",
        params=params,
        network=account.network,
        signature=[str(sig_r), str(sig_s)],
        max_fee='8989832783197500',
    )