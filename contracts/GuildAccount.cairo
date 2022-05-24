# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_le, assert_lt

from starkware.starknet.common.syscalls import (
    call_contract, 
    get_caller_address, 
    get_contract_address
)

from contracts.utils.constants import FALSE, TRUE

from openzeppelin.introspection.ERC165 import ERC165_supports_interface 
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721
from contracts.interfaces.IGuildCertificate import IGuildCertificate

from contracts.lib.role import Role

from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_lt,
    uint256_add
)

from openzeppelin.token.erc721.library import (
    ERC721_name,
    ERC721_symbol,
    ERC721_balanceOf,
    ERC721_ownerOf,
    ERC721_getApproved,
    ERC721_isApprovedForAll,
    ERC721_tokenURI,

    ERC721_initializer,
    ERC721_approve, 
    ERC721_setApprovalForAll, 
    ERC721_transferFrom,
    ERC721_safeTransferFrom,
    ERC721_mint,
    ERC721_burn,
    ERC721_only_token_owner,
    ERC721_setTokenURI
)

#
# Structs
#

# struct AccountNFTData:
#     member owner: felt
#     member tokens_len: felt
#     member tokens: felt*
#     member token_ids_len: felt
#     member token_ids: felt*
# end


#
# Storage variables
#

@storage_var
func _name() -> (res: felt):
end

@storage_var
func _guild_master() -> (res: felt):
end

@storage_var
func _whitelisted_role(account: felt) -> (res: felt):
end

@storage_var
func _allowed_contracts_len() -> (res: felt):
end

@storage_var
func _allowed_contracts(index: felt) -> (res: felt):
end

@storage_var
func _allowed_selectors_len(contract: felt) -> (res: felt):
end

@storage_var
func _allowed_selectors(contract: felt, index: felt) -> (res: felt):
end

@storage_var
func _guild_certificate() -> (res: felt):
end

@storage_var
func _current_nonce() -> (res: felt):
end

#
# Guards
#

func require_master{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (caller) = get_caller_address()
    let (master) = _guild_master.read()

    with_attr error_message("Caller is not guild master"):
        assert caller = master
    end
    return ()
end

func require_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (guild_certificate) = _guild_certificate.read()

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate,
        owner=caller_address,
        guild=contract_address
    )

    let (_role) = IGuildCertificate.get_role(contract_address=guild_certificate, certificate_id=certificate_id)

    with_attr error_message("Caller is not owner"):
        assert _role = Role.OWNER
    end
    return ()
end


func require_owner_or_member{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (guild_certificate) = _guild_certificate.read()

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate,
        owner=caller_address,
        guild=contract_address
    )

    let (check) = uint256_lt(Uint256(0,0),certificate_id)

    with_attr error_mesage("Caller must have access"):
        assert check = TRUE
    end
    return ()
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        master: felt,
        guild_certificate: felt
    ):
    _name.write(name)
    _guild_master.write(master)
    _guild_certificate.write(guild_certificate)

    # Account_initializer(public_key)
    return()
end

#
# Getters
#

