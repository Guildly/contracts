%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256

from contracts.fee_policies.realms.claim_resources import initial_balance, fee_distributions
from contracts.fee_policies.realms.library import get_owners, get_resources
from lib.realms_contracts_git.contracts.settling_game.interfaces.IERC1155 import IERC1155

from contracts.settling_game.utils.game_structs import ModuleIds

from tests.protostar.realms_setup.setup import (
    deploy_account,
    deploy_module,
    deploy_controller,
    time_warp,
)

@contract_interface
namespace FeePolicy {
    func initializer(
        resources_address: felt,
        realms_address: felt,
        certificate_address: felt,
        policy_manager: felt,
        proxy_admin: felt,
    ) {
    }
    func initial_balance(to: felt, selector: felt) -> (
        pre_balances_len: felt, pre_balances: Uint256*
    ) {
    }
    func fee_distributions(
        to: felt,
        selector: felt,
        calldata_len: felt,
        calldata: felt*,
        pre_balances_len: felt,
        pre_balances: Uint256*,
        caller_split: felt,
        owner_split: felt
    ) -> (
        owner: felt,
        caller_amounts_len: felt,
        caller_amounts: Uint256*,
        owner_amounts_len: felt,
        owner_amounts: Uint256*,
        token_address: felt,
        token_ids_len: felt,
        token_ids: Uint256*,
        token_standard: felt
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
        declared = declare("./contracts/fee_policy_manager.cairo")
        ids.policy_manager_address = deploy_contract("./contracts/proxy.cairo", 
            [declared.class_hash]
        ).contract_address
        ids.policy_address = deploy_contract("./contracts/fee_policies/realms/claim_resources.cairo", [
            ids.resources_token_address,
            ids.realms_address
        ]).contract_address
        context.resources_token_address = ids.resources_token_address
        context.account_address = ids.account_address
        context.account_2_address = ids.account_2_address
        context.fee_policy_address = ids.policy_address
    %}

    return ();
}

@external
func test_initial_balance{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local resources_token_address;
    local account_address;
    local fee_policy_address;

    %{
        ids.resources_token_address = context.resources_token_address
        ids.account_address = context.account_address
        ids.fee_policy_address = context.fee_policy_address
        stop_prank = start_prank(ids.account_address, ids.fee_policy_address)
    %}

    let (local resource_ids: Uint256*) = get_resources();

    let (local resource_amounts: Uint256*) = alloc();
    assert resource_amounts[0] = Uint256(1000, 0);
    assert resource_amounts[1] = Uint256(1000, 0);
    assert resource_amounts[2] = Uint256(1000, 0);
    assert resource_amounts[3] = Uint256(1000, 0);
    assert resource_amounts[4] = Uint256(1000, 0);
    assert resource_amounts[5] = Uint256(1000, 0);
    assert resource_amounts[6] = Uint256(1000, 0);
    assert resource_amounts[7] = Uint256(1000, 0);
    assert resource_amounts[8] = Uint256(1000, 0);
    assert resource_amounts[9] = Uint256(1000, 0);
    assert resource_amounts[10] = Uint256(1000, 0);
    assert resource_amounts[11] = Uint256(1000, 0);
    assert resource_amounts[12] = Uint256(1000, 0);
    assert resource_amounts[13] = Uint256(1000, 0);
    assert resource_amounts[14] = Uint256(1000, 0);
    assert resource_amounts[15] = Uint256(1000, 0);
    assert resource_amounts[16] = Uint256(1000, 0);
    assert resource_amounts[17] = Uint256(1000, 0);
    assert resource_amounts[18] = Uint256(1000, 0);
    assert resource_amounts[19] = Uint256(1000, 0);
    assert resource_amounts[20] = Uint256(1000, 0);
    assert resource_amounts[21] = Uint256(1000, 0);

    let (data: felt*) = alloc();
    assert data[0] = 1;

    IERC1155.mintBatch(
        resources_token_address,
        account_address,
        22,
        resource_ids,
        22,
        resource_amounts,
        1,
        data
    );

    let (pre_balances_len, pre_balances: Uint256*) = FeePolicy.initial_balance(
        fee_policy_address,
        1,
        1
    );

    %{
        print(ids.pre_balances_len)
        for i in range(22):
            print(f'id: {i} - {memory[ids.resource_ids._reference_value + 2*i]}')
        for i in range(22):
            print(f'amount: {i} - {memory[ids.resource_amounts._reference_value + 2*i]}') 
        for i in range(22):
            print(f'pre balance: {i} - {memory[ids.pre_balances._reference_value + 2*i]}')
        stop_prank()
    %}

    return ();
}

