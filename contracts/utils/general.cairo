from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.pow import pow

// unpack data
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