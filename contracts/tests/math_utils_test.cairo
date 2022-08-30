%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from contracts.lib.math_utils import MathUtils

@view
func test_array_sum{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    arr_len : felt, arr : felt*
) -> (sum : felt):
    let (sum) = MathUtils.array_sum(arr_len, arr)
    return (sum)
end

@view
func test_array_product{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    arr_len : felt, arr : felt*
) -> (product : felt):
    let (product) = MathUtils.array_product(arr_len, arr)
    return (product)
end

@view
func test_uint256_array_sum{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    arr_len : felt, arr : Uint256*
) -> (sum : Uint256):
    let (sum) = MathUtils.uint256_array_sum(arr_len, arr)
    return (sum)
end

@view
func test_uint256_array_product{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    arr_len : felt, arr : Uint256*
) -> (product : Uint256):
    let (product) = MathUtils.uint256_array_product(arr_len, arr)
    return (product)
end
