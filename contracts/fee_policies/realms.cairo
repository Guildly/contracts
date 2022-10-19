%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero, unsigned_div_rem
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_block_timestamp, get_contract_address
from starkware.cairo.common.uint256 import Uint256

from contracts.interfaces.realms import IBuildings, IFood, IResources, ITravel, ICombat
from contracts.empires.constants import FOOD_LENGTH, RESOURCES_LENGTH
from contracts.empires.storage import (
    realms,
    erc1155_contract,
    building_module,
    food_module,
    goblin_town_module,
    resource_module,
    travel_module,
    combat_module,
    producer_taxes,
    attacker_taxes,
)
from contracts.empires.helpers import get_resources, get_owners, get_resources_refund
from contracts.empires.modifiers import Modifier
from contracts.empires.structures import Realm
from contracts.settling_game.utils.game_structs import HarvestType
from contracts.settling_game.utils.constants import CCombat
from contracts.settling_game.utils.game_structs import ResourceIds
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from src.openzeppelin.access.ownable.library import Ownable
from src.openzeppelin.security.safemath.library import SafeUint256

// @notice Harvests either farms or fishing villages
// @param token_id The staked Realm id (S_Realm)
// @param harvest_type The harvest type is either export or store. Export mints tokens, store keeps on the realm as food
// @param food_building_id The food building id
@external
func harvest{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(calldata_len: felt, food_building_id: felt) {
    alloc_locals;
    Ownable.assert_only_owner();
    Modifier.assert_part_of_empire(realm_id=token_id.low);

    // prepare the call to balanceOfBatch
    let (resources_address) = erc1155_contract.read();
    let (owners: felt*) = alloc();
    let (token_ids: Uint256*) = alloc();
    let (empire_address) = get_contract_address();
    assert [owners] = empire_address;
    assert [owners + 1] = empire_address;
    assert [token_ids] = Uint256(ResourceIds.wheat, 0);
    assert [token_ids + Uint256.SIZE] = Uint256(ResourceIds.fish, 0);

    let (local pre_balance_len, local pre_balance) = IERC1155.balanceOfBatch(
        contract_address=resources_address,
        owners_len=FOOD_LENGTH,
        owners=owners,
        tokens_id_len=FOOD_LENGTH,
        tokens_id=token_ids,
    );
    with_attr error_message("food balance length error") {
        assert pre_balance_len = FOOD_LENGTH;
    }

    // harvest for the realm_id
    // force to mint tokens in order to collect the tax
    let (food_module_) = food_module.read();
    IFood.harvest(
        contract_address=food_module_,
        token_id=token_id,
        harvest_type=HarvestType.Export,
        food_building_id=food_building_id,
    );

    // recall balanceOfBatch to retrieve increase in resources
    let (local post_balance_len, local post_balance) = IERC1155.balanceOfBatch(
        contract_address=resources_address,
        owners_len=FOOD_LENGTH,
        owners=owners,
        tokens_id_len=FOOD_LENGTH,
        tokens_id=token_ids,
    );
    with_attr error_message("food balance length error") {
        assert post_balance_len = FOOD_LENGTH;
    }

    // calculate resources increase and send to user diff * (100 - tax) // 100
    let (amounts: Uint256*) = alloc();
    let (data: felt*) = alloc();
    assert data[0] = 0;
    let (food_tax) = producer_taxes.read();
    let (diff_wheat: Uint256) = SafeUint256.sub_le([post_balance], [pre_balance]);
    let (diff_fish: Uint256) = SafeUint256.sub_le(
        [post_balance + Uint256.SIZE], [pre_balance + Uint256.SIZE]
    );
    let (realm_wheat, _) = unsigned_div_rem(diff_wheat.low * (100 - food_tax), 100);
    let (realm_fish, _) = unsigned_div_rem(diff_fish.low * (100 - food_tax), 100);
    assert [amounts] = Uint256(realm_wheat, 0);
    assert [amounts + Uint256.SIZE] = Uint256(realm_fish, 0);

    // send cut back to the owner
    let (realm: Realm) = IGuildCertificate.r.read(token_id.low);

    // send cut back to the caller
    


    // send cut back to the guild


    IERC1155.safeBatchTransferFrom(
        contract_address=resources_address,
        _from=empire_address,
        to=realm.lord,
        ids_len=FOOD_LENGTH,
        ids=token_ids,
        amounts_len=FOOD_LENGTH,
        amounts=amounts,
        data_len=1,
        data=data,
    );
    return ();
}

// RESOURCES

// @notice Claim available resources
// @token_id The staked realm token id
@external
func claim_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) {
    alloc_locals;
    Ownable.assert_only_owner();
    Modifier.assert_part_of_empire(realm_id=token_id.low);

    // prepare the call to balanceOfBatch
    let (resources_address) = erc1155_contract.read();
    let (owners: felt*) = get_owners();
    let (token_ids: Uint256*) = get_resources();

    let (local pre_balance_len, local pre_balance) = IERC1155.balanceOfBatch(
        contract_address=resources_address,
        owners_len=RESOURCES_LENGTH,
        owners=owners,
        tokens_id_len=RESOURCES_LENGTH,
        tokens_id=token_ids,
    );
    with_attr error_message("resources balance length error") {
        assert pre_balance_len = RESOURCES_LENGTH;
    }

    // claim the resources
    let (resource_module_) = resource_module.read();
    IResources.claim_resources(contract_address=resource_module_, token_id=token_id);

    // recall balanceOfBatch to retrieve increase in resources
    let (local post_balance_len, local post_balance) = IERC1155.balanceOfBatch(
        contract_address=resources_address,
        owners_len=RESOURCES_LENGTH,
        owners=owners,
        tokens_id_len=RESOURCES_LENGTH,
        tokens_id=token_ids,
    );
    with_attr error_message("resources balance length error") {
        assert pre_balance_len = RESOURCES_LENGTH;
    }

    // calculate the taxable amount of resources
    let (local refund_resources: Uint256*) = alloc();
    let (producer_taxes_) = producer_taxes.read();
    get_resources_refund(
        len=RESOURCES_LENGTH,
        post_resources=post_balance,
        pre_resources=pre_balance,
        diff_resources=refund_resources,
        tax=producer_taxes_,
    );

    // send excess resources back to user
    let (empire_address) = get_contract_address();
    let (realm: Realm) = realms.read(token_id.low);
    let (data: felt*) = alloc();
    assert data[0] = 0;
    IERC1155.safeBatchTransferFrom(
        contract_address=resources_address,
        _from=empire_address,
        to=realm.lord,
        ids_len=RESOURCES_LENGTH,
        ids=token_ids,
        amounts_len=RESOURCES_LENGTH,
        amounts=refund_resources,
        data_len=1,
        data=data,
    );
    return ();
}

