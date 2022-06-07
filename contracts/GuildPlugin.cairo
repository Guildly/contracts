# SPDX-License-Identifier: MIT

%lang starknet

from openzeppelin.token.erc721.interfaces.IERC721 import IERC721
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.hash_state import (
    HashState, hash_finalize, hash_init, hash_update, hash_update_single
)
from starkware.starknet.common.syscalls import (
    get_tx_info
)

@contract_interface
namespace IAccount:
    func is_valid_signature(hash: felt, sig_len: felt, sig: felt*):
    end
end

# Tmp struct introduced whuke we wait for Cairo
# to support passing '[Call]' to __execute__
struct CallArray:
    member to: felt
    member selector: felt
    member data_offset: felt
    member data_len: felt
end

#
# Storage variables
#

#
# Actions
#

@external
func delegate_validate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        plugin_data_len: felt,
        plugin_data: felt*,
        call_array_len: felt,
        call_array: CallArray*,
        calldata_len: felt,
        calldata: felt*
    ):
    alloc_locals
    let (tx_info) = get_tx_info()

    let guild = [plugin_data]
    let token_id = [plugin_data + 1]

    let (hash) = compute_hash(guild, token_id)

    with_attr error_message("unauthorised guild call"):
        IAccount.is_valid_signature(
            contract_address=tx_info.account_contract_address,
            hash=hash,
            sig_len=plugin_data_len - 2,
            sig=plugin_data + 2
        )
    end
    # # check if the tx is signed by the guild
    # with_attr error_message("session key signature invalid"):
    #     verify_ecdsa_signature(
    #         message=tx_info.transaction_hash,
    #         public_key=session_key,
    #         signature_r=tx_info.signature[0],
    #         signature_s=tx_info.signature[1]
    #     )
    # end

    # IERC721.transferFrom(
    #     contract_address=token,
    #     from_=guild,
    #     to=tx_info.account_contract_address,
    #     tokenId=token_id
    # )


    return ()
end

@external
func guildloan_ERC721{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    return ()
end

func compute_hash{pedersen_ptr: HashBuiltin*}(
        guild: felt, 
        token_id: felt
    ) -> (hash: felt):
    let hash_ptr = pedersen_ptr
    with hash_ptr:
        let (hash_state_ptr) = hash_init()
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, guild)
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, token_id)
        let (res) = hash_finalize(hash_state_ptr)
        let pedersen_ptr = hash_ptr
    end
    return (hash=res)
end