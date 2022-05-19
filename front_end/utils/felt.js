import BN from "bn.js"

const P = new BN("800000000000011000000000000000000000000000000000000000000000001", 16)

export function feltToString(felt) {
    const newStrB = Buffer.from(felt.toString(16), 'hex')
    return newStrB.toString()
}

export function stringToFelt(str) {
    return "0x" + new Buffer.from(str).toString('hex')
}

export function toNegativeNumber(felt) {
    const added = felt.sub(P);
    return (added.abs() < felt.abs())
        ? added
        : felt;
}