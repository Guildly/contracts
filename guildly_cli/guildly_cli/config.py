""""
This file hold all high-level config parameters

Use:
from guildly_cli.guildly_cli.config import Config

... = Config.NILE_NETWORK
"""
from nile import deployments
from enum import auto


class ContractAlias(auto):
    GuildManager = 'GuildManager'
    Certificate = 'Certificate'

def safe_load_deployment(alias: str, network: str):
    """Safely loads address from deployments file"""
    try:
        address, _ = next(deployments.load(alias, network))
        print(f"Found deployment for alias {alias}.")
        return address, _
    except StopIteration:
        print(f"Deployment for alias {alias} not found.")
        return None, None


def safe_load_declarations(alias: str, network: str):
    """Safely loads address from declarations file"""
    try:
        class_hash = next(deployments.load_class(alias, network))
        print(f"Found declaration for alias {alias}.")
        return class_hash
    except StopIteration:
        print(f"Decleration for alias {alias} not found.")
        return None


class Config:
    def __init__(self, nile_network: str):
        self.nile_network = "127.0.0.1" if nile_network == "localhost" else nile_network

        self.MAX_FEE = 1282666338551926

        # self.CAIRO_PATH = 

        self.Guild_alias = "proxy_" + ContractAlias.GuildManager
        self.Certificate_alias = "proxy_" + ContractAlias.Certificate

        self.USER_ALIAS = "STARKNET_PRIVATE_KEY"
        self.USER_ADDRESS, _ = safe_load_deployment(
            "account-0", self.nile_network)

        self.GUILD_MANAGER_PROXY, _ = safe_load_deployment(
            "proxy_GuildManager", self.nile_network
        )

        self.CERTIFICATE_PROXY, _ = safe_load_deployment(
            "proxy_Certificate", self.nile_network
        )

        self.PROXY_CLASS_HASH = safe_load_declarations(
            "proxy", self.nile_network
        )

        self.GUILD_CLASS_HASH = safe_load_declarations(
            "guild_contract", self.nile_network
        )