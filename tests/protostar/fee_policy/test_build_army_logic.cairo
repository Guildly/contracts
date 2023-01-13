%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256

from contracts.fee_policies.realms.claim_resources import get_tokens
from contracts.fee_policies.realms.library import get_owners, get_resources

from lib.cairo_contracts.src.openzeppelin.token.erc20.IERC20 import IERC20
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
    func check_caller_balance(
        calldata_len: felt, 
        calldata: felt*, 
        caller_balances_len: felt, 
        caller_balances: Uint256*
    ) -> (bool: felt) {
    }
    func execute_payment_plan(
        pre_balances_len: felt, 
        pre_balances: Uint256*, 
        post_balances_len: felt, 
        post_balances: Uint256*,
        payment_tokens_len: felt,
        payment_tokens: felt*,
        payment_amounts_len: felt,
        payment_amounts: Uint256*,
        recipients_len: felt,
        recipients: felt*
    ) -> (final_balances_len: felt, final_balances: Uint256*) {
    }
}

const PK = 11111;
const PK2 = 22222;

const ETH_NAME = 'Ether';
const ETH_SYMBOL = 'ETH';

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
    let (local combat_address) = deploy_module(
        ModuleIds.L06_Combat, controller_address, account_address
    );

    local policy_address;
    local certificate_address;
    local eth_address;
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
        ids.eth_address = deploy_contract("./openzeppelin/token/erc20/presets/ERC20Mintable.cairo", [
            ids.ETH_NAME, 
            ids.ETH_SYMBOL, 
            18, 
            1000,
            0, 
            ids.account_address,
            ids.account_address
        ]).contract_address
        ids.policy_address = deploy_contract("./contracts/fee_policies/realms/build_army.cairo", [
            ids.resources_token_address,
            ids.realms_address,
            ids.combat_address
        ]).contract_address
        context.resources_token_address = ids.resources_token_address
        context.realms_address = ids.realms_address
        context.account_address = ids.account_address
        context.account_2_address = ids.account_2_address
        context.fee_policy_address = ids.policy_address
        context.eth_address = ids.eth_address
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
func test_check_caller_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_address;
    local fee_policy_address;

    %{
        ids.account_address = context.account_address
        ids.fee_policy_address = context.fee_policy_address
        stop_prank = start_prank(ids.account_address, ids.fee_policy_address)
    %}

    let calldata_len = 9;
    let (calldata: felt*) = alloc();
    assert calldata[0] = 1;
    assert calldata[1] = 0;
    assert calldata[2] = 1;
    assert calldata[3] = 2;
    assert calldata[4] = 1;
    assert calldata[5] = 2;
    assert calldata[6] = 2;
    assert calldata[7] = 2;
    assert calldata[8] = 1;
    let (caller_balances: Uint256*) = alloc();
    assert caller_balances[0] = Uint256(1000, 0);
    assert caller_balances[1] = Uint256(1000, 0);
    assert caller_balances[2] = Uint256(1000, 0);
    assert caller_balances[3] = Uint256(1000, 0);
    assert caller_balances[4] = Uint256(1000, 0);
    assert caller_balances[5] = Uint256(1000, 0);
    assert caller_balances[6] = Uint256(1000, 0);
    assert caller_balances[7] = Uint256(1000, 0);
    assert caller_balances[8] = Uint256(1000, 0);
    assert caller_balances[9] = Uint256(1000, 0);
    assert caller_balances[10] = Uint256(1000, 0);
    assert caller_balances[11] = Uint256(1000, 0);
    assert caller_balances[12] = Uint256(1000, 0);
    assert caller_balances[13] = Uint256(1000, 0);
    assert caller_balances[14] = Uint256(1000, 0);
    assert caller_balances[15] = Uint256(1000, 0);
    assert caller_balances[16] = Uint256(1000, 0);
    assert caller_balances[17] = Uint256(1000, 0);
    assert caller_balances[18] = Uint256(1000, 0);
    assert caller_balances[19] = Uint256(1000, 0);
    assert caller_balances[20] = Uint256(1000, 0);
    assert caller_balances[21] = Uint256(1000, 0);
    let (bool) = FeePolicy.check_caller_balance(
        fee_policy_address,
        calldata_len,
        calldata,
        22,
        caller_balances
    );

    assert bool = TRUE;

    return ();
}

@external
func test_execute_payment_plan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    
    local account_address;
    local account_2_address;
    local eth_address;
    local fee_policy_address;

    %{
        ids.account_address = context.account_address
        ids.account_2_address = context.account_2_address
        ids.eth_address = context.eth_address
        ids.fee_policy_address = context.fee_policy_address
        stop_prank_fee = start_prank(ids.account_address, ids.fee_policy_address)
        stop_prank_eth = start_prank(ids.account_address, ids.eth_address)
    %}

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
    assert post_balances[0] = Uint256(0, 0);
    assert post_balances[1] = Uint256(0, 0);
    assert post_balances[2] = Uint256(0, 0);
    assert post_balances[3] = Uint256(0, 0);
    assert post_balances[4] = Uint256(0, 0);
    assert post_balances[5] = Uint256(0, 0);
    assert post_balances[6] = Uint256(0, 0);
    assert post_balances[7] = Uint256(0, 0);
    assert post_balances[8] = Uint256(0, 0);
    assert post_balances[9] = Uint256(0, 0);
    assert post_balances[10] = Uint256(0, 0);
    assert post_balances[11] = Uint256(0, 0);
    assert post_balances[12] = Uint256(0, 0);
    assert post_balances[13] = Uint256(0, 0);
    assert post_balances[14] = Uint256(0, 0);
    assert post_balances[15] = Uint256(0, 0);
    assert post_balances[16] = Uint256(0, 0);
    assert post_balances[17] = Uint256(0, 0);
    assert post_balances[18] = Uint256(0, 0);
    assert post_balances[19] = Uint256(0, 0);
    assert post_balances[20] = Uint256(0, 0);
    assert post_balances[21] = Uint256(0, 0);

    let (payment_tokens: felt*) = alloc();
    assert payment_tokens[0] = eth_address;

    let (payment_amounts: Uint256*) = alloc();
    assert payment_amounts[0] = Uint256(50, 0);

    let (recipients: felt*) = alloc();
    assert recipients[0] = account_2_address;

    IERC20.approve(eth_address, fee_policy_address, Uint256(1000, 0));

    %{
        stop_prank_eth()
        stop_prank_eth = start_prank(ids.fee_policy_address, ids.eth_address)
    %}

    let (local final_balances_len, local final_balances) = FeePolicy.execute_payment_plan(
        fee_policy_address, 
        22,
        pre_balances,
        22,
        post_balances,
        1,
        payment_tokens,
        1,
        payment_amounts,
        1,
        recipients
    );

    %{
        stop_prank_fee()
        stop_prank_eth()
    %}

    return ();

}