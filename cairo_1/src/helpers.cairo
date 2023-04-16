mod Helpers {
    #[view]
    fn find_value(arr: Array<felt252>, mut index: usize, value: felt252) -> u32 {
        loop {
            if index.into() == arr.len() {
                assert(1 == 0, 'Value not found');
            }
            if arr[index] == value {
                return (index=arr_index);
            }
            index += 1_usize;
        }

    }
}