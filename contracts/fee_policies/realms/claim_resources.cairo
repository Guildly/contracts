%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero, unsigned_div_rem
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256

from contracts.interfaces.IGuildCertificate import IGuildCertificate
from contracts.fee_policies.realms.library import get_resources, get_owners
from contracts.interfaces.IERC1155 import IERC1155
from contracts.lib.token_standard import TokenStandard

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.upgrades.library import Proxy

const RESOURCES_LENGTH = 22;

@storage_var
func resources_contract() -> (address: felt) {
}

@storage_var
func realms_contract() -> (res: felt) {
}

@storage_var
func guild_certificate() -> (res: felt) {
}

@storage_var
func fee_policy_manager() -> (res: felt) {
}

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    resources_address: felt,
    realms_address: felt,
    certificate_address: felt,
    policy_manager: felt,
    proxy_admin: felt,
) {
    resources_contract.write(resources_address);
    realms_contract.write(realms_address);
    guild_certificate.write(certificate_address);
    fee_policy_manager.write(policy_manager);
    Proxy.initializer(proxy_admin);
    return ();
}

// RESOURCES

@view
func initial_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, selector: felt
) -> (pre_balance_len: felt, pre_balance: felt*) {
    alloc_locals;
    let (guild_address) = get_caller_address();
    let (resources_address) = resources_contract.read();
    let (token_ids) = get_resources();
    let (owners) = get_owners(guild_address);
    let (pre_balance_len, pre_balance) = IERC1155.balanceOfBatch(
        contract_address=resources_address,
        owners_len=RESOURCES_LENGTH,
        owners=owners,
        tokens_id_len=RESOURCES_LENGTH,
        tokens_id=token_ids,
    );
    return (pre_balance_len, pre_balance);
}

@view
func fee_distributions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt,
    selector: felt,
    calldata_len: felt,
    calldata: felt*,
    pre_balances_len: felt,
    pre_balances: Uint256*,
    caller_split: felt,
    owner_split: felt
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
    alloc_locals;
    let (guild_address) = get_caller_address();
    let realm_id_low = calldata[0];
    let realm_id_high = calldata[1];
    let realm_id = Uint256(
        realm_id_low,
        realm_id_high
    );
    let (token_ids) = get_resources();
    let (owners) = get_owners(guild_address);
    let (resources_address) = resources_contract.read();
    let (certificate) = guild_certificate.read();

    let (post_balances_len, post_balances) = IERC1155.balanceOfBatch(
        contract_address=resources_address,
        owners_len=RESOURCES_LENGTH,
        owners=owners,
        tokens_id_len=RESOURCES_LENGTH,
        tokens_id=token_ids,
    );

    let (certificate) = guild_certificate.read();

    let (realms) = realms_contract.read();

    let (owner) = IGuildCertificate.get_token_owner(
        certificate, TokenStandard.ERC721, realms, realm_id
    );

    let (policy_manager) = fee_policy_manager.read();

    let (caller_resources: Uint256*) = alloc();
    let (owner_resources: Uint256*) = alloc();

    calculate_splits(
        RESOURCES_LENGTH,
        post_balances,
        pre_balances,
        caller_split,
        owner_split,
        caller_resources,
        owner_resources,
    );

    return (
        owner,
        RESOURCES_LENGTH,
        caller_resources,
        RESOURCES_LENGTH,
        owner_resources,
        resources_address,
        RESOURCES_LENGTH,
        token_ids,
        2,
    );
}

func calculate_splits{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    len: felt,
    post_resources: Uint256*,
    pre_resources: Uint256*,
    caller_split: felt,
    owner_split: felt,
    caller_resources: Uint256*,
    owner_resources: Uint256*,
) {
    if (len == 0) {
        return ();
    }
    let (diff: Uint256) = SafeUint256.sub_le([post_resources], [pre_resources]);
    let (caller_resource, _) = unsigned_div_rem(caller_split * diff.low, 100);
    let (owner_resource, _) = unsigned_div_rem(owner_split * diff.low, 100);
    assert [caller_resources] = Uint256(caller_resource,0);
    assert [owner_resources] = Uint256(owner_resource,0);
    return calculate_splits(
        len,
        post_resources + Uint256.SIZE,
        pre_resources + Uint256.SIZE,
        caller_split,
        owner_split,
        caller_resources + Uint256.SIZE,
        owner_resources + Uint256.SIZE,
    );
}

// // @notice Claim available resources
// // @token_id The staked realm token id
// @external
// func claim_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     token_id: Uint256
// ) {
//     alloc_locals;
//     Ownable.assert_only_owner();
//     Modifier.assert_part_of_empire(realm_id=token_id.low);

// // prepare the call to balanceOfBatch
//     let (resources_address) = erc1155_contract.read();
//     let (owners: felt*) = get_owners();
//     let (token_ids: Uint256*) = get_resources();

// let (local pre_balance_len, local pre_balance) = IERC1155.balanceOfBatch(
//         contract_address=resources_address,
//         owners_len=RESOURCES_LENGTH,
//         owners=owners,
//         tokens_id_len=RESOURCES_LENGTH,
//         tokens_id=token_ids,
//     );
//     with_attr error_message("resources balance length error") {
//         assert pre_balance_len = RESOURCES_LENGTH;
//     }

