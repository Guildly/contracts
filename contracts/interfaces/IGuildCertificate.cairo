%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IGuildCertificate:

    func balanceOf(
            owner: felt
        ) -> (
            balance: Uint256
        ):
    end

    func get_certificate_id(
            owner: felt,
            guild: felt
        ) -> (
            certificate_id: Uint256
        ):
    end

    func get_role(
        certificate_id: Uint256
    ) -> (
        role: felt
    ):
    end

    func mint(
            to: felt,
            guild: felt,
            role: felt
        ):
    end

    func burn(
            token_id: Uint256
        ):
    end

    func add_token_data(
            certificate_id: Uint256,
            token: felt,
            token_id: Uint256,
            amount: Uint256
        ):
    end

    func change_token_data(
            certificate_id: Uint256,
            token: felt,
            token_id: Uint256,
            new_amount: Uint256
        ):
    end

    func check_token_data(
            certificate_id: Uint256,
            token: felt,
            token_id: Uint256
        ) -> (
            bool: felt
        ):
    end
end