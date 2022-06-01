export function useDisplayName(account) {
    if (account === undefined)
        return "unknown";
    return account.substring(0, 6) + "..." + account.substring(account.length - 4);
}

export function validate256BitHash(str) {
    // Regular expression to check if string is a SHA256 hash
    const regexExp = /^0x[a-fA-F0-9]{40}$/
    return regexExp.test(str);
}