@external
func test_fee_distributions{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local resources_token_address;
    local account_address;
    local account_2_address;
    local fee_policy_address;

    %{
        ids.resources_token_address = context.resources_token_address
        ids.account_address = context.account_address
        ids.account_2_address = context.account_2_address
        ids.fee_policy_address = context.fee_policy_address
        stop_prank = start_prank(ids.account_address, ids.fee_policy_address)
        stop_prank = start_prank(ids.account_address, ids.resources_token_address)
    %}

    let (local resource_ids: Uint256*) = get_resources();

    let (local pre_balances: Uint256*) = alloc();
    assert pre_balances[0] = Uint256(0, 0);
    assert pre_balances[1] = Uint256(0, 0);
    assert pre_balances[2] = Uint256(0, 0);
    assert pre_balances[3] = Uint256(0, 0);
    assert pre_balances[4] = Uint256(0, 0);
    assert pre_balances[5] = Uint256(0, 0);
    assert pre_balances[6] = Uint256(0, 0);
    assert pre_balances[7] = Uint256(0, 0);
    assert pre_balances[8] = Uint256(0, 0);
    assert pre_balances[9] = Uint256(0, 0);
    assert pre_balances[10] = Uint256(0, 0);
    assert pre_balances[11] = Uint256(0, 0);
    assert pre_balances[12] = Uint256(0, 0);
    assert pre_balances[13] = Uint256(0, 0);
    assert pre_balances[14] = Uint256(0, 0);
    assert pre_balances[15] = Uint256(0, 0);
    assert pre_balances[16] = Uint256(0, 0);
    assert pre_balances[17] = Uint256(0, 0);
    assert pre_balances[18] = Uint256(0, 0);
    assert pre_balances[19] = Uint256(0, 0);
    assert pre_balances[20] = Uint256(0, 0);
    assert pre_balances[21] = Uint256(0, 0);

    let (local resource_amounts: Uint256*) = alloc();
    assert resource_amounts[0] = Uint256(1000, 0);
    assert resource_amounts[1] = Uint256(1000, 0);
    assert resource_amounts[2] = Uint256(1000, 0);
    assert resource_amounts[3] = Uint256(1000, 0);
    assert resource_amounts[4] = Uint256(1000, 0);
    assert resource_amounts[5] = Uint256(1000, 0);
    assert resource_amounts[6] = Uint256(1000, 0);
    assert resource_amounts[7] = Uint256(1000, 0);
    assert resource_amounts[8] = Uint256(1000, 0);
    assert resource_amounts[9] = Uint256(1000, 0);
    assert resource_amounts[10] = Uint256(1000, 0);
    assert resource_amounts[11] = Uint256(1000, 0);
    assert resource_amounts[12] = Uint256(1000, 0);
    assert resource_amounts[13] = Uint256(1000, 0);
    assert resource_amounts[14] = Uint256(1000, 0);
    assert resource_amounts[15] = Uint256(1000, 0);
    assert resource_amounts[16] = Uint256(1000, 0);
    assert resource_amounts[17] = Uint256(1000, 0);
    assert resource_amounts[18] = Uint256(1000, 0);
    assert resource_amounts[19] = Uint256(1000, 0);
    assert resource_amounts[20] = Uint256(1000, 0);
    assert resource_amounts[21] = Uint256(1000, 0);

    let (data: felt*) = alloc();
    assert data[0] = 1;

    IERC1155.mintBatch(
        resources_token_address,
        account_address,
        22,
        resource_ids,
        22,
        resource_amounts,
        1,
        data
    );
    
    let (calldata: felt*) = alloc();
    assert calldata[0] = 1;
    assert calldata[1] = 0;

    let (
        owner: felt,
        local caller_amounts_len: felt,
        local caller_amounts: Uint256*,
        local owner_amounts_len: felt,
        local owner_amounts: Uint256*,
        token_address: felt,
        token_ids_len: felt,
        token_ids: Uint256*,
        token_standard: felt
    ) = FeePolicy.fee_distributions(
        fee_policy_address,
        1,
        1,
        2,
        calldata,
        22,
        pre_balances,
        50,
        50
    );

    IERC1155.safeBatchTransferFrom(
        resources_token_address,
        account_address,
        account_2_address,
        22,
        token_ids,
        22,
        caller_amounts,
        1,
        data
    );

    %{
        print(ids.caller_amounts_len)
        for i in range(22):
            print(f'caller_amount: {i} - {memory[ids.caller_amounts._reference_value + 2*i]}')
        print(ids.owner_amounts_len)
        for i in range(22):
            print(f'owner_amount: {i} - {memory[ids.owner_amounts._reference_value + 2*i]}') 
        stop_prank()
    %}
    return ();
}