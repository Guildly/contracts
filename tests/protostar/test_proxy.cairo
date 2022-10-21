%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    
}