@view
func supportsInterface{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(interfaceId: felt) -> (success: felt):
    let (success) = ERC165_supports_interface(interfaceId)
    return (success)
end

@view
func get_nonce{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res) = _current_nonce.read()
    return (res=res)
end

# @view
# func get_permissions{
#         syscall_ptr : felt*,
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr
#     }() -> (
#         permissions_len: felt,
#         permissions: felt*
#     ):
#     alloc_locals
#     let (allowed_contracts_len) = _allowed_contracts_len.read()
#     let (allowed_contracts) = alloc()

#     _get_allowed_contracts(
#         allowed_contracts_index=0,
#         allowed_contracts_len=allowed_contracts_len,
#         allowed_contracts=allowed_contracts
#     )

#     get_allowed_selectors(
#         allowed_contracts_index=0,
#         allowed_contracts_len=allowed_contracts_len,
#         allowed_contracts=allowed_contracts
#     )
#     return ()
# end

@view
func get_allowed_contracts{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (
        allowed_contracts_len: felt,
        allowed_contracts: felt*
    ):
    alloc_locals
    let (allowed_contracts_len) = _allowed_contracts_len.read()
    let (allowed_contracts) = alloc()

    _get_allowed_contracts(
        allowed_contracts_index=0,
        allowed_contracts_len=allowed_contracts_len,
        allowed_contracts=allowed_contracts
    )
    return (allowed_contracts_len, allowed_contracts)
end

func _get_allowed_contracts{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        allowed_contracts_index: felt,
        allowed_contracts_len: felt,
        allowed_contracts: felt*
    ):
    if allowed_contracts_index == allowed_contracts_len:
        return ()
    end

    let (allowed_contract) = _allowed_contracts.read(allowed_contracts_index)
    assert allowed_contracts[allowed_contracts_index] =  allowed_contract

    _get_allowed_contracts(
        allowed_contracts_index=allowed_contracts_index + 1,
        allowed_contracts_len=allowed_contracts_len,
        allowed_contracts=allowed_contracts
    )
    return ()
end

func get_allowed_selectors{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        allowed_contracts_index: felt,
        allowed_contracts_len: felt,
        allowed_contracts: felt*
    ):
    alloc_locals
    if allowed_contracts_index == allowed_contracts_len:
        return ()
    end
    let (allowed_selectors) = alloc()

    let (allowed_selectors_len) = _allowed_selectors_len.read(
        allowed_contracts[allowed_contracts_index]
    )

    _get_allowed_selectors(
        allowed_selectors_index=0,
        allowed_selectors_len=allowed_selectors_len,
        allowed_selectors=allowed_selectors,
        contract=allowed_contracts[allowed_contracts_index]
    )
    return ()
end

func _get_allowed_selectors{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        allowed_selectors_index: felt,
        allowed_selectors_len: felt,
        allowed_selectors: felt*,
        contract: felt
    ):
    if allowed_selectors_index == allowed_selectors_len:
        return ()
    end

    let (allowed_selector) = _allowed_selectors.read(
        contract,
        allowed_selectors_index
    )
    
    assert allowed_selectors[allowed_selectors_index] = allowed_selector

    _get_allowed_selectors(
        allowed_selectors_index=allowed_selectors_index + 1,
        allowed_selectors_len=allowed_selectors_len,
        allowed_selectors=allowed_selectors,
        contract=contract
    )

    return ()
end


#
# Storage helpers
#

func _whitelist_members{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        members_index: felt,
        members_len: felt,
        members: felt*,
        roles: felt*  
    ):
    if members_index == members_len:
        return ()
    end
    _whitelisted_role.write(members[members_index], roles[members_index])

    _whitelist_members(
        members_index=members_index + 1, 
        members_len=members_len, 
        members=members,
        roles=roles
    )
    return ()
end

func _set_allowed_contracts{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        contracts_index: felt,
        contracts_len: felt, 
        contracts: felt*
    ):
    if contracts_index == contracts_len:
        return ()
    end

     # Write the current iteration to storage
    _allowed_contracts.write(contracts_index, contracts[contracts_index])

    # Recursively write the rest
    _set_allowed_contracts(contracts_index=contracts_index + 1, contracts_len=contracts_len, contracts=contracts)
    return ()
end

func _set_allowed_functions{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        function_selectors_index: felt,
        function_selectors_len: felt,
        function_selectors: felt*,
        contract: felt
    ):
    if function_selectors_index == function_selectors_len:
        return ()
    end

    # Write the current iteration to storage
    _allowed_selectors.write(
        contract=contract, 
        index=function_selectors_index, 
        value=function_selectors[function_selectors_index]
    )
    # Recursively write the rest
    _set_allowed_functions(
        function_selectors_index=function_selectors_index + 1, 
        function_selectors_len=function_selectors_len, 
        function_selectors=function_selectors,
        contract=contract
    )
    return ()
end


#
# Externals
#

@external
func whitelist_members{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        members_len: felt,
        members: felt*,
        roles_len: felt,
        roles: felt*
    ):
    require_master()
    
    _whitelist_members(
        members_index=0, 
        members_len=members_len, 
        members=members,
        roles=roles
    )
    return ()
end

@external
func join{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    let (guild_certificate) = _guild_certificate.read()
    let (contract_address) = get_contract_address()
    let (caller_address) = get_caller_address()
    let (whitelisted_role) = _whitelisted_role.read(caller_address)
    with_attr error_mesage("Caller is not whitelisted"):
       assert_lt(0, whitelisted_role)
    end
    IGuildCertificate.mint(
        contract_address=guild_certificate,
        to=caller_address, 
        guild=contract_address,
        role=whitelisted_role
    )
    return ()
end

@external
func deposit_ERC721{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token: felt,
        token_id: Uint256
    ):
    require_owner()
    let (guild_certificate) = _guild_certificate.read()

    let amount: Uint256 = Uint256(1,0)

    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate,
        owner=caller_address,
        guild=contract_address
    )

    let (check_exists) = IGuildCertificate.check_token_data(
        contract_address=guild_certificate,
        certificate_id=certificate_id,
        token=token,
        token_id=token_id
    )

    with_attr error_message("Caller certificate already holds tokens"):
        assert check_exists = FALSE
    end

    # Does the transfer (Also checks they have the token)
    IERC721.transferFrom(
        contract_address=token, 
        from_=caller_address,
        to=contract_address,
        tokenId=token_id
    )

    IGuildCertificate.add_token_data(
        contract_address=guild_certificate,
        certificate_id=certificate_id,
        token=token,
        token_id=token_id,
        amount=amount
    )
    return ()
end

@external
func withdraw_ERC721{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token: felt,
        token_id: Uint256
    ):
    require_owner()
    let (guild_certificate) = _guild_certificate.read()

    let new_amount: Uint256 = Uint256(0,0)

    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate,
        owner=caller_address,
        guild=contract_address
    )

    let (check_exists) = IGuildCertificate.check_token_data(
        contract_address=guild_certificate,
        certificate_id=certificate_id,
        token=token,
        token_id=token_id
    )

    with_attr error_message("Caller certificate doesn't hold tokens"):
        assert check_exists = TRUE
    end

    IERC721.transferFrom(
        contract_address=token, 
        from_=contract_address,
        to=caller_address,
        tokenId=token_id
    )

    IGuildCertificate.change_token_data(
        contract_address=guild_certificate,
        certificate_id=certificate_id,
        token=token,
        token_id=token_id,
        new_amount=new_amount
    )
    return ()
end

@external
func execute_transaction{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        to : felt,
        function_selector : felt,
        calldata_len : felt,
        calldata : felt*
    ) -> (
        response_len: felt,
        response: felt*
    ):
    alloc_locals
    require_owner_or_member()

    let (caller) = get_caller_address()
    
    # Check the tranasction is permitted
    check_permitted_call(to, function_selector)

    # Update nonce
    let (nonce) = _current_nonce.read()
    _current_nonce.write(value=nonce + 1)
    
    # Actually execute it
    let response = call_contract(
        contract_address=to,
        function_selector=function_selector,
        calldata_size=calldata_len,
        calldata=calldata,
    )
    return (response_len=response.retdata_size, response=response.retdata)
end

@external
func set_permission{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        contract: felt,
        function_selectors_len: felt,
        function_selectors: felt*
    ):
    require_master()

    let (allowed_contracts_index) = _allowed_contracts_len.read()
    _allowed_contracts.write(allowed_contracts_index, contract)
    _allowed_contracts_len.write(allowed_contracts_index + 1)

    _allowed_selectors_len.write(contract, function_selectors_len)
    _set_allowed_functions(
        function_selectors_index=0, 
        function_selectors_len=function_selectors_len, 
        function_selectors=function_selectors,
        contract=contract
    )
    return ()
end

func check_permitted_call{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(        
        to: felt,
        selector: felt
    ):
    alloc_locals
    let (allowed_contracts_len) = _allowed_contracts_len.read()
    let (check_contracts) = alloc()
    _check_permitted_to(
        allowed_contracts_index=0, 
        allowed_contracts_len=allowed_contracts_len, 
        to=to,
        check_list=check_contracts
    )
    let (check_contracts_product) = array_product(
        arr_len=allowed_contracts_len,
        arr=check_contracts
    )
    with_attr error_mesage("Contract is not permitted"):
        assert check_contracts_product = 0
    end
    let (allowed_selectors_len) = _allowed_selectors_len.read(to)
    let (check_selectors) = alloc()
    _check_permitted_selector(
        allowed_selectors_index=0, 
        allowed_selectors_len=allowed_selectors_len, 
        selector=selector,
        contract=to,
        check_list=check_selectors
    )
    let (check_selectors_product) = array_product(
        arr_len=allowed_selectors_len,
        arr=check_selectors
    )
    with_attr error_mesage("Function is not permitted"):
        assert check_selectors_product = 0
    end   
    return ()
end

func _check_permitted_to{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(
        allowed_contracts_index: felt,
        allowed_contracts_len: felt,
        to: felt,
        check_list: felt*
    ):
    if allowed_contracts_index == allowed_contracts_len:
        return ()
    end
    
    let (allowed_contract) = _allowed_contracts.read(allowed_contracts_index)
    assert check_list[allowed_contracts_index] = allowed_contract - to

    _check_permitted_to(
        allowed_contracts_index=allowed_contracts_index + 1,
        allowed_contracts_len=allowed_contracts_len,
        to=to,
        check_list=check_list
    )
    return ()
end

func _check_permitted_selector{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(
        allowed_selectors_index: felt,
        allowed_selectors_len: felt,
        selector: felt,
        contract: felt,
        check_list: felt*
    ):
    if allowed_selectors_index == allowed_selectors_len:
        return ()
    end
    
    let (allowed_selector) = _allowed_selectors.read(
        contract, 
        allowed_selectors_index
    )
    let check_selector = allowed_selector - selector
    assert check_list[allowed_selectors_index] = check_selector

    _check_permitted_selector(
        allowed_selectors_index=allowed_selectors_index + 1,
        allowed_selectors_len=allowed_selectors_len,
        selector=selector,
        contract=contract,
        check_list=check_list
    )
    return ()
end

@view
func array_product{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(
        arr_len: felt,
        arr: felt*
    ) -> (product: felt):
    if arr_len == 0:
        return (product=1)
    end

    let (product_of_rest) = array_product(arr_len=arr_len - 1, arr=arr + 1)
    return (product=[arr] * product_of_rest)
end

@view
func array_sum{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(
        arr_len: felt,
        arr: felt*
    ) -> (sum: felt):
    if arr_len == 0:
        return (sum=0)
    end

    let (sum_of_rest) = array_sum(arr_len=arr_len - 1, arr=arr + 1)
    return (sum=[arr] + sum_of_rest)
end