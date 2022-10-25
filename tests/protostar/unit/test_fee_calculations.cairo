%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace Resources {
    func initializer(uri: felt, proxy_admin: felt, module_controller_address: felt) {
    }
}

@contract_interface
namespace Realms {
    func initializer(name: felt, symbol: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace ClaimResources {
    func initializer(
        resources_address: felt,
        realms_address: felt,
        certificate_address: felt,
        policy_manager: felt,
        proxy_admin: felt,
    ) {
    }

    func initial_balance(to: felt, selector: felt) -> (pre_balance_len: felt, pre_balance: felt*) {
    }

    func fee_distributions(
        to: felt,
        selector: felt,
        calldata_len: felt,
        calldata: felt*,
        pre_balances_len: felt,
        pre_balances: Uint256*,
        caller_split: felt,
        owner_split: felt,
    ) -> (
        owner_felt: felt,
        caller_splits_len: felt,
        caller_splits: Uint256*,
        owner_splits_len: felt,
        owner_splits: Uint256*,
        token_address: felt,
        token_ids_len: felt,
        token_ids: Uint256*,
        token_standard: felt,
    ) {
    }
}

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local Resources_token_address;
    local Realms_token_address;
    local Claim_resources_policy_address;
    %{
        context.Resources_token_address = deploy_contract("./contracts/settling_game/tokens/Resources_ERC1155_Mintable_Burnable.cairo", []).contract_address
        ids.Resources_token_address = context.Resources_token_address
        context.Realms_token_address = deploy_contract("./contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo", []).contract_address
        ids.Realms_token_address = context.Realms_token_address
        context.Claim_resources_policy_address = deploy_contract("./contracts/fee_policies/realms/claim_resources.cairo", []).contract_address
        ids.Claim_resources_policy_address = context.Claim_resources_policy_address
    %}
    Resources.initializer(Resources_token_address, 1, 1, 1);
    Realms.initializer(Realms_token_address, 1, 1, 1);
    ClaimResources.initializer(
        Claim_resources_policy_address, Resources_token_address, Realms_token_address, 1, 1, 1
    );

    return ();
}

@external
func test_initial_balance{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;
    local Claim_resources_policy_address;
    %{ ids.Claim_resources_policy_address = context.Claim_resources_policy_address %}
    let (pre_balances_len, pre_balances: Uint256*) = ClaimResources.initial_balance(
        Claim_resources_policy_address, 1, 1
    );
    %{ print(ids.pre_balances_len) %}
    return ();
}

@external
func test_fee_distributions{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;
    local Resources_token_address;
    local Claim_resources_policy_address;
    %{ 
        ids.Resources_token_address = context.Resources_token_address
        ids.Claim_resources_policy_address = context.Claim_resources_policy_address 
    %}

    let (pre_balances: Uint256*) = alloc();
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

    let (calldata) = alloc();
    assert calldata[0] = 1;
    assert calldata[1] = 0;

    %{
        stop_mock_1 = mock_call(ids.Resources_token_address, "balanceOfBatch", [
            22,
            0,
            0,
            1000,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            5000,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            2000,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ])
        stop_mock_2 = mock_call(1, "get_token_owner", [10])
    %}

    let (
        owner_felt,
        caller_splits_len,
        caller_splits: Uint256*,
        owner_splits_len,
        owner_splits: Uint256*,
        token_address,
        token_ids_len,
        token_ids: Uint256*,
        token_standard,
    ) = ClaimResources.fee_distributions(
        Claim_resources_policy_address,
        1,
        1,
        2,
        calldata,
        22,
        pre_balances,
        50,
        50,
    );

    %{
        caller_balances = reflect.caller_splits.get()
        owner_balances = reflect.owner_splits.get()
        print(caller_balances)
        print(owner_balances)
    %}
    return ();
}
