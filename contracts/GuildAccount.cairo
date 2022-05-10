# SPDX-License-Identifier: MIT
# mostly based on https://github.com/OpenZeppelin/cairo-contracts/tree/43b30a69fe2c4e12d43ccbc9097d9b064c3229d4/src/openzeppelin
# with a few tweaks to make it token gated
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from contracts.guild_library import (
    AccountCallArray,
    Account_execute,
    Account_get_nonce,
    Account_initializer,
    Account_is_valid_signature,
    Account_get_token_owner,
    Account_execute_contract_caller,
    Call,
    from_call_array_to_call
)

from starkware.starknet.common.syscalls import (
    get_caller_address, get_contract_address
)

from openzeppelin.introspection.ERC165 import ERC165_supports_interface 
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721


from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_lt,
    uint256_add
)

# from contracts.library_ERC721 import (
#     ERC721_name,
#     ERC721_symbol,
#     ERC721_balanceOf,
#     ERC721_ownerOf,
#     ERC721_getApproved,
#     ERC721_isApprovedForAll,
#     ERC721_tokenURI,

#     ERC721_initializer,
#     ERC721_approve, 
#     ERC721_setApprovalForAll, 
#     ERC721_transferFrom,
#     ERC721_safeTransferFrom,
#     ERC721_mint,
#     ERC721_burn,
#     ERC721_only_token_owner,
#     ERC721_setTokenURI
# )

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

# struct CertificateData:
#     member owner: felt
#     member share: Uint256
#     member fund: felt
# end

struct AccountNFTData:
    member owner: felt
    member tokens_len: felt
    member tokens: felt*
    member token_ids_len: felt
    member token_ids: felt*
end


#
# Storage variables
#

@storage_var
func _account_nft_data_len() -> (res: Uint256):
end

@storage_var
func _account_nft_id(owner: felt) -> (res: Uint256):
end

# @storage_var
# func _account_nft_data(token_id : Uint256) -> (res: CertificateData):
# end

# @storage_var
# func _account_nft_data(token_id: Uint256) -> (res: AccountNFTData):
# end

@storage_var
func _account_nft_tokens_len(token_id: felt) -> (res: felt):
end

@storage_var
func _account_nft_tokens(token_id: Uint256, index: felt) -> (res: felt):
end

@storage_var
func _account_nft_token_ids_len(token_id: felt, token: felt) -> (res: felt):
end

@storage_var
func _account_nft_token_ids(token_id: felt, token: felt, index: felt) -> (res: felt):
end

@storage_var
func allowed_contracts_len() -> (res: felt):
end

@storage_var
func allowed_contracts(index: felt) -> (res: felt):
end

@storage_var
func allowed_functions_len() -> (res: felt):
end

@storage_var
func allowed_functions(index: felt) -> (res: felt):
end

@storage_var
func _token_ids_len() -> (res: Uint256):
end

@storage_var
func _guild_certificate() -> (res: felt):
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
        symbol: felt,
        owners_len: felt,
        owners: felt*,
        guild_certificate: felt
    ):
    let (contract_address)=get_contract_address()
    ERC721_initializer(name, symbol)
    

    # Account_initializer(public_key)
    initialize_owners(
        owners_index=0, 
        owners_len=owners_len, 
        owners=owners
    )
    return()
end

func initialize_owners{
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

    let (token_count) = _token_ids_len.read()
    let (new_token_id, _) = uint256_add(token_count, Uint256(1,0))
    _token_ids_len.write(new_token_id)
    ERC721_mint(owners[owners_index], new_token_id)

    initialize_owners(owners_index=owners_index + 1, owners_len=owners_len, owners=owners)
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
    allowed_contracts.write(index=contracts_index, value=contracts[contracts_index])
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
    allowed_functions.write(index=function_selectors_index, value=[function_selectors])
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

#this function just returns the current contract or user (public key) who controls this account
@view
func get_account_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res) = Account_get_token_owner()
    return (res=res)
end

@view
func get_nonce{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res) = Account_get_nonce()
    return (res=res)
end

@view
func is_valid_signature{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
        ecdsa_ptr: SignatureBuiltin*
    }(
        hash: felt,
        signature_len: felt,
        signature: felt*
    ) -> ():
    Account_is_valid_signature(hash, signature_len, signature)
    return ()
