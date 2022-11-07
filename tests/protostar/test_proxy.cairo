%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from tests.protostar.setup.setup import deploy_all

@external
func test_add_members{
    syscall_ptr: felt*, range_check_ptr
}() {
    let addresses: Contracts = deploy_all();

    
}

@external
func test_permissions{
    syscall_ptr: felt*, range_check_ptr
}() {
    let addresses: Contracts = deploy_all();


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
}