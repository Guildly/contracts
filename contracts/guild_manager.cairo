%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    deploy, 
    get_caller_address, 
    call_contract
)
from contracts.lib.math_utils import MathUtils

from starkware.cairo.common.bool import TRUE, FALSE
from contracts.lib.role import GuildRoles

from contracts.interfaces.IGuildCertificate import IGuildCertificate

from openzeppelin.upgrades.library import Proxy

#
# Constants
#

const INITIALIZE_SELECTOR = 1295919550572838631247819983596733806859788957403169325509326258146877103642

#
# Structs
#

struct ProxyDeployData:
    member implementation : felt
    member selector : felt
    member calldata_len : felt
    member calldata : felt*
end

#
# Storage variables
#

@storage_var
func salt() -> (value : felt):
end

@storage_var
func guild_proxy_class_hash() -> (value : felt):
end

@storage_var
func guild_class_hash() -> (value : felt):
end

@storage_var
func is_guild(address : felt) -> (res : felt):
end


#
# Events
#

@event
func GuildContractDeployed(name : felt, master : felt, contract_address : felt):
end

#
# Initialize & upgrade
#

@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    guild_proxy_class_hash_ : felt, guild_class_hash_ : felt, proxy_admin : felt
):
    guild_proxy_class_hash.write(value=guild_proxy_class_hash_)
    guild_class_hash.write(value=guild_class_hash_)
    Proxy.initializer(proxy_admin)
    return ()
end

@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    implementation : felt
):
    Proxy.assert_only_admin()
    Proxy._set_implementation_hash(implementation)
    return ()
end

#
# Externals
#

@external
func deploy_guild_proxy_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt, guild_certificate : felt
) -> (contract_address : felt):
    let (current_salt) = salt.read()
    let (proxy_class_hash) = guild_proxy_class_hash.read()
    let (class_hash) = guild_class_hash.read()
    let (caller_address) = get_caller_address()
    let (proxy_admin) = Proxy.get_admin()
    let (deploy_calldata : felt*) = alloc()
    assert deploy_calldata[0] = class_hash
    let (contract_address) = deploy(
        class_hash=proxy_class_hash,
        contract_address_salt=current_salt,
        constructor_calldata_size=1,
        constructor_calldata=deploy_calldata,
        deploy_from_zero=0,
    )
    salt.write(value=current_salt + 1)

    is_guild.write(contract_address, TRUE)

    let (initialize_calldata : felt*) = alloc()
    assert initialize_calldata[0] = name
    assert initialize_calldata[1] = caller_address
    assert initialize_calldata[2] = guild_certificate
    assert initialize_calldata[3] = proxy_admin

    let res = call_contract(
        contract_address=contract_address,
        function_selector=INITIALIZE_SELECTOR,
        calldata_size=4,
        calldata=initialize_calldata,
    )

    GuildContractDeployed.emit(name=name, master=caller_address, contract_address=contract_address)

    return (contract_address)
end

@view
func get_is_guild{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
) -> (value : felt):
    let (value) = is_guild.read(address)
    return (value)
end