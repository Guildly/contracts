"""Guilds test file."""
import pytest
import asyncio
import os

from starkware.starknet.business_logic.state.state import BlockInfo
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract
from starkware.starkware_utils.error_handling import StarkException
from tests.pytest.utils.TransactionSender import (
    TransactionSender,
    from_call_to_call_array,
)
from tests.pytest.utils.Signer import Signer
from tests.pytest.utils.utilities import str_to_felt, to_uint

GUILD_CONTRACT = os.path.join("contracts", "guild_contract.cairo")
GUILD_CONTRACT_UPGRADE = os.path.join(
    "contracts/proxy_upgrade", "guild_contract_upgrade.cairo"
)
GUILD_MANAGER = os.path.join("contracts", "guild_manager.cairo")
GUILD_CERTIFICATE = os.path.join("contracts", "guild_certificate.cairo")
POINTS_CONTRACT = os.path.join("contracts", "experience_points.cairo")
GAME_CONTRACT = os.path.join("contracts", "game_contract.cairo")
TEST_NFT = os.path.join("contracts", "test_nft.cairo")
PROXY = os.path.join("contracts", "proxy.cairo")

signer1 = Signer(123456789987654321)
signer2 = Signer(987654321123456789)
signer3 = Signer(567899876512344321)

CONTRACTS_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "contracts")
OZ_CONTRACTS_PATH = os.path.join(
    os.path.dirname(__file__), "..", "..", "lib", "cairo_contracts", "src"
)
here = os.path.abspath(os.path.dirname(__file__))

CAIRO_PATH = [CONTRACTS_PATH, OZ_CONTRACTS_PATH, here]

def set_block_number(self, starknet, block_number):
    starknet.state.state.block_info = BlockInfo(
        block_number,
        self.block_info.block_timestamp,
        self.block_info.gas_price,
        self.block_info.sequencer_address,
    )

def set_block_timestamp(self, starknet, block_timestamp):
    starknet.state.state.block_info = BlockInfo(
        self.block_info.block_number,
        block_timestamp,
        self.block_info.gas_price,
        self.block_info.sequencer_address,
    )

@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()


@pytest.fixture(scope="module")
async def contract_factory():
    starknet = await Starknet.empty()
    account1 = await starknet.deploy(
        "openzeppelin/account/presets/Account.cairo",
        cairo_path=CAIRO_PATH,
        constructor_calldata=[signer1.public_key],
    )
    account2 = await starknet.deploy(
        "openzeppelin/account/presets/Account.cairo",
        cairo_path=CAIRO_PATH,
        constructor_calldata=[signer2.public_key],
    )
    account3 = await starknet.deploy(
        "openzeppelin/account/presets/Account.cairo",
        cairo_path=CAIRO_PATH,
        constructor_calldata=[signer3.public_key],
    )
    guild_contract_class_hash = await starknet.declare(
        source=GUILD_CONTRACT,
        cairo_path=CAIRO_PATH,
    )
    guild_manager_class_hash = await starknet.declare(
        source=GUILD_MANAGER,
        cairo_path=CAIRO_PATH,
    )
    guild_certificate_class_hash = await starknet.declare(
        source=GUILD_CERTIFICATE,
        cairo_path=CAIRO_PATH,
    )
    guild_proxy_class_hash = await starknet.declare(
        source=PROXY,
        cairo_path=CAIRO_PATH,
    )

    guild_manager_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            guild_manager_class_hash.class_hash,
        ],
    )

    sender = TransactionSender(account1)

    await sender.send_transaction(
        [
            (
                guild_manager_proxy.contract_address,
                "initializer",
                [
                    guild_proxy_class_hash.class_hash,
                    guild_contract_class_hash.class_hash,
                    account1.contract_address,
                ],
            )
        ],
        [signer1],
    )

    guild_certificate_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            guild_certificate_class_hash.class_hash,
        ],
    )

    await sender.send_transaction(
        [
            (
                guild_certificate_proxy.contract_address,
                "initializer",
                [
                    str_to_felt("Guild certificate"),
                    str_to_felt("GC"),
                    guild_manager_proxy.contract_address,
                    account1.contract_address,
                ],
            )
        ],
        [signer1],
    )

    execution_info = await sender.send_transaction(
        [
            (
                guild_manager_proxy.contract_address,
                "deploy_guild",
                [str_to_felt("Test Guild"), guild_certificate_proxy.contract_address],
            )
        ],
        [signer1],
    )

    guild_proxy_address = execution_info.call_info.retdata[1]

    guild_contract_proxy = await starknet.deploy(
        source=PROXY,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            guild_contract_class_hash.class_hash,
        ],
    )

    guild_proxy = StarknetContract(
        state=starknet.state,
        abi=guild_proxy_class_hash.abi,
        contract_address=guild_proxy_address,
        deploy_call_info=guild_contract_proxy.deploy_call_info,
    )

    test_nft = await starknet.deploy(
        source=TEST_NFT,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            str_to_felt("Test NFT"),
            str_to_felt("TNFT"),
            account1.contract_address,
        ],
    )

    test_nft_2 = await starknet.deploy(
        source=TEST_NFT,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            str_to_felt("Test NFT"),
            str_to_felt("TNFT"),
            account1.contract_address,
        ],
    )

    points_contract = await starknet.deploy(
        source=POINTS_CONTRACT,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            str_to_felt("Experience Points"),
            str_to_felt("EP"),
            18,
            *to_uint(0),
            account1.contract_address,
            account1.contract_address,
        ],
    )

    game_contract = await starknet.deploy(
        source=GAME_CONTRACT,
        cairo_path=CAIRO_PATH,
        constructor_calldata=[
            test_nft.contract_address,
            points_contract.contract_address,
        ],
    )

    return (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract,
    )

