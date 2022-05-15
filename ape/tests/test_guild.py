from ape import accounts, project
from utils import str_to_felt, Signer

signer = Signer(123456789987654321)


def test_guild(guild):
    signer.send_transaction()
    assert 1 == 2


# def test_revert_non_holder(token_gated_account, test_nft):
#     token_gated_account
