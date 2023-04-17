mod Helpers {
    use array::ArrayTrait;
    fn find_value(arr: @Array<felt252>, mut index: u32, value: felt252) -> felt252 {
        loop {
            if index == 0_u32 {
                assert(1 == 0, 'Value not found');
            }
            if *arr.at(index) == value {
                break index;
            }
            index += 1_u32;
        };
        *arr.at(index)
    }
}