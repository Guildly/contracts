from ape import accounts, project
from utils import str_to_felt, Signer

signer = Signer(123456789987654321)

# def test_account(account):
#     print(accounts)
#     assert 1 == 2


def test_token_account():
    tokwn_gated_account = project.TokenGatedAccount.deploy(
        str_to_felt("Test Account"),
        str_to_felt("TACC"),
        signer.public_key,
    )
    signer.send_transaction()
    assert 1 == 2


# def test_revert_non_holder(token_gated_account, test_nft):
#     token_gated_account
