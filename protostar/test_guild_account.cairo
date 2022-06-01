%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from contracts.GuildAccount import set_permission

@external
func test_set_permissions{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local contract_address : felt
    # We deploy a contract and put its address into a local variable. Second argument is calldata array
    %{ ids.contract_address = deploy_contract("./contracts/GuildAccount.cairo").contract_address %}

    return ()
end