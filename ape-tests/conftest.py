import pytest
from ape import accounts
from utils import str_to_felt


@pytest.fixture(scope="session")
def account():
    container = accounts.containers["starknet"]
    return container.deploy_account("TEST")


# @pytest.fixture(scope="session")
# def token_gated_account_contract_type(project):
#     return project.token_gated_account


# @pytest.fixture(scope="session")
# def token_gated_account(token_gated_account_contract_type, account):
#     return token_gated_account_contract_type.deploy(
#         str_to_felt("Test Account")
#         str_to_felt("TACC")
#         account.public_key
#     )