@pytest.mark.asyncio
async def test_adding_members(contract_factory):
    """Test adding members to guild."""
    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract,
    ) = contract_factory

    sender = TransactionSender(account1)

    await sender.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "add_member",
                [account2.contract_address, 7],
            ),
            (
                guild_proxy.contract_address,
                "add_member",
                [account3.contract_address, 3],
            ),
        ],
        [signer1],
    )


@pytest.mark.asyncio
async def test_permissions(contract_factory):
    """Test setting permissions in the guild."""
    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract,
    ) = contract_factory

    sender = TransactionSender(account1)

    await sender.send_transaction(
        [
            (
                test_nft.contract_address,
                "mint",
                [account1.contract_address, *to_uint(1)],
            )
        ],
        [signer1]
    )

    await sender.send_transaction(
        [
            (
                test_nft.contract_address,
                "approve",
                [guild_proxy.contract_address, *to_uint(1)],
            )
        ],
        [signer1]
    )

    await sender.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "deposit",
                [
                    1,
                    test_nft.contract_address,
                    *to_uint(1),
                    *to_uint(1)
                ],
            )
        ],
        [signer1]
    )

    await sender.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "initialize_permissions",
                [
                    2,
                    game_contract.contract_address,
                    get_selector_from_name("kill_goblin"),
                    test_nft.contract_address,
                    get_selector_from_name("symbol")
                ],
            )
        ],
        [signer1]
    )

    calls = [(
        game_contract.contract_address,
        "kill_goblin",
        []
    )]

    (call_array, calldata) = from_call_to_call_array(calls)

    await sender.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "execute_transactions",
                [
                    len(call_array),
                    *[x for t in call_array for x in t],
                    len(calldata),
                    *calldata,
                    0
                ],
            )
        ],
        [signer1]
    )

    execution_info = await game_contract.get_goblin_kill_count(
        guild_proxy.contract_address
    ).call()
    assert execution_info.result == (1,)

    with pytest.raises(StarkException):

        await sender.send_transaction(
            [
                (
                    guild_proxy.contract_address,
                    "initialize_permissions",
                    [
                        1,
                        test_nft.contract_address,
                        get_selector_from_name("name"),
                    ],
                )
            ],
            [signer1]
        )

