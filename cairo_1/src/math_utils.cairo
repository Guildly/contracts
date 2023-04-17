

mod MathUtils {
    use array::ArrayTrait;
    fn array_sum(arr: @Array<felt252>, mut index: usize, mut sum: felt252) -> felt252 {
        loop {
            match gas::withdraw_gas_all(get_builtin_costs()) {
                Option::Some(_) => {
                },
                Option::None(_) => {
                    let mut err_data = array::array_new();
                    err_data.append('Out of gas');
                    panic(err_data)
                },
            }
            sum += *arr.at(index);
            if index == 0_usize {
                break sum;
            }
            index -= 1_usize;
        }
    }

    fn array_product(arr: @Array<felt252>, mut index: usize, mut product: felt252) -> felt252 {
        loop {
            match gas::withdraw_gas_all(get_builtin_costs()) {
                Option::Some(_) => {
                },
                Option::None(_) => {
                    let mut err_data = array::array_new();
                    err_data.append('Out of gas');
                    panic(err_data)
                },
            }
            product *= *arr.at(index);
            if index == 0_usize {
                break product;
            }
            index -= 1_usize;
        }
    }
}
