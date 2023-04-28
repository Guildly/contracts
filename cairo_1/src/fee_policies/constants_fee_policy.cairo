mod NetAssetFlow {
    const POSITIVE: felt252 = 1;
    const NEGATIVE: felt252 = 2;
    const NEUTRAL: felt252 = 3;
}

mod ShiftSplit {
    const _1: felt252 = 0;
    const _2: felt252 = 16384;
    const _3: felt252 = 268435456;
}

mod Recipient {
    const OWNER: usize = 1;
    const CALLER: usize = 2;
    const ADMIN: usize = 3;
}