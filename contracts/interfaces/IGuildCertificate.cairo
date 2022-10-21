%lang starknet

from starkware.cairo.common.uint256 import Uint256

//
// Structs
//

struct Token {
    token_standard: felt,
    token: felt,
    token_id: Uint256,
    amount: Uint256,
}


@contract_interface
namespace IGuildCertificate {

    func balanceOf(
            owner: felt
        ) -> (
            balance: Uint256
        ){
    }

    func get_certificate_id(
            owner: felt,
            guild: felt
        ) -> (
            certificate_id: Uint256
        ){
    }

    func get_role(
        certificate_id: Uint256
    ) -> (
        role: felt
    ){
    }

    func get_tokens(
        certificate_id: Uint256
    ) -> (
        tokens_len: felt,
        tokens: Token*
    ){
    }

    func get_token_amount(
        certificate_id: Uint256,
        token_standard: felt,
        token: felt,
        token_id: Uint256
    ) -> (
        amount: Uint256
    ){
    }

    func get_token_owner(
        token_standard: felt, 
        token: felt, 
        token_id: Uint256
    ) -> (
        owner: felt
    ){
    }

    func check_token_exists(
            certificate_id: Uint256,
            token_standard: felt,
            token: felt,
            token_id: Uint256
        ) -> (
            bool: felt
        ){
    }

    func check_tokens_exist(
            certificate_id: Uint256
        ) -> (
            bool: felt
        ){
    }

    func mint(
            to: felt,
            guild: felt,
            role: felt
        ){
    }

    func update_role(
            certificate_id: Uint256,
            role: felt
        ){
    }

    func burn(
            account: felt,
            guild: felt
        ){
    }

    func guild_burn(
            account: felt,
            guild: felt
        ){
    }

    func add_token_data(
            certificate_id: Uint256,
            token_standard: felt,
            token: felt,
            token_id: Uint256,
            amount: Uint256
        ){
    }

    func change_token_data(
            certificate_id: Uint256,
            token_standard: felt,
            token: felt,
            token_id: Uint256,
            new_amount: Uint256
        ){
    }
}