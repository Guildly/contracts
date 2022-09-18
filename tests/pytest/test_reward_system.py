"""GuildManager.cairo test file."""
import pytest
import asyncio
import os

from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract
from starkware.starkware_utils.error_handling import StarkException
from utils import (
    str_to_felt,
    to_uint,
    Signer,
    from_call_to_call_array
)

GUILD_CONTRACT = os.path.join("contracts", "GuildContractNew.cairo")
GUILD_MANAGER = os.path.join("contracts", "GuildManager.cairo")
GUILD_CERTIFICATE = os.path.join("contracts", "GuildCertificate.cairo")
POINTS_CONTRACT = os.path.join("contracts", "ExperiencePoints.cairo")
GAME_CONTRACT = os.path.join("contracts", "GameContract.cairo")
TEST_NFT = os.path.join("contracts", "TestNFT.cairo")
GUILD_PROXY = os.path.join("contracts", "Proxy.cairo")

signer1 = Signer(123456789987654321)
signer2 = Signer(987654321123456789)
signer3 = Signer(567899876512344321)


@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope="module")
async def contract_factory():
    starknet = await Starknet.empty()
    account1 = await starknet.deploy(
        "openzeppelin/account/Account.cairo",
        constructor_calldata=[signer1.public_key]
    )
    account2 = await starknet.deploy(
        "openzeppelin/account/Account.cairo",
        constructor_calldata=[signer2.public_key]
    )
    account3 = await starknet.deploy(
        "openzeppelin/account/Account.cairo",
        constructor_calldata=[signer3.public_key]
    )
    guild_contract_class_hash = await starknet.declare(
        source=GUILD_CONTRACT
    )
    guild_proxy_class_hash = await starknet.declare(
        source=GUILD_PROXY
    )
    guild_manager = await starknet.deploy(
        source=GUILD_MANAGER,
        constructor_calldata=[
            guild_proxy_class_hash.class_hash,
            guild_contract_class_hash.class_hash
        ]
    )
    guild_certificate = await starknet.deploy(
        source=GUILD_CERTIFICATE,
        constructor_calldata=[
            str_to_felt("Guild certificate"),
            str_to_felt("GC"),
            guild_manager.contract_address
        ],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_manager.contract_address,
        selector_name="deploy_guild_proxy_contract",
        calldata=[
            str_to_felt("Test Guild"),
            guild_certificate.contract_address
        ]
    )

    execution_info = await guild_manager.get_guild_contracts().call()
    guild_proxy_address = execution_info.result.guilds[0]

    deployed_proxy = await starknet.deploy(
        source=GUILD_PROXY, 
        constructor_calldata=[            
            guild_contract_class_hash.class_hash,
            get_selector_from_name("initialize"),
            3,
            str_to_felt("Test Guild"),
            account1.contract_address,
            guild_certificate.contract_address
        ]
    )

    guild_proxy = StarknetContract(
        state=starknet.state,
        abi=guild_proxy_class_hash.abi,
        contract_address=guild_proxy_address,
        deploy_execution_info=deployed_proxy.deploy_execution_info
    )

    test_nft = await starknet.deploy(
        source=TEST_NFT,
        constructor_calldata=[
            str_to_felt("Test NFT"),
            str_to_felt("TNFT"),
            account1.contract_address,
        ],
    )

    
    test_nft_2 = await starknet.deploy(
        source=TEST_NFT,
        constructor_calldata=[
            str_to_felt("Test NFT"),
            str_to_felt("TNFT"),
            account1.contract_address,
        ],
    )

    points_contract = await starknet.deploy(
        source=POINTS_CONTRACT, constructor_calldata=[
            str_to_felt("Experience Points"),
            str_to_felt("EP"),
            18,
            *to_uint(0),
            account1.contract_address,
            account1.contract_address
        ]
    )

    game_contract = await starknet.deploy(
        source=GAME_CONTRACT, constructor_calldata=[
            test_nft.contract_address, 
            points_contract.contract_address
        ]
    )


    return (
        starknet, 
        account1, 
        account2, 
        account3, 
        guild_manager, 
        guild_certificate, 
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract
    )

