%lang starknet

from starkware.cairo.common.uint256 import Uint256

struct Permission {
    to: felt,
    selector: felt,
}

struct CallArray {
    to: felt,
    selector: felt,
    data_offset: felt,
    data_len: felt,
}

@contract_interface
namespace Controller {
    func initializer(arbiter_address: felt, proxy_admin: felt) {
    }
    func set_address_for_module_id(module_id: felt, module_address: felt) {
    }
}

@contract_interface
namespace GuildManager {
    func initializer(
        guild_proxy_class_hash_: felt, guild_class_hash_: felt, controller: felt, proxy_admin: felt
    ) {
    }
    func deploy_guild(name: felt, certificate_address: felt) -> (contract_address: felt) {
    }
}

@contract_interface
namespace Guild {
    func whitelist_member(address: felt, role: felt) {
    }
    func join() {
    }
    func set_fee_policy(policy_id: felt, caller_split: felt, owner_split: felt) {
    }
    func deposit(token_standard: felt, token_address: felt, token_id: Uint256, amount: Uint256) {
    }
    func initialize_permissions(permissions_len: felt, permissions: Permission*) {
    }
    func execute_transactions(
        call_array_len: felt,
        call_array: CallArray*,
        calldata_len: felt,
        calldata: felt*,
        nonce: felt,
    ) {
    }
}

@contract_interface
namespace Certificate {
    func initializer(name: felt, symbol: felt, guild_manager: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace PolicyManager {
    func initializer(module_controller: felt, proxy_admin: felt) {
    }
    func add_policy(policy_id: felt, to: felt, selector: felt) {
    }
}

@contract_interface
namespace ResourcesPolicy {
    func initializer(
        resources_address: felt,
        realms_address: felt,
        certificate_address: felt,
        policy_manager: felt,
        proxy_admin: felt,
    ) {
    }
}
