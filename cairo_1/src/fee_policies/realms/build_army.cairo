%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict import dict_read, dict_write
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.math import assert_le, unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.pow import pow
from starkware.cairo.common.uint256 import Uint256, uint256_lt

from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.token.erc20.IERC20 import IERC20

from contracts.fee_policies.library import TokenArray, TokenBalances, TokenBalancesArray
from contracts.fee_policies.realms.library import get_resources, get_owners
from contracts.interfaces.IERC1155 import IERC1155
from contracts.settling_game.utils.pow2 import pow2

// struct holding how much resources does it cost to build/buy a thing
struct Cost {
    // the count of unique ResourceIds necessary
    resource_count: felt,
    // how many bits are the packed members packed into
    bits: felt,
    // packed IDs of the necessary resources
    packed_ids: felt,
    // packed amounts of each resource
    packed_amounts: felt,
}

@contract_interface
namespace ICombat {
    func get_battalion_cost(battalion_id: felt) -> (cost: Cost) {
    }
}

@contract_interface
namespace IResources {
    func balanceOfBatch(
        owners_len: felt, 
        owners: felt*, 
        token_ids_len: felt, 
        token_ids: Uint256*
    ) -> (balances_len: felt, balances: Uint256*) {
    }
}

const RESOURCES_LENGTH = 22;
const MAX_UINT_PART = 2 ** 128 - 1;

@storage_var
func resources_contract() -> (address: felt) {
}

@storage_var
func realms_contract() -> (res: felt) {
}

@storage_var
func combat_contract() -> (res: felt) {
}


#[contract]
mod BuildArmy {

    struct Storage {
        _resources_contract: ContractAddress,
        _realms: ContractAddress,
        _combat: ContractAddress,
    }

    #[constructor]
    fn constructor(resources_address: ContractAddress,realms_address: ContractAddress,combat_address: ContractAddress) {
        resources_contract::write(resources_address);
        realms_contract::write(realms_address);
        combat_contract::write(combat_address)
    }

    #[view]
    fn get_tokens(to: ContractAddress, selector: ContractAddress, calldata: Array<span<felt252>>) -> (
        used_token_ids: Array<TokenDetails>,
        token_ids: Array<TokenDetails>
    ) {
        let realm_id_low = calldata[0];
        let realm_id_high = calldata[1];
        let realm_id = Uint256(
            realm_id_low,
            realm_id_high
        );
        let realms_address = realms_contract::read();
        let resources_address = resources_contract::read();

        let used_token_ids = ArrayTrait::new();
        used_token_ids[0] = realm_id;

        let accrued_token_ids = get_resources();



        let (accrued_token_array: TokenArray*) = alloc();
        assert accrued_token_array[0] = TokenArray(
            1,
            resources_address,
            0,
            RESOURCES_LENGTH
        );

        return (
            used_token_ids,
            accrued_token_ids,
        );
    }

    #[external]
    fn get_balances() -> (token_balances: Array<TokenBalances>) {
        let caller = get_caller_address();
        let resources_address = resources_contract::read();
        let token_ids = get_resources();
        let owners = get_owners(caller);
        let final_balances = IResources::balanceOfBatch(resources_address, owners, token_ids)
    }
}

// RESOURCES

@external
func check_owner_balances{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    calldata_len: felt, calldata: felt*, owner_balances_len: felt, owner_balances: Uint256*
) -> (bool: felt) {
    alloc_locals;
    let (combat_address) = combat_contract.read();
    let realm_id_low = calldata[0];
    let realm_id_high = calldata[1];
    let realm_id = Uint256(
        realm_id_low,
        realm_id_high
    );
    let army_id = calldata[2];
    let battalion_ids_len = calldata[3];
    
    let (battalion_ids: felt*) = alloc();
    unpack_calldata_loop(4, 0, battalion_ids_len, calldata, battalion_ids);

    let battalion_quantity_len = calldata[4 + battalion_ids_len];
    let (battalion_quantity: felt*) = alloc();

    unpack_calldata_loop(5 + battalion_quantity_len, 0, battalion_quantity_len, calldata, battalion_quantity);

    let (battalion_costs: Cost*) = alloc();

    load_battalion_costs(
        combat_address, 
        battalion_ids_len,
        battalion_ids,
        battalion_costs
    );

    // transform costs into tokens
    let (token_len: felt, token_ids: Uint256*, token_values: Uint256*) = transform_costs_to_tokens(
        battalion_ids_len, battalion_costs, 1
    );

    let (bool) = check_owner_amount(0, token_len, token_ids, token_values, owner_balances);

    return (bool,);
}