@pytest.mark.asyncio
async def test_adding_members(contract_factory):
    """Test adding members to guild."""
    (
        starknet, 
        account1, 
        account2, 
        account3, 
        guild_manager, 
        guild_certificate, 
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract
    ) = contract_factory

    await signer1.send_transactions(
        account=account1,
        calls=[
            (
                guild_proxy.contract_address,
                "whitelist_member",
                [account2.contract_address, 3]
            ),
            (
                guild_proxy.contract_address,
                "whitelist_member",
                [account3.contract_address, 2]
            )
        ]
    )

    await signer2.send_transaction(
        account=account2,
        to=guild_proxy.contract_address,
        selector_name="join",
        calldata=[],
    )

    await signer3.send_transaction(
        account=account3,
        to=guild_proxy.contract_address,
        selector_name="join",
        calldata=[],
    )

    await signer2.send_transaction(
        account=account2,
        to=guild_proxy.contract_address,
        selector_name="leave",
        calldata=[],
    )

@pytest.mark.asyncio
async def test_permissions(contract_factory):
    """Test setting permissions in the guild."""
    (
        starknet, 
        account1, 
        account2, 
        account3, 
        guild_manager, 
        guild_certificate, 
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract
    ) = contract_factory

    await signer1.send_transaction(
        account=account1,
        to=test_nft.contract_address,
        selector_name="mint",
        calldata=[account1.contract_address, *to_uint(1)],
    )

    await signer1.send_transaction(
        account=account1,
        to=test_nft.contract_address,
        selector_name="approve",
        calldata=[guild_proxy.contract_address, *to_uint(1)],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_proxy.contract_address,
        selector_name="deposit",
        calldata=[
            1,
            test_nft.contract_address, 
            *to_uint(1),
            *to_uint(1)
        ],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_proxy.contract_address,
        selector_name="initialize_permissions",
        calldata=[
            2,
            game_contract.contract_address,
            get_selector_from_name("kill_goblin"),
            test_nft.contract_address,
            get_selector_from_name("symbol")
        ],
    )
        
    calls = [(
        game_contract.contract_address, 
        "kill_goblin",
        []
    )]

    (call_array, calldata) = from_call_to_call_array(calls)

    await signer1.send_transaction(
        account=account1,
        to=guild_proxy.contract_address,
        selector_name="execute_transactions",
        calldata=[
            len(call_array),
            *[x for t in call_array for x in t],
            len(calldata),
            *calldata,
            0
        ],
    )

    execution_info = await game_contract.get_goblin_kill_count(
        guild_proxy.contract_address
    ).call()
    assert execution_info.result == (1,)

    with pytest.raises(StarkException):
        await signer1.send_transaction(
            account=account1,
            to=guild_proxy.contract_address,
            selector_name="initialize_permissions",
            calldata=[
                1,
                test_nft.contract_address,
                get_selector_from_name("name"),
            ],
        )

@pytest.mark.asyncio
async def test_non_permissioned(contract_factory):
    """Test calling function that has not been permissioned."""
    (
        starknet, 
        account1, 
        account2, 
        account3, 
        guild_manager, 
        guild_certificate, 
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract
    ) = contract_factory

    calls = [(
        test_nft.contract_address, 
        "name",
        [0]
    )]

    (call_array, calldata) = from_call_to_call_array(calls)

    with pytest.raises(StarkException):
        await signer1.send_transaction(
            account=account1,
            to=guild_proxy.contract_address,
            selector_name="execute_transactions",
            calldata=[
                len(call_array),
                *[x for t in call_array for x in t],
                len(calldata),
                *calldata,
                1
            ],
        )


