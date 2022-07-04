%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    uint256_lt
)

from contracts.utils.constants import FALSE, TRUE
from contracts.interfaces.IGuildManager import IGuildManager

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.ERC165 import ERC165

from openzeppelin.access.ownable import Ownable

#
# Structs
#

struct CertificateTokenData:
    member token: felt
    member token_id: felt
    member amount: felt
end

#
# Storage variables
#

@storage_var
func _guild_manager() -> (res : felt):
end

@storage_var
func _certificate_id_count() -> (res : Uint256):
end

@storage_var
func _certificate_id(owner : felt, guild : felt) -> (res : Uint256):
end

@storage_var
func _role(certificate_id: Uint256) -> (res: felt):
end

# @storage_var
# func _certificate_tokens_data_len(certificate_id: Uint256) -> (res: felt):
# end

# @storage_var
# func _certificate_tokens_data(certificate_id: Uint256, index: felt) -> (res: CertificateTokenData):
# end

@storage_var
func _certificate_token_amount(certificate_id: Uint256, token: felt, token_id: Uint256) -> (res: Uint256):
end

@storage_var
func _certificate_token_data(certificate_id: felt) -> (res: CertificateTokenData):
end

#
# Guards
#

func assert_only_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    let (caller) = get_caller_address()
    let (guild_manager) = _guild_manager.read()
    IGuildManager.check_valid_contract(guild_manager, caller)
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
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC721.name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC721.symbol()
    return (symbol)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC721.balance_of(owner)
    return (balance)
end

@view
func ownerOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (owner: felt):
    let (owner: felt) = ERC721.owner_of(tokenId)
    return (owner)
end

@view
func tokenURI{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (tokenURI: felt):
    let (tokenURI: felt) = ERC721.token_uri(tokenId)
    return (tokenURI)
end

@view
func get_certificate_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner : felt, guild : felt) -> (certificate_id : Uint256):
   let (value) =  _certificate_id.read(owner, guild)
   return (value)
end

@view
func get_role{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(certificate_id: Uint256) -> (role: felt):
    let (value) = _role.read(certificate_id)
    return (value)
end

# @view 
# func get_guild{
#         syscall_ptr : felt*,
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr
#     }(token_id : Uint256) -> (guild : felt):
#     let (certificate_data) = _certificate_data.read(token_id)
#     let fund = certificate_data.fund
#     return (fund)
# end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
        guild_manager: felt
    ):
    ERC721.initializer(name, symbol)
    _guild_manager.write(guild_manager)
    return ()
end

#
# External
#

@external
func setTokenURI{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256, tokenURI: felt):
    assert_only_owner()
    ERC721._set_token_uri(tokenId, tokenURI)
    return ()
end

@external
func transfer_ownership{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(new_owner: felt):
    Ownable.transfer_ownership(new_owner)
    return ()
end

@external
func mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, guild: felt, role: felt):
    assert_only_owner()

    let (certificate_count) = _certificate_id_count.read()
    let (new_certificate_id, _) = uint256_add(certificate_count, Uint256(1,0))
    _certificate_id_count.write(new_certificate_id)

    _certificate_id.write(to, guild, new_certificate_id)
    _role.write(new_certificate_id, role)

    ERC721._mint(to, new_certificate_id)
    return ()
end

@external
func update_role{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(certificate_id: Uint256, role: felt):
    Ownable.assert_only_owner()

    _role.write(certificate_id, role)
    return()
end


@external
func burn{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(certificate_id: Uint256):
    ERC721.assert_only_token_owner(certificate_id)
    ERC721._burn(certificate_id)
    return ()
end

@external
func guild_burn{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(certificate_id: Uint256):
    assert_only_owner()
    ERC721._burn(certificate_id)
    return ()
end

@external
func add_token_data{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        certificate_id: Uint256,
        token: felt,
        token_id: Uint256,
        amount: Uint256
    ):
    assert_only_owner()

    _certificate_token_amount.write(certificate_id, token, token_id, amount)

    # let data = CertificateTokenData(
    #     token=token,
    #     token_id=token_id,
    #     amount=amount
    # )
    # _certificate_token_data.write(certificate_id, data)

    return ()
end

@external
func change_token_data{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        certificate_id: Uint256,
        token: felt,
        token_id: Uint256,
        new_amount: Uint256
    ):
    assert_only_owner()

    _certificate_token_amount.write(certificate_id, token, token_id, new_amount)

    return ()
end

@external
func check_token_data{        
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        certificate_id: Uint256,
        token: felt,
        token_id: Uint256
    ) -> (
        bool: felt
    ):
    alloc_locals
    assert_only_owner()
    let (amount) = _certificate_token_amount.read(certificate_id, token, token_id)
    let (check_amount) = uint256_lt(Uint256(0,0),amount)
    return(check_amount)
end