end

@view
func test_function{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (caller: felt):
    let (caller) = get_caller_address()
    return (caller)
end

@external
func add_guild_members{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(address: felt):
    let (token_id) = _token_ids_len.read()
    let (new_token_id) = token_id + 1
    ERC721_mint(address, new_token_id)
    _token_ids_len.write(new_token_id)
    return ()
end

func _add_guild_members{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
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
func execute_function{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
        ecdsa_ptr: SignatureBuiltin*
    }(
        call_array_len: felt,
        call_array: AccountCallArray*,
        calldata_len: felt,
        calldata: felt*,
        nonce: felt
    ) -> (response_len: felt, response: felt*):

    alloc_locals

    let (local caller) = get_caller_address()

    # check whether the function called is a permitted function
    # check_permitted_call(call_array_len, call_array, calldata_len, calldata)

    # if call originated from public key (wallet) then call as usual and check for signature
    # else call the corresponding function for contract caller (which checks for ownership of NFT only and not the signature)
    if caller == 0:

        let (response_len, response) = Account_execute(
            call_array_len,
            call_array,
            calldata_len,
            calldata,
            nonce
        )
        return (response_len=response_len, response=response)
    else:

        let (response_len, response) = Account_execute_contract_caller(
            caller,
            call_array_len,
            call_array,
            calldata_len,
            calldata,
            nonce
        )
        return (response_len=response_len, response=response)
    end


end

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
    _set_allowed_contracts(
        contracts_index=0, 
        contracts_len=contracts_len, 
        contracts=contracts
    )
    _set_allowed_functions(
        functions_selectors_index=0, 
        function_selectors_len=function_selectors_len, 
        function_selectors=function_selectors
    )
    return ()
end


# func check_permitted_call{
#         syscall_ptr : felt*, 
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr, 
#     }(        
#         call_array_len: felt,
#         call_array: AccountCallArray*,
#         calldata_len: felt,
#         calldata: felt*
#     ):
#     # TMP: Convert `AccountCallArray` to 'Call'.
#     let (calls : Call*) = alloc()
#     from_call_array_to_call(call_array_len, call_array, calldata, calls)
#     let calls_len = call_array_len
#     _check_permitted_call(calls_len, calls)
#     return ()
# end


# func _check_permitted_call{
#         syscall_ptr : felt*, 
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr, 
#     }(
#         calls_len: felt,
#         calls: felt*
#     ):
#     alloc_locals
#     if call_array_index == call_array_len:
#         return ()
#     end

#     # do the current call
#     let this_call: Call = [calls]
    
#     let (allowed_contracts_len) = allowed_contracts_len.read()
#     let (to) = [this_call].to
#     _check_permitted_to(index=0, allowed_contracts_len=allowed_contracts_len, to=to)

#     let (allowed_functions_len) = allowed_functions_len.read()
#     let (selector) = [this_call].selector
#     _check_permitted_selector(index=0, allowed_functions_len=allowed_functions_len, selector=selector)

#     _check_permitted_call(
#         calls_len - 1, 
#         calls + Call.SIZE
#     )
#     return ()
# end

# func _check_permitted_to{
#         syscall_ptr : felt*, 
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr, 
#     }(
#         index: felt,
#         account_contracts_len: felt,
#         to: felt
#     ):
#     if index == account_contracts_len:
#         return ()
#     end
    
#     let (allowed_contract) = allowed_contracts.read(index)
#     if allowed_contract == to:
#         return ()   
#     else:
#         error_message("Contract is not permitted")
#     end

#     _check_permitted_to(
#         index=index + 1,
#         account_contracts_len=account_contracts_len,
#         to=to
#     )
#     return ()
# end

# func _check_permitted_selector{
#         syscall_ptr : felt*, 
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr, 
#     }(
#         index: felt,
#         account_functions_len: felt,
#         to: felt
#     ):
#     if index == account_functions_len:
#         return ()
#     end
    
#     let (allowed_function) = allowed_functions.read(index)
#     if allowed_function == to:
#         return ()   
#     else:
#         error_mesage("Function is not permitted")
#     end

#     _check_permitted_selector(
#         index=index + 1,
#         account_functions_len=account_functions_len,
#         to=to
#     )
#     return ()
# end