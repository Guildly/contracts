%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

@view
func array_product{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(
        arr_len: felt,
        arr: felt*
    ) -> (product: felt):
    if arr_len == 0:
        return (product=1)
    end

    let (product_of_rest) = array_product(arr_len=arr_len - 1, arr=arr + 1)
    return (product=[arr] * product_of_rest)
end

@view
func array_sum{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(
        arr_len: felt,
        arr: felt*
    ) -> (sum: felt):
    if arr_len == 0:
        return (sum=0)
    end

    let (sum_of_rest) = array_sum(arr_len=arr_len - 1, arr=arr + 1)
    return (sum=[arr] + sum_of_rest)
end