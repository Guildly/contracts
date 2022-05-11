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

    func increase_shares(
            token_id: Uint256,
            amount: Uint256
        ):
    end

    func decrease_shares(
            token_id: Uint256,
            amount: Uint256
        ):
    end
end