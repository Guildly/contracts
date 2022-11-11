%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from tests.protostar.realms_setup.helpers import get_resources, get_owners
from tests.protostar.realms_setup.setup import (
    deploy_account,
    deploy_module,
    deploy_controller,
    time_warp,
)
from tests.protostar.realms_setup.interfaces import Realms, Settling, ResourcesToken
from tests.protostar.setup.interfaces import Guild, ResourcesPolicy, PolicyManager
from tests.protostar.setup.setup import deploy_all, Contracts

from contracts.settling_game.utils.game_structs import ModuleIds
from contracts.settling_game.modules.resources.interface import IResources
from contracts.settling_game.modules.settling.interface import ISettling

from contracts.token.constants import (
    IERC1155_ID,
    IERC1155_METADATA_ID,
    IERC1155_RECEIVER_ID,
    IACCOUNT_ID,
    ON_ERC1155_RECEIVED_SELECTOR,
    ON_ERC1155_BATCH_RECEIVED_SELECTOR,
)

const PK = 11111;
const PK2 = 22222;

const CLAIM_RESOURCES_SELECTOR = 74641129835352282747209266803538371422631007050446038804429802040671281965428;

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    // Realms
    local realms_1_data;

    let (local account_1_address) = deploy_account(PK);
    let (local account_2_address) = deploy_account(PK2);
    let (local controller_address) = deploy_controller(account_1_address, account_1_address);
    let (local resources_address) = deploy_module(
        ModuleIds.Resources, controller_address, account_1_address
    );
    let (local resources_token_address) = deploy_module(
        ModuleIds.Resources_Token, controller_address, account_1_address
    );
    let (local realms_address) = deploy_module(
        ModuleIds.Realms_Token, controller_address, account_1_address
    );
    let (local s_realms_address) = deploy_module(
        ModuleIds.S_Realms_Token, controller_address, account_1_address
    );
    let (local settling_address) = deploy_module(
        ModuleIds.Settling, controller_address, account_1_address
    );
    let (local goblintown_address) = deploy_module(
        ModuleIds.GoblinTown, controller_address, account_1_address
    );
    let (local buildings_address) = deploy_module(
        ModuleIds.Buildings, controller_address, account_1_address
    );
    let (local food_address) = deploy_module(
        ModuleIds.L10_Food, controller_address, account_1_address
    );
    let (local calculator_address) = deploy_module(
        ModuleIds.Calculator, controller_address, account_1_address
    );

    let realms_token_id: Uint256 = Uint256(1, 0);
    let realms_name = 'Test 1';

    %{
        from tests.protostar.utils import utils
        stop_prank_realms = start_prank(ids.account_1_address, target_contract_address=ids.realms_address)
        stop_prank_settling = start_prank(ids.account_1_address, target_contract_address=ids.settling_address)
        context.account_1_address = ids.account_1_address
        context.account_2_address = ids.account_2_address
        context.resources_address = ids.resources_address
        context.resources_token_address = ids.resources_token_address
        context.realms_address = ids.realms_address
        context.settling_address = ids.settling_address
        ids.realms_1_data = utils.pack_realm(utils.build_realm_order(4, 5, 2, 1, 4, 2, 8, 13, 6, 0, 0, 0, 0, 4))
    %}
    Realms.set_realm_data(realms_address, realms_token_id, realms_name, realms_1_data);
    Realms.mint(realms_address, account_1_address);
    Realms.approve(realms_address, settling_address, realms_token_id);
    Settling.settle(settling_address, realms_token_id);

    %{
        stop_prank_realms()
        stop_prank_settling()
    %}

    local policy_address;
    // Guilds
    let addresses: Contracts = deploy_all();

    %{
        ids.policy_address = deploy_contract("./contracts/fee_policies/realms/claim_resources.cairo", [
            ids.resources_token_address,
            ids.realms_address
        ]).contract_address
    %}
    %{
        stop_prank = start_prank(ids.addresses.account1, ids.addresses.guild)
    %}
    Guild.whitelist_member(addresses.guild, addresses.account2, 3);
    Guild.whitelist_member(addresses.guild, addresses.account3, 2);
    %{
        stop_prank()
        stop_prank = start_prank(ids.addresses.account2, ids.addresses.guild)
    %}
    Guild.join(addresses.guild);
    %{
        stop_prank()
        stop_prank = start_prank(ids.addresses.account3, ids.addresses.guild)
    %}
    Guild.join(addresses.guild);
    %{
        stop_prank()
    %}
    PolicyManager.add_policy(addresses.policy_manager, 1, resources_address, CLAIM_RESOURCES_SELECTOR);
    return ();
}

@external
func test_claim_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local account_1_address;
    local resources_address;
    local resources_token_address;
    local settling_address;
    local realms_token_id: Uint256;

    let realms_token_id: Uint256 = Uint256(1, 0);
    %{
        ids.resources_address = context.resources_address
        ids.resources_token_address = context.resources_token_address
        ids.settling_address = context.settling_address
        ids.account_1_address = context.account_1_address
        stop_prank_resources = start_prank(ids.account_1_address, target_contract_address=ids.resources_address)
    %}
    time_warp(1000000, resources_address);
    time_warp(1000000, settling_address);
    IResources.claim_resources(resources_address, realms_token_id);
    let (accounts_len, accounts) = get_owners(account_1_address);
    let (token_ids: Uint256*) = get_resources();
    let (balances_len, balances: Uint256*) = ResourcesToken.balanceOfBatch(
        resources_token_address, accounts_len, accounts, 22, token_ids
    );

    local resources: Uint256* = balances;
    %{
        for i in [1, 7, 12, 5]:
            # assert 18000000000000000000000 == memory[ids.balances._reference_value + 2*i]
            print(memory[ids.balances._reference_value + 2*i])
            # assert 0 == memory[ids.resources._reference_value + 2*i + 1]
        stop_prank_resources()
    %}
    return ();
}

// @external
// func test_fee_policy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     alloc_locals;

//     local account_2_address;
//     local resources_address;
//     local resources_token_address;
//     local settling_address;
//     local realms_token_id: Uint256;

//     let combat_address = 123;
//     let realms_token_id: Uint256 = Uint256(1, 0);
//     %{
//         ids.resources_address = context.resources_address
//         ids.resources_token_address = context.resources_token_address
//         ids.settling_address = context.settling_address
//         ids.account_2_address = context.account_2_address
//         stop_prank_resources = start_prank(ids.combat_address, target_contract_address=ids.resources_address)
//     %}
//     time_warp(1000000, resources_address);
//     time_warp(1000000, settling_address);
//     IResources.pillage_resources(resources_address, realms_token_id, account_2_address);
//     let (accounts_len, accounts) = get_owners(account_2_address);
//     let (token_ids: Uint256*) = get_resources();
//     let (balances_len, balances: Uint256*) = IResourcesToken.balanceOfBatch(
//         resources_token_address, accounts_len, accounts, 22, token_ids
//     );

//     local resources: Uint256* = balances;
//     %{
//         for i in [1, 7, 12, 5]:
//             assert 18000000000000000000000 == memory[ids.balances._reference_value + 2*i]
//             assert 0 == memory[ids.resources._reference_value + 2*i + 1]
//         stop_prank_resources()
//     %}
//     return ();
// }

// TODO
// test wonder claim