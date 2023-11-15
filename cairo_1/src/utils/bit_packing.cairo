use quaireaux_math::fast_power;

mod BitPacking {
    fn unpack_data(data: felt252, index: felt252, mask_size: felt252) -> felt252 {
        // 1. Create a 8-bit mask at and to the left of the index
        // E.g., 000111100 = 2**2 + 2**3 + 2**4 + 2**5
        // E.g.,  2**(i) + 2**(i+1) + 2**(i+2) + 2**(i+3) = (2**i)(15)
        let power = fast_power(2, index);
        // 1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256 + 512 + 1024 + 2048 = 15
        let mask = mask_size * power;

        // 2. Apply mask using bitwise operation: mask AND data.
        let masked = bitand(mask, data);

        // 3. Shift element right by dividing by the order of the mask.
        masked / power
    }
}
