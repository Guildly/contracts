mod MathUtils {
    use array::ArrayTrait;
    fn array_sum(arr: @Array<felt252>, mut index: usize, mut sum: felt252) -> felt252 {
        loop {
            sum += *arr.at(index);
            if index == 0_usize {
                break sum;
            }
            index -= 1_usize;
        }
    }

    fn array_product(arr: @Array<felt252>, mut index: usize, mut product: felt252) -> felt252 {
        loop {
            product *= *arr.at(index);
            if index == 0_usize {
                break product;
            }
            index -= 1_usize;
        }
    }
}