@pytest.mark.asyncio
async def test_deposit_and_withdraw(contract_factory):
    """Test deposit and withdraw owned asset."""
    (
        starknet, 
        account1, 
        account2, 
        account3, 
        guild_manager, 
        guild_certificate, 
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract
    ) = contract_factory

#     calls = [
#     (
#         test_nft.contract_address,
#         "mint",
#         [account1.contract_address, *to_uint(2)]
#     ),
#     (
#         test_nft.contract_address,
#         "mint",
#         [account1.contract_address, *to_uint(3)]
#     ),
#     (
#         test_nft.contract_address,
#         "approve",
#         [account1.contract_address, *to_uint(2)]
#     ),
#     (
#         test_nft.contract_address,
#         "approve",
#         [account1.contract_address, *to_uint(3)]
#     ),
#     (
#         guild_proxy.contract_address,
#         "deposit",
#         [
#             1,
#             test_nft.contract_address, 
#             *to_uint(2),
#             *to_uint(1)
#         ]
#     ),
#     (
#         guild_proxy.contract_address,
#         "deposit",
#         [
#             1,
#             test_nft.contract_address, 
#             *to_uint(3),
#             *to_uint(1)
#         ]
#     )
# ]

# await signer1.send_transactions(
#     account=account1,
#     calls=calls
# )

    await signer1.send_transaction(
        account=account1,
        to=test_nft.contract_address,
        selector_name="mint",
        calldata=[account1.contract_address, *to_uint(2)],
    )

    await signer1.send_transaction(
        account=account1,
        to=test_nft.contract_address,
        selector_name="mint",
        calldata=[account1.contract_address, *to_uint(3)],
    )

    await signer1.send_transaction(
        account=account1,
        to=test_nft_2.contract_address,
        selector_name="mint",
        calldata=[account1.contract_address, *to_uint(1)],
    )

    await signer1.send_transaction(
        account=account1,
        to=test_nft.contract_address,
        selector_name="approve",
        calldata=[guild_proxy.contract_address, *to_uint(2)],
    )

    await signer1.send_transaction(
        account=account1,
        to=test_nft.contract_address,
        selector_name="approve",
        calldata=[guild_proxy.contract_address, *to_uint(3)],
    )

    await signer1.send_transaction(
        account=account1,
        to=test_nft_2.contract_address,
        selector_name="approve",
        calldata=[guild_proxy.contract_address, *to_uint(1)],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_proxy.contract_address,
        selector_name="deposit",
        calldata=[
            1,
            test_nft.contract_address, 
            *to_uint(2),
            *to_uint(1)
        ],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_proxy.contract_address,
        selector_name="deposit",
        calldata=[
            1,
            test_nft.contract_address, 
            *to_uint(3),
            *to_uint(1)
        ],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_proxy.contract_address,
        selector_name="deposit",
        calldata=[
            1,
            test_nft_2.contract_address, 
            *to_uint(1),
            *to_uint(1)
        ],
    )

    execution_info = await guild_certificate.get_certificate_id(
        account1.contract_address,
        guild_proxy.contract_address
    ).call()
    certificate_id = execution_info.result.certificate_id

    execution_info = await guild_certificate.get_token_amount(
        certificate_id,
        1,
        test_nft.contract_address,
        to_uint(2)
    ).call()
    amount = execution_info.result.amount

    assert amount == to_uint(1)

    execution_info = await guild_certificate.get_tokens(
        certificate_id
    ).call()
    amount = execution_info.result.tokens[0].amount
    assert amount == to_uint(1)

    await signer1.send_transaction(
        account=account1,
        to=guild_proxy.contract_address,
        selector_name="withdraw",
        calldata=[
            1,
            test_nft.contract_address, 
            *to_uint(2),
            *to_uint(1)
        ],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_proxy.contract_address,
        selector_name="withdraw",
        calldata=[
            1,
            test_nft.contract_address, 
            *to_uint(3),
            *to_uint(1)
        ],
    )

    await signer1.send_transaction(
        account=account1,
        to=guild_proxy.contract_address,
        selector_name="withdraw",
        calldata=[
            1,
            test_nft_2.contract_address, 
            *to_uint(1),
            *to_uint(1)
        ],
    )

    execution_info = await guild_certificate.get_token_amount(
        certificate_id,
        1,
        test_nft.contract_address,
        to_uint(2)
    ).call()
    amount = execution_info.result.amount

    assert amount == to_uint(0)

    execution_info = await guild_certificate.get_tokens(
        certificate_id
    ).call()
    amount = execution_info.result.tokens[0].amount
    assert amount == to_uint(0)


