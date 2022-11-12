%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256

from contracts.fee_policies.realms.claim_resources import get_tokens
from contracts.fee_policies.realms.library import get_owners, get_resources
from lib.realms_contracts_git.contracts.settling_game.interfaces.IERC1155 import IERC1155

from contracts.lib.role import GuildRoles
from contracts.settling_game.utils.game_structs import ModuleIds
from contracts.fee_policies.library import FeePolicies

from tests.protostar.realms_setup.setup import (
    deploy_account,
    deploy_module,
    deploy_controller,
    time_warp,
)
from tests.protostar.realms_setup.interfaces import Realms

@contract_interface
namespace FeePolicy {
    func get_tokens(
        to: felt, 
        selector: felt, 
        calldata_len: felt, 
        calldata: felt*
    ) -> (
        used_token: felt,
        used_token_id: Uint256,
        used_token_standard: felt,
        accrued_token: felt,
        accrued_token_ids_len: felt,
        accrued_token_ids: Uint256*,
        accrued_token_standard: felt,
    ) {
    }
}

const PK = 11111;
const PK2 = 22222;

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    let (local account_address) = deploy_account(PK);
    let (local account_2_address) = deploy_account(PK2);
    let (local controller_address) = deploy_controller(account_address, account_address);
    let (local resources_token_address) = deploy_module(
        ModuleIds.Resources_Token, controller_address, account_address
    );
    let (local realms_address) = deploy_module(
        ModuleIds.Realms_Token, controller_address, account_address
    );

    local policy_address;
    local certificate_address;
    local policy_manager_address;

    %{
        declared = declare("./contracts/guild_certificate.cairo")
        ids.certificate_address = deploy_contract("./contracts/proxy.cairo", 
            [declared.class_hash]
        ).contract_address
        declared = declare("./contracts/fee_policies/fee_policy_manager.cairo")
        ids.policy_manager_address = deploy_contract("./contracts/proxy.cairo", 
            [declared.class_hash]
        ).contract_address
        ids.policy_address = deploy_contract("./contracts/fee_policies/realms/claim_resources.cairo", [
            ids.resources_token_address,
            ids.realms_address
        ]).contract_address
        context.resources_token_address = ids.resources_token_address
        context.realms_address = ids.realms_address
        context.account_address = ids.account_address
        context.account_2_address = ids.account_2_address
        context.fee_policy_address = ids.policy_address
    %}
    Realms.mint(realms_address, account_address);

    return ();
}

@external
func test_get_tokens{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local resources_token_address;
    local realms_address;
    local account_address;
    local fee_policy_address;
    local selector_address;

    %{
        # from starkware.starknet.public.abi import get_selector_from_name
        ids.resources_token_address = context.resources_token_address
        ids.account_address = context.account_address
        ids.fee_policy_address = context.fee_policy_address
        ids.realms_address = context.realms_address
        # ids.selector_address = get_selector_from_name('claim_resources')
        stop_prank = start_prank(ids.account_address, ids.fee_policy_address)
    %}

    let to = realms_address;
    let selector = 123;
    let calldata_len = 2;
    let (calldata: felt*) = alloc();
    assert calldata[0] = 1;
    assert calldata[1] = 0;


    let (        
        local used_token: felt,
        local used_token_id: Uint256,
        local used_token_standard: felt,
        local accrued_token: felt,
        local accrued_token_ids_len: felt,
        local accrued_token_ids: Uint256*,
        local accrued_token_standard: felt
    ) = FeePolicy.get_tokens(
        fee_policy_address,
        to,
        selector,
        calldata_len,
        calldata
    );

    %{
        assert ids.used_token == ids.realms_address
        assert memory[ids.used_token_id._reference_value] == 1
        assert memory[ids.used_token_id._reference_value + 1] == 0
        assert ids.used_token_standard == 1
        assert ids.accrued_token == ids.resources_token_address
        assert ids.accrued_token_ids_len == 22
        assert ids.accrued_token_standard == 2
    %}

    return ();
}

@external
func test_calculate_splits{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    // let (local resource_ids: Uint256*) = get_resources();

    let (pre_balances: Uint256*) = alloc();
    assert pre_balances[0] = Uint256(1000, 0);
    assert pre_balances[1] = Uint256(1000, 0);
    assert pre_balances[2] = Uint256(1000, 0);
    assert pre_balances[3] = Uint256(1000, 0);
    assert pre_balances[4] = Uint256(1000, 0);
    assert pre_balances[5] = Uint256(1000, 0);
    assert pre_balances[6] = Uint256(1000, 0);
    assert pre_balances[7] = Uint256(1000, 0);
    assert pre_balances[8] = Uint256(1000, 0);
    assert pre_balances[9] = Uint256(1000, 0);
    assert pre_balances[10] = Uint256(1000, 0);
    assert pre_balances[11] = Uint256(1000, 0);
    assert pre_balances[12] = Uint256(1000, 0);
    assert pre_balances[13] = Uint256(1000, 0);
    assert pre_balances[14] = Uint256(1000, 0);
    assert pre_balances[15] = Uint256(1000, 0);
    assert pre_balances[16] = Uint256(1000, 0);
    assert pre_balances[17] = Uint256(1000, 0);
    assert pre_balances[18] = Uint256(1000, 0);
    assert pre_balances[19] = Uint256(1000, 0);
    assert pre_balances[20] = Uint256(1000, 0);
    assert pre_balances[21] = Uint256(1000, 0);

    let (post_balances: Uint256*) = alloc();
    assert post_balances[0] = Uint256(2000, 0);
    assert post_balances[1] = Uint256(2000, 0);
    assert post_balances[2] = Uint256(2000, 0);
    assert post_balances[3] = Uint256(2000, 0);
    assert post_balances[4] = Uint256(2000, 0);
    assert post_balances[5] = Uint256(2000, 0);
    assert post_balances[6] = Uint256(2000, 0);
    assert post_balances[7] = Uint256(2000, 0);
    assert post_balances[8] = Uint256(2000, 0);
    assert post_balances[9] = Uint256(2000, 0);
    assert post_balances[10] = Uint256(2000, 0);
    assert post_balances[11] = Uint256(2000, 0);
    assert post_balances[12] = Uint256(2000, 0);
    assert post_balances[13] = Uint256(2000, 0);
    assert post_balances[14] = Uint256(2000, 0);
    assert post_balances[15] = Uint256(2000, 0);
    assert post_balances[16] = Uint256(2000, 0);
    assert post_balances[17] = Uint256(2000, 0);
    assert post_balances[18] = Uint256(2000, 0);
    assert post_balances[19] = Uint256(2000, 0);
    assert post_balances[20] = Uint256(2000, 0);
    assert post_balances[21] = Uint256(2000, 0);

    let caller_split = 1500;
    let owner_split = 8500;
    let admin_split = 0;

    let (local caller_balances: Uint256*) = alloc();
    let (local owner_balances: Uint256*) = alloc();
    let (local admin_balances: Uint256*) = alloc();

    FeePolicies.calculate_splits(
        22,
        pre_balances,
        post_balances,
        caller_split,
        owner_split,
        admin_split,
        caller_balances,
        owner_balances,
        admin_balances
    );

    %{
        for i in range(22):
            print(f'caller: {i} - {memory[ids.caller_balances._reference_value + 2*i]}')
        for i in range(22):
            print(f'owner: {i} - {memory[ids.owner_balances._reference_value + 2*i]}') 
        for i in range(22):
            print(f'admin: {i} - {memory[ids.admin_balances._reference_value + 2*i]}')
    %}
    return ();
}