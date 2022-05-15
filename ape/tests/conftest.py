import pytest
from ape import accounts, project
from utils import str_to_felt, Signer

signer = Signer(123456789987654321)

@pytest.fixture(scope="session")
def account():
    container = accounts.containers["starknet"]
    return container.deploy_account("TEST")

@pytest.fixture(scope="session")
def guild_certificate(account):
    return project.GuildCerficate.deploy(
        str_to_felt("Test Guild Certificate"),
        str_to_felt("TGC"),
        account
    )


@pytest.fixture(Ascope="session")
def guild(account, guild_certificate):
    return project.GuildAccount.deploy(
        account,
        guild_certificate
    )
