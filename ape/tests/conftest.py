import pytest
from ape import accounts, project
from utils import str_to_felt

@pytest.fixture(scope="session")
def account():
    container = accounts.containers["starknet"]
    return container.deploy_account("TEST")

@pytest.fixture(scope="session")
def guild_certificate(account):
    return project.GuildCertificate.deploy(
        str_to_felt("Test Guild Certificate"),
        str_to_felt("TGC"),
        account
    )


@pytest.fixture(scope="session")
def guild(account, guild_certificate):
    return project.GuildContract.deploy(
        str_to_felt("Test Guild Contract"),
        account,
        guild_certificate
    )
