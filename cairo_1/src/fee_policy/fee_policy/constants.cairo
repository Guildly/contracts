#[derive(Copy, Drop, PartialEq, Serde)]
enum NetAssetFlow {
    POSITIVE: (),
    NEGATIVE: (),
    NEUTRAL: (),
}

mod ShiftSplit {
    const _1: felt252 = 0;
    const _2: felt252 = 16384;
    const _3: felt252 = 268435456;
}

mod Recipient {
    const OWNER: u8 = 1;
    const CALLER: u8 = 2;
    const ADMIN: u8 = 3;
}
