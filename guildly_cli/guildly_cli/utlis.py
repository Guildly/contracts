def to_uint(a):
    """Takes in value, returns uint256-ish tuple."""
    return (a & ((1 << 128) - 1), a >> 128)

def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")

def strhex_as_strfelt(strhex: str):
    """Converts a string in hex format to a string in felt format"""
    if strhex is not None:
        return str(int(strhex, 16))
    else:
        print("strhex address is None.")