@pytest.mark.asyncio
async def test_non_permissioned(contract_factory):
    """Test calling function that has not been permissioned."""
    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract,
    ) = contract_factory

    calls = [(
        test_nft.contract_address,
        "name",
        [0]
    )]

    (call_array, calldata) = from_call_to_call_array(calls)

    sender = TransactionSender(account1)

    with pytest.raises(StarkException):
        await sender.send_transaction(
            [
                (
                    guild_proxy.contract_address,
                    "execute_transactions",
                    [
                        len(call_array),
                        *[x for t in call_array for x in t],
                        len(calldata),
                        *calldata,
                        0
                    ],
                )
            ],
            [signer1]
        )

@pytest.mark.asyncio
async def test_deposit_and_withdraw(contract_factory):
    """Test deposit and withdraw owned asset."""
    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract,
    ) = contract_factory

    calls = [
        (
            test_nft.contract_address,
            "mint",
            [account1.contract_address, *to_uint(2)]
        ),
        (
            test_nft.contract_address,
            "mint",
            [account1.contract_address, *to_uint(3)]
        ),
        (
            test_nft_2.contract_address,
            "mint",
            [account1.contract_address, *to_uint(1)]
        ),
        (
            test_nft.contract_address,
            "approve",
            [guild_proxy.contract_address, *to_uint(2)]
        ),
        (
            test_nft.contract_address,
            "approve",
            [guild_proxy.contract_address, *to_uint(3)]
        ),
        (
            test_nft_2.contract_address,
            "approve",
            [guild_proxy.contract_address, *to_uint(1)]
        ),
        (
            guild_proxy.contract_address,
            "deposit",
            [
                1,
                test_nft.contract_address,
                *to_uint(2),
                *to_uint(1)
            ]
        ),
        (
            guild_proxy.contract_address,
            "deposit",
            [
                1,
                test_nft.contract_address,
                *to_uint(3),
                *to_uint(1)
            ]
        ),
        (
            guild_proxy.contract_address,
            "deposit",
            [
                1,
                test_nft_2.contract_address,
                *to_uint(1),
                *to_uint(1)
            ]
        ),
    ]

    sender = TransactionSender(account1)

    await sender.send_transaction(
        calls,
        [signer1]
    )

    execution_info = await sender.send_transaction(
        [
            (
                guild_certificate_proxy.contract_address,
                "get_certificate_id",
                [
                    account1.contract_address,
                    guild_proxy.contract_address
                ]
            )
        ],
        [signer1]
    )

    certificate_id = execution_info.call_info.retdata[1]

    execution_info = await sender.send_transaction(
        [
            (
                guild_certificate_proxy.contract_address,
                "get_token_amount",
                [
                    *to_uint(certificate_id),
                    1,
                    test_nft.contract_address,
                    *to_uint(2)
                ]
            )
        ],
        [signer1]
    )

    amount = execution_info.call_info.retdata[1]

    assert to_uint(amount) == to_uint(1)

    execution_info = await sender.send_transaction(
        [
            (
                guild_certificate_proxy.contract_address,
                "get_tokens",
                [
                    *to_uint(certificate_id),
                ]
            )
        ],
        [signer1]
    )

    amount = execution_info.call_info.retdata[4]

    assert to_uint(amount) == to_uint(1)

    calls = [
        (
            guild_proxy.contract_address,
            "withdraw",
            [
                1,
                test_nft.contract_address,
                *to_uint(2),
                *to_uint(1)
            ],
        ),
        (
            guild_proxy.contract_address,
            "withdraw",
            [
                1,
                test_nft.contract_address,
                *to_uint(3),
                *to_uint(1)
            ],
        ),
        (
            guild_proxy.contract_address,
            "withdraw",
            [
                1,
                test_nft_2.contract_address,
                *to_uint(1),
                *to_uint(1)
            ],
        )
    ]

    await sender.send_transaction(
        calls,
        [signer1]
    )

    execution_info = await sender.send_transaction(
        [
            (
                guild_certificate_proxy.contract_address,
                "get_token_amount",
                [
                    *to_uint(certificate_id),
                    1,
                    test_nft.contract_address,
                    *to_uint(2)
                ]
            )
        ],
        [signer1]
    )

    amount = execution_info.call_info.retdata[1]

    assert to_uint(amount) == to_uint(0)

    execution_info = await sender.send_transaction(
        [
            (
                guild_certificate_proxy.contract_address,
                "get_tokens",
                [
                    *to_uint(certificate_id),
                ]
            )
        ],
        [signer1]
    )

    # Check amount on token_id 2 is 0 in the array

    amount = execution_info.call_info.retdata[12]

    assert to_uint(amount) == to_uint(0)


