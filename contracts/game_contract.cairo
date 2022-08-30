%lang starknet


from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_contract_address

from contracts.interfaces.IExperiencePoints import IExperiencePoints
from openzeppelin.token.erc721.IERC721 import IERC721

from starkware.cairo.common.uint256 import Uint256, uint256_lt
from starkware.cairo.common.bool import TRUE, FALSE


#
# Storage variables
#

@storage_var
func _token() -> (res: felt):
end

@storage_var
func _goblin_kill_count(guild: felt) -> (res: felt):
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
func get_goblin_kill_count{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(guild: felt) -> (res: felt):
    let (val) = _goblin_kill_count.read(guild)
    return (val)
end

#
# Actions
#

@external
func kill_goblin{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> ():
    alloc_locals
    let (caller) = get_caller_address()
    let (token) = _token.read()
    let (balance) = IERC721.balanceOf(contract_address=token, owner=caller)
    let (check_balance) = uint256_lt(Uint256(0,0), balance)
    with_attr error_mesage("Game Contract: Owner does not hold token."):
        assert check_balance = TRUE
    end
    let (goblin_kill_count) = _goblin_kill_count.read(caller)
    _goblin_kill_count.write(caller, goblin_kill_count + 1)
    return()
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
    with_attr error_mesage("Game Contract: Caller is not owner"):
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