func unpack_calldata_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    calldata_index: felt, new_array_index: felt, calldata_len: felt, calldata: felt*, new_array: felt*
) {
    if (new_array_index == calldata_len) {
        return ();
    }
    assert new_array[new_array_index] = calldata[calldata_index];
    return unpack_calldata_loop(calldata_index + 1, new_array_index + 1, calldata_len, calldata, new_array);
}

// @notice Load Battalion costs
func load_battalion_costs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    combat_address: felt, battlion_ids_len: felt, battlion_ids: felt*, costs: Cost*
) {
    alloc_locals;

    if (battlion_ids_len == 0) {
        return ();
    }

    let (cost: Cost) = ICombat.get_battalion_cost(combat_address, [battlion_ids]);
    assert [costs] = cost;

    return load_battalion_costs(combat_address, battlion_ids_len - 1, battlion_ids + 1, costs + Cost.SIZE);
}

func transform_costs_to_tokens{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(costs_len: felt, costs: Cost*, qty: felt) -> (
    token_len: felt, token_ids: Uint256*, token_values: Uint256*
) {
    alloc_locals;

    // destructure the costs array to two arrays, one
    // holding the IDs of resources and the other one values of resources
    // that are required to build the Troops
    let (resource_ids: felt*) = alloc();
    let (resource_values: felt*) = alloc();
    let (resource_len: felt) = load_resource_ids_and_values_from_costs(
        resource_ids, resource_values, costs_len, costs, 0
    );

    // unify the resources and convert them to a list of Uint256, so that they can
    // be used in a IERC1155 function call
    let (d_len: felt, d: DictAccess*) = sum_values_by_key(
        resource_len, resource_ids, resource_values
    );

    // populate the toke IDs and token values arrays with correct values
    // from the dictionary
    let (token_ids: Uint256*) = alloc();
    let (token_values: Uint256*) = alloc();
    convert_cost_dict_to_tokens_and_values(d_len, d, qty, token_ids, token_values);

    return (d_len, token_ids, token_values);
}

// function takes a dictionary where the keys are (ERC1155) token IDs and
// values are the amounts to be bought and populates the passed in `token_ids`
// and `token_values` arrays with Uint256 elements
// all values are multiplier by `value_multiplier`
func convert_cost_dict_to_tokens_and_values{range_check_ptr}(
    len: felt, d: DictAccess*, value_multiplier: felt, token_ids: Uint256*, token_values: Uint256*
) {
    alloc_locals;

    if (len == 0) {
        return ();
    }

    let current_entry: DictAccess = [d];

    // assuming we will never have token IDs and values with numbers >= 2**128
    with_attr error_message(
            "Token values out of bounds: ID {current_entry.key} value {current_entry.new_value}") {
        assert_le(current_entry.key, MAX_UINT_PART);
        assert_le(current_entry.new_value, MAX_UINT_PART);
    }
    assert [token_ids] = Uint256(low=current_entry.key, high=0);
    assert [token_values] = Uint256(low=current_entry.new_value * 10 ** 18 * value_multiplier, high=0);

    return convert_cost_dict_to_tokens_and_values(
        len - 1,
        d + DictAccess.SIZE,
        value_multiplier,
        token_ids + Uint256.SIZE,
        token_values + Uint256.SIZE,
    );
}

// function takes an array of Cost structs (which hold packed values of
// resource IDs and respective amounts of these resources necessary to build
// something) and unpacks them into two arrays of `ids` and `values` - i.e.
// this func has a side-effect of populating the ids and values arrays;
// it returns the total number of resources as `sum([c.resource_count for c in costs])`
// which is also the length of the ids and values arrays
func load_resource_ids_and_values_from_costs{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}(ids: felt*, values: felt*, costs_len: felt, costs: Cost*, cummulative_resource_count: felt) -> (
    total_resource_count: felt
) {
    alloc_locals;

    if (costs_len == 0) {
        return (cummulative_resource_count,);
    }

    let current_cost: Cost = [costs];
    load_single_cost_ids_and_values(current_cost, 0, ids, values);

    return load_resource_ids_and_values_from_costs(
        ids + current_cost.resource_count,
        values + current_cost.resource_count,
        costs_len - 1,
        costs + Cost.SIZE,
        cummulative_resource_count + current_cost.resource_count,
    );
}

// helper function for the load_resource_ids_and_values_from_cost
// it works with a single Cost struct, from which it unpacks the packed
// resource IDs and packed resource amounts and appends these to
// the passed in `ids` and `values` array; it recursively calls itself,
// looping through all the resources (resource_count) in the Cost struct
func load_single_cost_ids_and_values{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}(cost: Cost, idx: felt, ids: felt*, values: felt*) {
    alloc_locals;

    if (idx == cost.resource_count) {
        return ();
    }

    let (bits_squared) = pow2(cost.bits);
    let (token_id) = unpack_data(cost.packed_ids, cost.bits * idx, bits_squared - 1);
    let (value) = unpack_data(cost.packed_amounts, cost.bits * idx, bits_squared - 1);
    assert [ids + idx] = token_id;
    assert [values + idx] = value;

    return load_single_cost_ids_and_values(cost, idx + 1, ids, values);
}

func check_owner_amount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: felt,
    tokens_len: felt,
    token_ids: Uint256*,
    token_values: Uint256*,
    caller_balances: Uint256*
) -> (bool: felt) {
    if (index == tokens_len) {
        return(TRUE,);
    }
    let amount_needed = token_values[index];
    let caller_amount = caller_balances[index];
    let (check) = uint256_lt(caller_amount, amount_needed);
    if (check == TRUE) {
        return(FALSE,);
    }
    return check_owner_amount(index + 1, tokens_len, token_ids, token_values, caller_balances);
}

