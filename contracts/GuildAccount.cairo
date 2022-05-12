# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin


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
func _guild_master() -> (res: felt):
end

@storage_var
func _allowed_contracts_len() -> (res: felt):
end

@storage_var
func _allowed_contracts(index: felt) -> (res: felt):
end

@storage_var
func _allowed_functions_len() -> (res: felt):
end

@storage_var
func _allowed_functions(index: felt) -> (res: felt):
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
        master: felt,
        guild_certificate: felt
    ):
    _guild_master.write(master)
    _guild_certificate.write(guild_certificate)

    # Account_initializer(public_key)
    return()
end

@external
func initialize_owners{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        owners_len: felt,
        owners: felt*
    ):
    require_master()

    _initialize_owners(
        owners_index=0,
        owners_len=owners_len,
        owners=owners
    )
    return ()
end


func _initialize_owners{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        owners_index: felt,
        owners_len: felt,
        owners: felt*
    ):
    if owners_index == owners_len:
        return ()
    end

    let (guild_certificate) = _guild_certificate.read()
    let (contract_address) = get_contract_address()
    IGuildCertificate.mint(
        contract_address=guild_certificate, 
        to=owners[owners_index], 
        guild=contract_address,
        role=Role.OWNER
    )

    _initialize_owners(owners_index=owners_index + 1, owners_len=owners_len, owners=owners)
    return ()
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

#
# Storage helpers
#

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
    _allowed_contracts.write(index=contracts_index, value=contracts[contracts_index])
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
        function_selectors: felt*
    ):
    if function_selectors_index == function_selectors_len:
        return ()
    end

     # Write the current iteration to storage
    _allowed_functions.write(index=function_selectors_index, value=[function_selectors])
    # Recursively write the rest
    _set_allowed_functions(
        function_selectors_index=function_selectors_index + 1, 
        function_selectors_len=function_selectors_len, 
        function_selectors=function_selectors + 1
    )
    return ()
end


#
# Externals
#

@view
func get_nonce{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res) = _current_nonce.read()
    return (res=res)
end

@external
func add_guild_members{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        members_len: felt,
        members: felt*
    ):
    _add_guild_members(members_index=0, members_len=members_len, members=members)
    return ()
end

func _add_guild_members{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        members_index: felt,
        members_len: felt,
        members: felt*    
    ):
    let (guild_certificate) = _guild_certificate.read()
    let (contract_address) = get_contract_address()
    IGuildCertificate.mint(
        contract_address=guild_certificate,
        to=members[members_index], 
        guild=contract_address,
        role=Role.MEMBER
    )

    _add_guild_members(members_index=members_index + 1, members_len=members_len, members=members)
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
func set_permissions{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        contracts_len: felt, 
        contracts: felt*,
        function_selectors_len: felt,
        function_selectors: felt*
    ):
    require_master()

    _set_allowed_contracts(
        contracts_index=0, 
        contracts_len=contracts_len, 
        contracts=contracts
    )
    _set_allowed_functions(
        function_selectors_index=0, 
        function_selectors_len=function_selectors_len, 
        function_selectors=function_selectors
    )
    return ()
end


func check_permitted_call{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(        
        to: felt,
        function_selector: felt
    ):
    let (allowed_contracts_len) = _allowed_contracts_len.read()
    _check_permitted_to(index=0, allowed_contracts_len=allowed_contracts_len, to=to)

    let (allowed_functions_len) = _allowed_functions_len.read()
    _check_permitted_selector(index=0, allowed_functions_len=allowed_functions_len, selector=function_selector)
    
    return ()
end

func _check_permitted_to{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(
        index: felt,
        allowed_contracts_len: felt,
        to: felt
    ):
    if index == allowed_contracts_len:
        return ()
    end
    
    let (allowed_contract) = _allowed_contracts.read(index)

    with_attr error_message("Contract is not permitted"):
        assert allowed_contract = to
    end

    _check_permitted_to(
        index=index + 1,
        allowed_contracts_len=allowed_contracts_len,
        to=to
    )
    return ()
end

func _check_permitted_selector{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(
        index: felt,
        allowed_functions_len: felt,
        selector: felt
    ):
    if index == allowed_functions_len:
        return ()
    end
    
    let (allowed_function) = _allowed_functions.read(index)
    with_attr error_mesage("Function is not permitted"):
        assert allowed_function = selector
    end

    _check_permitted_selector(
        index=index + 1,
        allowed_functions_len=allowed_functions_len,
        selector=selector
    )
    return ()
end