@pytest.mark.asyncio
async def test_withdraw_non_held(contract_factory):
    """Test whether withdrawing non deposited nft fails."""
    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract,
    ) = contract_factory

    sender = TransactionSender(account1)

    with pytest.raises(StarkException):
        await sender.send_transaction(
            [
                (
                    guild_proxy.contract_address,
                    "withdraw",
                    [
                        1,
                        test_nft.contract_address,
                        *to_uint(2),
                        *to_uint(1)
                    ],
                )
            ],
            [signer1]
        )

@pytest.mark.asyncio
async def test_multicall(contract_factory):
    """Test executing a multicall from account."""
    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract,
    ) = contract_factory

    sender = TransactionSender(account1)

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

    await sender.send_transaction(
        calls,
        [signer1]
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

    await sender.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "execute_transactions",
                [
                    len(call_array),
                    *[x for t in call_array for x in t],
                    len(calldata),
                    *calldata,
                    1
                ],
            )
        ],
        [signer1]
    )

@pytest.mark.asyncio
async def test_remove_with_items(contract_factory):
    """Test removing a member who has items in the guild."""
    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract,
    ) = contract_factory

    sender1 = TransactionSender(account1)
    sender2 = TransactionSender(account2)
    sender3 = TransactionSender(account3)

    await sender3.send_transaction(
        [
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
        ],
        [signer3]
    )

    await sender2.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "remove_member",
                [
                    account3.contract_address,
                ],
            )
        ],
        [signer2]
    )

    execution_info = await sender1.send_transaction(
        [
            (
                guild_certificate_proxy.contract_address,
                "get_certificate_id",
                [
                    account3.contract_address,
                    guild_proxy.contract_address
                ]
            )
        ],
        [signer1]
    )

    certificate_id = execution_info.call_info.retdata[1]

    execution_info = await sender1.send_transaction(
        [
            (
                guild_certificate_proxy.contract_address,
                "get_token_amount",
                [
                    *to_uint(certificate_id),
                    1,
                    test_nft.contract_address,
                    *to_uint(5)
                ]
            )
        ],
        [signer1]
    )

    amount = execution_info.call_info.retdata[1]

    assert to_uint(amount) == to_uint(0)

@pytest.mark.asyncio
async def add_multiple_ERC721(contract_factory):
    """Test adding more than one ERC721 token."""

    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract,
    ) = contract_factory

    sender = TransactionSender(account3)

    with pytest.raises(StarkException):
        await sender.send_transaction(
            [
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
            ],
            [signer3]
        )

@pytest.mark.asyncio
async def test_withdraw_out_of_many(contract_factory):
    """Test withdrawing a token out of many tokens that have been deposited."""

    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract,
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

    sender = TransactionSender(account1)

    await sender.send_transaction(
        calls,
        [signer1]
    )

    await sender.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "withdraw",
                [
                    1,
                    test_nft.contract_address,
                    *to_uint(8),
                    *to_uint(1)
                ],
            )
        ],
        [signer1]
    )

@pytest.mark.asyncio
async def test_update_role(contract_factory):
    """Test updating role of whitelisted member."""
    (
        starknet,
        account1,
        account2,
        account3,
        guild_manager_proxy,
        guild_certificate_proxy,
        guild_proxy,
        test_nft,
        test_nft_2,
        game_contract,
    ) = contract_factory
    
    sender1 = TransactionSender(account1)
    sender3 = TransactionSender(account3)

    await sender1.send_transaction(
        [
            (
                guild_proxy.contract_address,
                "update_roles",
                [account3.contract_address, 1],
            )
        ],
        [signer1]
    )

    await sender3.send_transaction(
        [
            (
                test_nft.contract_address,
                "mint",
                [account3.contract_address, *to_uint(10)],
            )
        ],
        [signer3]
    )

    await sender3.send_transaction(
        [
            (
                test_nft.contract_address,
                "approve",
                [guild_proxy.contract_address, *to_uint(10)],
            )
        ],
        [signer3]
    )
