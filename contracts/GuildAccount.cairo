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

func require_owner_or_member{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (guild_certificate) = _guild_certificate.read()

    tempvar syscall_ptr: felt* = syscall_ptr
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

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC721_name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC721_symbol()
    return (symbol)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC721_balanceOf(owner)
    return (balance)
end

@view
func ownerOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (owner: felt):
    let (owner: felt) = ERC721_ownerOf(tokenId)
    return (owner)
end

@view
func getApproved{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (approved: felt):
    let (approved: felt) = ERC721_getApproved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, operator: felt) -> (isApproved: felt):
    let (isApproved: felt) = ERC721_isApprovedForAll(owner, operator)
    return (isApproved)
end

@view
func tokenURI{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (tokenURI: felt):
    let (tokenURI: felt) = ERC721_tokenURI(tokenId)
    return (tokenURI)
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

@external
func approve{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    ERC721_approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        from_: felt, 
        to: felt, 
        tokenId: Uint256
    ):
    ERC721_transferFrom(from_, to, tokenId)
    return ()
end

@external
func safeTransferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        from_: felt, 
        to: felt, 
        tokenId: Uint256,
        data_len: felt, 
        data: felt*
    ):
    ERC721_safeTransferFrom(from_, to, tokenId, data_len, data)
    return ()
end

@external
func setTokenURI{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256, tokenURI: felt):
    #Ownable_only_owner()
    ERC721_setTokenURI(tokenId, tokenURI)
    return ()
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

# @external
# func deposit_ERC721{
#         syscall_ptr : felt*, 
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr
#     }(
#         token: felt,
#         token_id: felt
#     ):
#     let (caller_address) = get_caller_address()
#     let (contract_address) = get_contract_address()

#     let (balance) = balanceOf(caller_address)

#     let (check_balance) = uint256_lt(0,balance)

#     if check_balance == TRUE:
#         let (account_nft_id) = _account_nft_id(caller_address)
#         let (account_nft_data) = _account_nft_data.read(account_nft_id)
#         let data = AccountNFTData(
#             tokens_len=tokens_len,
#             tokens=tokens,
#             token_ids_len=token_ids_len.
#             token_ids=token_ids
#         )
#     else:
#         let (account_nft_len) = _account_nft_data_len.read()
#         let (account_nft_id) = account_nft_len + 1
#         _account_nft_data_len.write(account_nft_id)


#     IERC721.transferFrom(
#         contract_address=token, 
#         from_=caller_address,
#         to=contract_address,
#         tokenId=token_id
#     )

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