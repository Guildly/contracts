%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from contracts.lib.role import GuildRoles
from contracts.lib.token_standard import TokenStandard

from tests.protostar.setup.setup import Contracts, deploy_all
from tests.protostar.setup.interfaces import Guild

@external
func __setup__{
    syscall_ptr: felt*, range_check_ptr
}() {
    alloc_locals;
    let addresses: Contracts = deploy_all();

    %{
        context.account1 = ids.addresses.account1
        context.account2 = ids.addresses.account2
        context.account3 = ids.addresses.account3
        context.guild_address = ids.addresses.guild
        context.test_nft_address = ids.addresses.test_nft
        context.game_address = ids.addresses.game_contract
    %}

    return ();
}


@external
func test_add_members{
    syscall_ptr: felt*, range_check_ptr
}() {
    alloc_locals;
    local account1;
    local account2;
    local account3;
    local guild_address;

    %{
        ids.account1 = context.account1
        ids.account2 = context.account2
        ids.account3 = context.account3
        ids.guild_address = context.guild_address
        stop_prank = start_prank(ids.account1, ids.guild_address)
    %}
    Guild.whitelist_member(guild_address, account2, GuildRoles.ADMIN);
    Guild.whitelist_member(guild_address, account3, GuildRoles.OWNER);
    %{
        stop_prank()
        stop_prank = start_prank(ids.account2, ids.guild_address)
    %}
    Guild.join(guild_address);
    %{
        stop_prank()
        stop_prank = start_prank(ids.account3, ids.guild_address)
    %}
    Guild.join(guild_address);
    %{
        stop_prank()
    %}
    return ();
}

@external
func test_permissions{
    syscall_ptr: felt*, range_check_ptr
}() {
    alloc_locals;
    local account1;
    local account2;
    local account3;
    local guild_address;
    local test_nft_address;
    local game_address;

    %{
        ids.account1 = context.account1
        ids.account2 = context.account2
        ids.account3 = context.account3
        ids.guild_address = context.guild_address
        ids.test_nft_address = context.test_nft_address
        ids.game_address = context.game_address
        stop_prank_guild = start_prank(ids.account1, ids.guild_address)
        stop_prank_test_nft = start_prank(ids.account1, ids.test_nft_address)
    %}

    TestNft.mint(test_nft_address, account1, Uint256(1, 0));
    TestNft.approve(test_nft_address, guild_address, Uint256(1, 0);
    Guild.deposit(guild_address, TokenStandard.ERC721, test_nft_address, Uint256(1, 0), Uint256(1, 0));
    Guild.initialize_permissions(
        guild_address, 
        2, 
        game_address, 
        get_selector_from_name("kill_goblin"), 
        test_nft_address, 
        get_selector_from_name("symbol")
    );
    let (calls: Call*) = alloc();
    assert calls[0] = Call(
        game_contract.contract_address,
        "kill_goblin",
        []
    )
    (call_array: CallArray, calldata: felt*) = from_call_to_call_array(calls)

    Guild.execute_transactions(
        guild_address,
        call_array_len,
        call_array,
        calldata_len,
        calldata
    );

    let (kill_count) = Game.get_goblin_kill_count(game_address);
    assert kill_count = 1;
    return();
}