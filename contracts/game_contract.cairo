%lang starknet


from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_contract_address


from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from starkware.cairo.common.uint256 import Uint256

@storage_var
func _token() -> (res: felt):
end

@storage_var
func value() -> (res: felt):
end

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token: felt):
    _token.write(token)
    return ()
end

@view
func get_value{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):

    let (val) = value.read()
    return (val)
end

@external
func set_value_with_nft{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(val: felt, token_id: Uint256) -> ():
    let (caller_address) = get_caller_address()
    let (token) = _token.read()
    let (owner) = IERC721.ownerOf(contract_address=token, tokenId=token_id)
    with_attr error_mesage("Caller is not owner"):
        assert caller_address = owner
    end

    value.write(val)
    return()
end