// upack data
// parse data, index, mask_size
func unpack_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(data: felt, index: felt, mask_size: felt) -> (score: felt) {
    alloc_locals;

    // 1. Create a 8-bit mask at and to the left of the index
    // E.g., 000111100 = 2**2 + 2**3 + 2**4 + 2**5
    // E.g.,  2**(i) + 2**(i+1) + 2**(i+2) + 2**(i+3) = (2**i)(15)
    let (power) = pow(2, index);
    // 1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256 + 512 + 1024 + 2048 = 15
    let mask = mask_size * power;

    // 2. Apply mask using bitwise operation: mask AND data.
    let (masked) = bitwise_and(mask, data);

    // 3. Shift element right by dividing by the order of the mask.
    let (result, _) = unsigned_div_rem(masked, power);

    return (score=result);
}

// given two arrays of length `len` which can be though of as key-value mapping split
// into `keys` and `values`, the function computes the sum of values by key
// it returns a Cairo dict
//
// given input
// len = 4
// keys = ["a", "c", "d", "c"]
// values = [2, 2, 2, 2]
//
// the result is
// d_len = 3
// d = {"a": 2, "c": 4, "d": 2}
func sum_values_by_key{range_check_ptr}(len: felt, keys: felt*, values: felt*) -> (
    d_len: felt, d: DictAccess*
) {
    alloc_locals;

    let (local dict_start: DictAccess*) = default_dict_new(default_value=0);

    let (dict_end: DictAccess*) = sum_values_by_key_loop(dict_start, len, keys, values);

    let (finalized_dict_start, finalized_dict_end) = default_dict_finalize(dict_start, dict_end, 0);

    // figure out the size of the dict, because it's needed to return an array of DictAccess objects
    let ptr_diff = [ap];
    ptr_diff = finalized_dict_end - finalized_dict_start, ap++;
    tempvar unique_keys = ptr_diff / DictAccess.SIZE;

    return (unique_keys, finalized_dict_start);
}

// helper function for sum_values_by_key, doing the recursive looping
func sum_values_by_key_loop{range_check_ptr}(
    dict: DictAccess*, len: felt, keys: felt*, values: felt*
) -> (dict_end: DictAccess*) {
    alloc_locals;

    if (len == 0) {
        return (dict,);
    }

    let (current: felt) = dict_read{dict_ptr=dict}(key=[keys]);
    let updated = current + [values];
    dict_write{dict_ptr=dict}(key=[keys], new_value=updated);

    return sum_values_by_key_loop(dict, len - 1, keys + 1, values + 1);
}