@pytest.mark.asyncio
async def test_withdraw_non_held(contract_factory):
    """Test whether withdrawing non deposited nft fails."""
    (
        starknet, 
        account1, 
        account2, 
        account3, 
        guild_manager, 
        guild_certificate, 
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract
    ) = contract_factory

    with pytest.raises(StarkException):
        await signer1.send_transaction(
            account=account1,
            to=guild_proxy.contract_address,
            selector_name="withdraw",
            calldata=[            
                1,
                test_nft.contract_address, 
                *to_uint(1),
                *to_uint(1)
            ],
        )

@pytest.mark.asyncio
async def test_multicall(contract_factory):
    """Test executing a multicall from account."""
    (
        starknet, 
        account1, 
        account2, 
        account3, 
        guild_manager, 
        guild_certificate, 
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract
    ) = contract_factory

    calls = [
        (
            test_nft.contract_address,
            "mint",
            [account1.contract_address, *to_uint(4)]
        ),
        (
            test_nft.contract_address,
            "approve",
            [guild_proxy.contract_address, *to_uint(4)] 
        )
    ]

    await signer1.send_transactions(
        account=account1,
        calls=calls,
    )

    calls = [
        (
            game_contract.contract_address,
            "kill_goblin",
            [] 
        ),
        (
            test_nft.contract_address,
            "symbol",
            []
        )
    ]

    (call_array, calldata) = from_call_to_call_array(calls)

    await signer1.send_transaction(
        account=account1,
        to=guild_proxy.contract_address,
        selector_name="execute_transactions",
        calldata=[
            len(call_array),
            *[x for t in call_array for x in t],
            len(calldata),
            *calldata,
            1
        ],
    )

@pytest.mark.asyncio
async def test_remove_with_items(contract_factory):
    """Test removing a member who has items in the guild."""
    (
        starknet, 
        account1, 
        account2, 
        account3, 
        guild_manager, 
        guild_certificate, 
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract
    ) = contract_factory

    await signer3.send_transactions(
        account=account3,
        calls=[
            (
                test_nft.contract_address,
                "mint",
                [account3.contract_address, *to_uint(5)]
            ),
            (
                test_nft.contract_address,
                "approve",
                [guild_proxy.contract_address, *to_uint(5)]
            ),
            (
                guild_proxy.contract_address,
                "deposit",
                [   1,
                    test_nft.contract_address, 
                    *to_uint(5),
                    *to_uint(1)
                ]
            ),
        ]
    )

    execution_info = await guild_certificate.get_certificate_id(
        account3.contract_address,
        guild_proxy.contract_address
    ).call()
    certificate_id = execution_info.result.certificate_id

    await signer2.send_transaction(
        account=account2,
        to=guild_proxy.contract_address,
        selector_name="remove_member",
        calldata=[
            account3.contract_address, 
        ],
    )

    execution_info = await guild_certificate.get_token_amount(
        certificate_id,
        1,
        test_nft.contract_address,
        to_uint(5)
    ).call()
    amount = execution_info.result.amount

    assert amount == to_uint(0)

