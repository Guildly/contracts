from nile.core.call_or_invoke import call_or_invoke

def send(self, to, method, calldata, nonce=None):
    calldata = [[int(x) for x in c] for c in calldata]

    if nonce is None:
        nonce = int(
            call_or_invoke(self.address, "call", "get_nonce", [], self.network)
        )

    (call_array, calldata, sig_r, sig_s) = self.signer.sign_transaction(
        sender=self.address,
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
        contract=self.address,
        type="invoke",
        method="__execute__",
        params=params,
        network=self.network,
        signature=[str(sig_r), str(sig_s)],
        max_fee='8989832783197500',
    )