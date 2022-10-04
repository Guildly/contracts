from nile.core.declare import declare
from nile.common import get_nonce
from starkware.starknet.compiler.compile import compile_starknet_files

def wrapped_declare(account, contract_name, network, alias):
    contract_class = compile_starknet_files(
        files=[f"{'contracts'}/{contract_name}.cairo"], debug_info=True, cairo_path=["/Users/supsam/Documents/cairo/game_guilds/lib/cairo_contracts/src"]
    )
    nonce = get_nonce(account.address, network)
    sig_r, sig_s = account.signer.sign_declare(
        sender=account.address,
        contract_class=contract_class,
        nonce=nonce,
        max_fee=80999285161067,
    )
    class_hash = declare(sender=account.address, contract_name=contract_name, signature=[sig_r, sig_s], alias=alias, network=network, max_fee=80999285161067)
    return class_hash