@pytest.mark.asyncio
async def add_multiple_ERC721(contract_factory):
    """Test adding more than one ERC721 token."""

    (
        starknet, 
        account1, 
        account2, 
        account3, 
        guild_manager, 
        guild_certificate, 
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract
    ) = contract_factory

    with pytest.raises(StarkException):
        await signer3.send_transactions(
            account=account3,
            calls=[
                (
                    test_nft.contract_address,
                    "mint",
                    [account3.contract_address, *to_uint(6)]
                ),
                (
                    test_nft.contract_address,
                    "approve",
                    [guild_proxy.contract_address, *to_uint(6)]
                ),
                (
                    guild_proxy.contract_address,
                    "deposit",
                    [   1,
                        test_nft.contract_address, 
                        *to_uint(6),
                        *to_uint(2)
                    ]
                ),
            ]
        )

@pytest.mark.asyncio
async def test_withdraw_out_of_many(contract_factory):
    """Test withdrawing a token out of many tokens that have been deposited."""

    (
        starknet, 
        account1, 
        account2, 
        account3, 
        guild_manager, 
        guild_certificate, 
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract
    ) = contract_factory

    calls = [
        (
            test_nft.contract_address,
            "mint",
            [account1.contract_address, *to_uint(7)]
        ),
        (
            test_nft.contract_address,
            "mint",
            [account1.contract_address, *to_uint(8)]
        ),
        (
            test_nft.contract_address,
            "mint",
            [account1.contract_address, *to_uint(9)]
        ),
        (
            test_nft.contract_address,
            "approve",
            [guild_proxy.contract_address, *to_uint(7)] 
        ),
        (
            test_nft.contract_address,
            "approve",
            [guild_proxy.contract_address, *to_uint(8)] 
        ),
        (
            test_nft.contract_address,
            "approve",
            [guild_proxy.contract_address, *to_uint(9)] 
        ),
        (
            guild_proxy.contract_address,
            "deposit",
            [
                1,
                test_nft.contract_address, 
                *to_uint(7),
                *to_uint(1)
            ]
        ),
        (
            guild_proxy.contract_address,
            "deposit",
            [
                1,
                test_nft.contract_address, 
                *to_uint(8),
                *to_uint(1)
            ]
        ),
        (
            guild_proxy.contract_address,
            "deposit",
            [
                1,
                test_nft.contract_address, 
                *to_uint(9),
                *to_uint(1)
            ]
        )
    ]

    await signer1.send_transactions(
        account=account1,
        calls=calls
    )

    execution_info = await guild_certificate.get_tokens(to_uint(1)).call()
    print(execution_info.result)

    await signer1.send_transaction(
        account=account1,
        to=guild_proxy.contract_address,
        selector_name="withdraw",
        calldata=[
            1,
            test_nft.contract_address, 
            *to_uint(8),
            *to_uint(1)
        ],
    )

@pytest.mark.asyncio
async def test_update_role(contract_factory):
    """Test updating role of whitelisted member."""
    (
        starknet, 
        account1, 
        account2, 
        account3, 
        guild_manager, 
        guild_certificate, 
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract
    ) = contract_factory

    await signer1.send_transaction(
        account=account1,
        to=guild_proxy.contract_address,
        selector_name="update_role",
        calldata=[account3.contract_address, 1],
    )

    await signer3.send_transaction(
        account=account3,
        to=test_nft.contract_address,
        selector_name="mint",
        calldata=[account3.contract_address, *to_uint(10)],
    )

    await signer3.send_transaction(
        account=account3,
        to=test_nft.contract_address,
        selector_name="approve",
        calldata=[guild_proxy.contract_address, *to_uint(10)],
    )

    with pytest.raises(StarkException):
        await signer3.send_transaction(
            account=account3,
            to=guild_proxy.contract_address,
            selector_name="deposit",
            calldata=[
                1,
                test_nft.contract_address, 
                *to_uint(10),
                *to_uint(1)
            ],
        )