// // claim the resources
//     let (resource_module_) = resource_module.read();
//     IResources.claim_resources(contract_address=resource_module_, token_id=token_id);

// // recall balanceOfBatch to retrieve increase in resources
//     let (post_balance_len, post_balance) = IERC1155.balanceOfBatch(
//         contract_address=resources_address,
//         owners_len=RESOURCES_LENGTH,
//         owners=owners,
//         tokens_id_len=RESOURCES_LENGTH,
//         tokens_id=token_ids,
//     );
//     with_attr error_message("resources balance length error") {
//         assert pre_balance_len = RESOURCES_LENGTH;
//     }

// // calculate the taxable amount of resources
//     let (local refund_resources: Uint256*) = alloc();
//     let (producer_taxes_) = producer_taxes.read();
//     get_resources_refund(
//         len=RESOURCES_LENGTH,
//         post_resources=post_balance,
//         pre_resources=pre_balance,
//         diff_resources=refund_resources,
//         tax=producer_taxes_,
//     );

// // send excess resources back to user
//     let (empire_address) = get_contract_address();
//     let (realm: Realm) = realms.read(token_id.low);
//     let (data: felt*) = alloc();
//     assert data[0] = 0;
// IERC1155.safeBatchTransferFrom(
//     contract_address=resources_address,
//     _from=empire_address,
//     to=realm.lord,
//     ids_len=RESOURCES_LENGTH,
//     ids=token_ids,
//     amounts_len=RESOURCES_LENGTH,
//     amounts=refund_resources,
//     data_len=1,
//     data=data,
// );
//     return ();
// }

// // @notice Commence the attack
// // @param attacking_realm_id The staked Realm id (S_Realm)
// // @param defending_realm_id The staked Realm id (S_Realm)
// // @return: combat_outcome The outcome of the combat - either the attacker (CCombat.COMBAT_OUTCOME_ATTACKER_WINS)
// //                          or the defender (CCombat.COMBAT_OUTCOME_DEFENDER_WINS)
// @external
// func initiate_combat{
//     range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
// }(
//     attacking_army_id: felt,
//     attacking_realm_id: Uint256,
//     defending_army_id: felt,
//     defending_realm_id: Uint256,
// ) -> (combat_outcome: felt) {
//     alloc_locals;
//     Ownable.assert_only_owner();
//     Modifier.assert_part_of_empire(realm_id=attacking_realm_id.low);
//     let (defending) = realms.read(defending_realm_id.low);
//     with_attr error_message("friendly fire is not permitted in the empire") {
//         assert defending.lord = 0;
//         assert defending.annexation_date = 0;
//     }

// // prepare the call to balanceOfBatch
//     let (resources_address) = erc1155_contract.read();
//     let (owners: felt*) = get_owners();
//     let (token_ids: Uint256*) = get_resources();

// let (local pre_balance_len, local pre_balance) = IERC1155.balanceOfBatch(
//         contract_address=resources_address,
//         owners_len=RESOURCES_LENGTH,
//         owners=owners,
//         tokens_id_len=RESOURCES_LENGTH,
//         tokens_id=token_ids,
//     );
//     with_attr error_message("resources balance length error") {
//         assert pre_balance_len = RESOURCES_LENGTH;
//     }

// let (combat_module_) = combat_module.read();
//     let (combat_outcome) = ICombat.initiate_combat(
//         contract_address=combat_module_,
//         attacking_army_id=attacking_army_id,
//         attacking_realm_id=attacking_realm_id,
//         defending_army_id=defending_army_id,
//         defending_realm_id=defending_realm_id,
//     );
//     if (combat_outcome == CCombat.COMBAT_OUTCOME_ATTACKER_WINS) {
//         // recall balanceOfBatch to retrieve increase in resources
//         let (local post_balance_len, local post_balance) = IERC1155.balanceOfBatch(
//             contract_address=resources_address,
//             owners_len=RESOURCES_LENGTH,
//             owners=owners,
//             tokens_id_len=RESOURCES_LENGTH,
//             tokens_id=token_ids,
//         );
//         with_attr error_message("resources balance length error") {
//             assert pre_balance_len = RESOURCES_LENGTH;
//         }

// // calculate the taxable amount of resources
//         let (local refund_resources: Uint256*) = alloc();
//         let (attacker_taxes_) = attacker_taxes.read();
//         get_resources_refund(
//             len=RESOURCES_LENGTH,
//             post_resources=post_balance,
//             pre_resources=pre_balance,
//             diff_resources=refund_resources,
//             tax=attacker_taxes_,
//         );

// // send excess resources back to user
//         let (empire_address) = get_contract_address();
//         let (realm: Realm) = realms.read(attacking_realm_id.low);
//         let (data: felt*) = alloc();
//         assert data[0] = 0;
//         IERC1155.safeBatchTransferFrom(
//             contract_address=resources_address,
//             _from=empire_address,
//             to=realm.lord,
//             ids_len=RESOURCES_LENGTH,
//             ids=token_ids,
//             amounts_len=RESOURCES_LENGTH,
//             amounts=refund_resources,
//             data_len=1,
//             data=data,
//         );
//         return (combat_outcome=combat_outcome);
//     }
//     return (combat_outcome=combat_outcome);
// }
