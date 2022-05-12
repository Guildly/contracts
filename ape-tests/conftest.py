import pytest
from ape import accounts, project


@pytest.fixture(scope="session")
def account():
    container = accounts.containers["starknet"]
    return container.deploy_account("TEST")


@pytest.fixture(scope="session")
def token_gated_account():
    return project.TokenGatedAccount.deploy(
        str_to_felt("Test Account"),
        str_to_felt("TACC"),
        signer.public_key,
    )