// @notice Commence the attack
// @param attacking_realm_id The staked Realm id (S_Realm)
// @param defending_realm_id The staked Realm id (S_Realm)
// @return: combat_outcome The outcome of the combat - either the attacker (CCombat.COMBAT_OUTCOME_ATTACKER_WINS)
//                          or the defender (CCombat.COMBAT_OUTCOME_DEFENDER_WINS)
@external
func initiate_combat{
    range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}(
    attacking_army_id: felt,
    attacking_realm_id: Uint256,
    defending_army_id: felt,
    defending_realm_id: Uint256,
) -> (combat_outcome: felt) {
    alloc_locals;
    Ownable.assert_only_owner();
    Modifier.assert_part_of_empire(realm_id=attacking_realm_id.low);
    let (defending) = realms.read(defending_realm_id.low);
    with_attr error_message("friendly fire is not permitted in the empire") {
        assert defending.lord = 0;
        assert defending.annexation_date = 0;
    }

    // prepare the call to balanceOfBatch
    let (resources_address) = erc1155_contract.read();
    let (owners: felt*) = get_owners();
    let (token_ids: Uint256*) = get_resources();

    let (local pre_balance_len, local pre_balance) = IERC1155.balanceOfBatch(
        contract_address=resources_address,
        owners_len=RESOURCES_LENGTH,
        owners=owners,
        tokens_id_len=RESOURCES_LENGTH,
        tokens_id=token_ids,
    );
    with_attr error_message("resources balance length error") {
        assert pre_balance_len = RESOURCES_LENGTH;
    }

    let (combat_module_) = combat_module.read();
    let (combat_outcome) = ICombat.initiate_combat(
        contract_address=combat_module_,
        attacking_army_id=attacking_army_id,
        attacking_realm_id=attacking_realm_id,
        defending_army_id=defending_army_id,
        defending_realm_id=defending_realm_id,
    );
    if (combat_outcome == CCombat.COMBAT_OUTCOME_ATTACKER_WINS) {
        // recall balanceOfBatch to retrieve increase in resources
        let (local post_balance_len, local post_balance) = IERC1155.balanceOfBatch(
            contract_address=resources_address,
            owners_len=RESOURCES_LENGTH,
            owners=owners,
            tokens_id_len=RESOURCES_LENGTH,
            tokens_id=token_ids,
        );
        with_attr error_message("resources balance length error") {
            assert pre_balance_len = RESOURCES_LENGTH;
        }

        // calculate the taxable amount of resources
        let (local refund_resources: Uint256*) = alloc();
        let (attacker_taxes_) = attacker_taxes.read();
        get_resources_refund(
            len=RESOURCES_LENGTH,
            post_resources=post_balance,
            pre_resources=pre_balance,
            diff_resources=refund_resources,
            tax=attacker_taxes_,
        );

        // send excess resources back to user
        let (empire_address) = get_contract_address();
        let (realm: Realm) = realms.read(attacking_realm_id.low);
        let (data: felt*) = alloc();
        assert data[0] = 0;
        IERC1155.safeBatchTransferFrom(
            contract_address=resources_address,
            _from=empire_address,
            to=realm.lord,
            ids_len=RESOURCES_LENGTH,
            ids=token_ids,
            amounts_len=RESOURCES_LENGTH,
            amounts=refund_resources,
            data_len=1,
            data=data,
        );
        return (combat_outcome=combat_outcome);
    }
    return (combat_outcome=combat_outcome);
}