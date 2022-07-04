%lang starknet


from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_contract_address

from contracts.interfaces.IExperiencePoints import IExperiencePoints
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from starkware.cairo.common.uint256 import Uint256


from contracts.utils.constants import FALSE, TRUE

#
# Storage variables
#

@storage_var
func _token() -> (res: felt):
end

@storage_var
func _character_name(account: felt) -> (res: felt):
end

@storage_var
func _door_opened(account: felt) -> (res: felt):
end

@storage_var
func _points_contract() -> (res: felt):
end

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token: felt, points_contract: felt):
    _token.write(token)
    _points_contract.write(points_contract)
    return ()
end

#
# Getters
#

@view
func get_character_name{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (res: felt):
    let (val) = _character_name.read(account)
    return (val)
end

@view
func get_door{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (res: felt):
    let (val) = _door_opened.read(account)
    return (val)
end

#
# Actions
#

@external
func set_character_name{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(val: felt) -> ():
    let (caller) = get_caller_address()
    _character_name.write(caller, val)
    return()
end

@external
func open_door{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256):
    let (caller_address) = get_caller_address()
    let (token) = _token.read()
    let (owner) = IERC721.ownerOf(contract_address=token, tokenId=token_id)
    with_attr error_mesage("Caller is not owner"):
        assert caller_address = owner
    end
    _door_opened.write(caller_address, TRUE)
    return ()
end

@external
func get_rewards{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        account: felt,
        val: felt,
        token_id: Uint256
    ):
    let (caller_address) = get_caller_address()
    let (token) = _token.read()
    let (owner) = IERC721.ownerOf(contract_address=token, tokenId=token_id)
    with_attr error_mesage("Caller is not owner"):
        assert caller_address = owner
    end

    distribute_points(account)
    return()
end

func distribute_points{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt):
    let (points_contract) = _points_contract.read()
    IExperiencePoints.mint(
        contract_address=points_contract,
        to=account,
        amount=Uint256(10,0)
    )
    return ()
end
