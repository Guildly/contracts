import time
from starkware.starknet.public.abi import get_selector_from_name

from guildly_cli.scripts.caller_invoke import wrapped_send, wrapped_declare
from guildly_cli.guildly_cli.config import Config
from guildly_cli.guildly_cli.utlis import to_uint, str_to_felt, strhex_as_strfelt

def from_call_to_call_array(calls):
    """Transform from Call to CallArray."""
    call_array = []
    calldata = []
    for _, call in enumerate(calls):
        assert len(call) == 3, "Invalid call parameters"
        entry = (
            int(call[0], 16),
            get_selector_from_name(call[1]),
            len(calldata),
            len(call[2]),
        )
        call_array.append(entry)
        calldata.extend(call[2])
    return (call_array, calldata)


def run(nre):

    config = Config(nre.network)

    # proxy_class_hash = wrapped_declare("STARKNET_PRIVATE_KEY", "proxy", nre.network, alias="proxy")
    # guild_contract_class_hash = wrapped_declare("STARKNET_PRIVATE_KEY", "guild_contract", nre.network, alias="guild_contract")
    # guild_manager_class_hash = wrapped_declare("STARKNET_PRIVATE_KEY", "guild_manager", nre.network, alias="guild_manager")
    # guild_certificate_class_hash = wrapped_declare("STARKNET_PRIVATE_KEY", "guild_certificate", nre.network, alias="guild_certificate")

    # guild_proxy_manager_address, guild_proxy_manager_abi = nre.deploy(
    #     "proxy",
    #     arguments=[
    #         guild_manager_class_hash,
    #     ],
    #     alias="proxy_GuildManager"
    # )

    # print(guild_proxy_manager_abi, guild_proxy_manager_address)

    # guild_proxy_certificate_address, guild_proxy_certificate_abi = nre.deploy(
    #     "proxy",
    #     arguments=[
    #         guild_certificate_class_hash,
    #     ],
    #     alias="proxy_Certificate",
    # )

    # print(guild_proxy_certificate_abi, guild_proxy_certificate_address)

    # # wait 120s - this will reduce on mainnet
    # print('🕒 Waiting for deploy before invoking')
    # time.sleep(120)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_GuildManager",
        function="initializer", 
        arguments=[
            config.PROXY_CLASS_HASH,
            config.GUILD_CLASS_HASH,
            config.USER_ADDRESS
        ]
    )

    wrapped_send(
        config.nile_network,
        config.USER_ALIAS,
        "proxy_Certificate",
        "initializer", 
        arguments=[
            str(str_to_felt("Guild Certificate")),
            str(str_to_felt("GC")),
            config.GUILD_MANAGER_PROXY,
            config.USER_ADDRESS
        ],
    )

    # test_nft_address, test_nft_abi = nre.deploy(
    #     "test_nft",
    #     arguments=[
    #         str(str_to_felt("Test NFT")),
    #         str(str_to_felt("TNFT")),
    #         config.USER_ADDRESS,
    #     ],
    #     alias="test_nft"
    # )
    # print(test_nft_abi, test_nft_address)
    # points_contract_address, points_abi = nre.deploy(
    #     "experience_points",
    #     arguments=[
    #         str(str_to_felt("Experience Points")),
    #         str(str_to_felt("EP")),
    #         "18",
    #         str(0),
    #         str(0),
    #         config.USER_ADDRESS,
    #         config.USER_ADDRESS,
    #     ],
    #     alias="points_contract"
    # )
    # print(points_abi, points_contract_address)
    # test_game_contract_address, test_game_abi = nre.deploy(
    #     "game_contract", 
    #     arguments=[
    #         test_nft_address, 
    #         points_contract_address
    #     ],
    #     alias="game_contract"
    # )
    # print(test_game_abi, test_game_contract_address)
