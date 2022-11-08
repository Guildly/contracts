%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256

from contracts.fee_policies.realms.claim_resources import get_tokens
from contracts.fee_policies.realms.library import get_owners, get_resources
from lib.realms_contracts_git.contracts.settling_game.interfaces.IERC1155 import IERC1155

from contracts.settling_game.utils.game_structs import ModuleIds

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
        declared = declare("./contracts/fee_policy_manager.cairo")
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

    // %{
    //     print(ids.pre_balances_len)
    //     for i in range(22):
    //         print(f'id: {i} - {memory[ids.resource_ids._reference_value + 2*i]}')
    //     for i in range(22):
    //         print(f'amount: {i} - {memory[ids.resource_amounts._reference_value + 2*i]}') 
    //     for i in range(22):
    //         print(f'pre balance: {i} - {memory[ids.pre_balances._reference_value + 2*i]}')
    //     stop_prank()
    // %}

    return ();
}