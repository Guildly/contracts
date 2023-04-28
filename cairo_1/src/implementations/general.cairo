use array::ArrayTrait;
use array::SpanTrait;
use serde::Serde;
use openzeppelin::utils::check_gas;

impl ArraySpanSerde of Serde::<Array<Span<felt252>>> {
    fn serialize(ref output: Array<felt252>, mut input: Array<Span<felt252>>) {
        Serde::<usize>::serialize(ref output, input.len());
        serialize_array_span_helper(ref output, input);
    }
    fn deserialize(ref serialized: Span<felt252>) -> Option<Array<Span<felt252>>> {
        let length = *serialized.pop_front()?;
        let mut arr = ArrayTrait::new();
        deserialize_array_span_helper(ref serialized, arr, length)
    }
}

fn serialize_array_span_helper(ref output: Array<felt252>, mut input: Array<Span<felt252>>) {
    check_gas();
    match input.pop_front() {
        Option::Some(value) => {
            Serde::<Span<felt252>>::serialize(ref output, value);
            serialize_array_span_helper(ref output, input);
        },
        Option::None(_) => {},
    }
}

fn deserialize_array_span_helper(
    ref serialized: Span<felt252>, mut curr_output: Array<Span<felt252>>, remaining: felt252
) -> Option<Array<Span<felt252>>> {
    if remaining == 0 {
        return Option::Some(curr_output);
    }
    check_gas();
    curr_output.append(Serde::<Span<felt252>>::deserialize(ref serialized)?);
    deserialize_array_span_helper(ref serialized, curr_output, remaining - 1)
}