use array::ArrayTrait;
use array::SpanTrait;
use starknet::StorageAccess;
use starknet::StorageBaseAddress;
use starknet::SyscallResult;
use starknet::storage_access;
use starknet::storage_read_syscall;
use starknet::storage_write_syscall;
use starknet::storage_base_address_from_felt252;
use starknet::storage_address_from_base_and_offset;
use traits::Into;
use traits::TryInto;
use option::OptionTrait;

#[derive(Serde)]
struct PolicyTarget {
    to: ContractAddress,
    selector: ContractAddress,
}

struct TokenBalances {
    token: felt252,
    balances: Array<u256>
}

struct TokenDifferences {
    token: felt252,
    differences: Array<u256>
}

#[derive(Copy, Drop, Serde)]
struct TokenDetails {
    token_standard: felt252,
    token: ContractAddress,
    ids: Array<u256>
}


impl PolicyTargetStorageAccess of StorageAccess::<PolicyTarget> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<PolicyTarget> {
        Result::Ok(
            PolicyTarget {
                to: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 0_u8)
                )?.try_into().unwrap(),
                selector: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 1_u8)
                )?.try_into().unwrap(),
            }
        )
    }

    fn write(address_domain: u32, base: StorageBaseAddress, value: PolicyTarget) -> SyscallResult::<()> {
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 0_u8), value.x.into()
        )?;
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 1_u8), value.y.into()
        )
    }
}

impl ArrayTokenBalancesDrop of Drop::<Array<TokenBalances>>;

impl ArrayTokenBalancesSerde of Serde::<Array<TokenBalances>> {
    fn serialize(ref output: Array<felt252>, mut input: Array<TokenBalances>) {
        Serde::<usize>::serialize(ref output, input.len());
        serialize_array_token_balances_helper(ref output, input);
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<Array<TokenBalances>> {
        let length = *serialized.pop_front()?;
        let mut arr = ArrayTrait::new();
        deserialize_array_token_balances_helper(ref serialized, arr, length)
    }
}

fn serialize_array_token_balances_helper(ref output: Array<felt252>, mut input: Array<TokenBalances>) {
    check_gas();
    match input.pop_front() {
        Option::Some(value) => {
            Serde::<TokenBalances>::serialize(ref output, value);
            serialize_array_token_balances_helper(ref output, input);
        },
        Option::None(_) => {},
    }
}

fn deserialize_array_token_balances_helper(
    ref serialized: Span<felt252>, mut curr_output: Array<TokenBalances>, remaining: felt252
) -> Option<Array<TokenBalances>> {
    if remaining == 0 {
        return Option::Some(curr_output);
    }

    check_gas();

    curr_output.append(Serde::<TokenBalances>::deserialize(ref serialized)?);
    deserialize_array_token_balances_helper(ref serialized, curr_output, remaining - 1)
}

impl ArrayTokenDifferencesDrop of Drop::<Array<TokenDifferences>>;

impl ArrayTokenDifferencesSerde of Serde::<Array<TokenDifferences>> {
    fn serialize(ref output: Array<felt252>, mut input: Array<TokenDifferences>) {
        Serde::<usize>::serialize(ref output, input.len());
        serialize_array_token_differences_helper(ref output, input);
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<Array<TokenDifferences>> {
        let length = *serialized.pop_front()?;
        let mut arr = ArrayTrait::new();
        deserialize_array_token_differences_helper(ref serialized, arr, length)
    }
}

fn serialize_array_token_differences_helper(ref output: Array<felt252>, mut input: Array<TokenDifferences>) {
    check_gas();
    match input.pop_front() {
        Option::Some(value) => {
            Serde::<TokenDifferences>::serialize(ref output, value);
            serialize_array_token_diffrences_helper(ref output, input);
        },
        Option::None(_) => {},
    }
}

fn deserialize_array_token_differences_helper(
    ref serialized: Span<felt252>, mut curr_output: Array<TokenDifferences>, remaining: felt252
) -> Option<Array<TokenDifferences>> {
    if remaining == 0 {
        return Option::Some(curr_output);
    }

    check_gas();

    curr_output.append(Serde::<TokenDifferences>::deserialize(ref serialized)?);
    deserialize_array_token_differences_helper(ref serialized, curr_output, remaining - 1)
}


mod FeePolicies {
    use array::ArrayTrait;
    use option::OptionTrait;
    use integer::u256_from_felt252;
    use starknet::get_contract_address;

    use openzeppelin::token::erc1155::IERC1155;

    use guild_contracts::fee_policies::constants_fee_policy::NetAssetFlow;
    use guild_contracts::fee_policies::constants_fee_policy::ShiftSplit;
    use guild_contracts::utils::bit_packing::unpack_data;

    use super::TokenDifferences;
    use super::TokenBalances;

    fn pack_fee_splits(caller_split: felt252, owner_split: felt252, admin_split: felt252) -> felt252 {
        let caller = caller_split * ShiftSplit::_1;
        let owner = owner_split * ShiftSplit::_2;
        let admin = admin_split * ShiftSplit::_3;
        caller + owner + admin
    }

    fn unpack_fee_splits(packed_splits: felt252) -> (felt252, felt252, felt252) {
        let caller_split = unpack_data(packed_splits, 0, 16383);
        let owner_split = unpack_data(packed_splits, 14, 16383);
        let admin_split = unpack_data(packed_splits, 28, 16383);
        return (caller_split, owner_split, admin_split);
    }

    fn get_balances(accrued_token: felt252, accrued_token_ids: Array<u256>) -> Array<u256> {
        let owner = get_contract_address();
        let owners = ArrayTrait::new();

        loop_generate_owners(0, accrued_token_ids_len, owner, owners);

        let erc1155_dispatcher = IERC1155 { contract_address: accrued_token };

        erc1155_dispatcher.balanceOfBatch(
            accrued_token_ids_len, owners, accrued_token_ids_len, accrued_token_ids
        )
    }

    fn loop_generate_owners(index: felt252, token_ids_len: felt252, owner: ContractAddress, ref owners: Array<ContractAddress>) {
        if (index == token_ids_len) {
            return ();
        }

        owners.append(owner);

        loop_generate_owners(index + 1, token_ids_len, owner, ref owners)
    }

    fn calculate_differences(
        index: usize,
        tokens_len: usize,
        pre_balances: Array<TokenBalances>,
        post_balances: Array<TokenBalances>,
        difference_balances: Array<TokenDifferences>,
    ) {
        if tokens_len == 0_usize {
            return ();
        }
        loop_calculate_differences(
            0_usize,
            pre_balances.at(index).balances.len(),
            *pre_balances.at(index).balances,
            *post_balances.at(index).balances,
            *difference_balances.at(index).differences,
        );

        return calculate_differences(
            index + 1_usize,
            tokens_len - 1_usize,
            pre_balances,
            post_balances,
            difference_balances,
        );
    }

    fn loop_calculate_differences(
        index: usize,
        token_ids_len: usize,
        pre_balances: Array<u256>,
        post_balances: Array<u256>,
        ref difference_balances: Array<felt252>,
    ) {
        if token_ids_len == 0_usize {
            return ();
        }
        let diff = post_balances.at(index).into() - pre_balances.at(index).into();
        difference_balances.append(diff);
        return loop_calculate_differences(
            index + 1_usize,
            token_ids_len - 1_usize,
            pre_balances,
            post_balances,
            difference_balances,
        );
    }

    fn calculate_distribution_balances(
        index: usize,
        difference_balances_len: usize,
        difference_balances: @Array<TokenDifferences>,
        caller_split: u256,
        owner_split: u256,
        admin_split: u256,
        caller_balances: Array<TokenBalances>,
        ref owner_balances: Array<TokenBalances>,
        ref admin_balances: Array<TokenBalances>,
    ) {

        if index == difference_balances_len {
            return ();
        }

        loop_calculate_distribution_balances(
            0,
            difference_balances.at(index).differences.len(),
            difference_balances.at(index).differences,
            caller_split,
            owner_split,
            admin_split,
            ref caller_balances.at(index).balances,
            ref owner_balances.at(index).balances,
            ref admin_balances.at(index).balances,
        );

        return calculate_distribution_balances(
            0,
            difference_balances_len,
            difference_balances,
            caller_split,
            owner_split,
            admin_split,
            ref caller_balances,
            ref owner_balances,
            ref admin_balances,
        );
    }

    fn loop_calculate_distribution_balances(
        index: usize,
        differences_len: usize,
        differences: Array<u256>,
        caller_split: u256,
        owner_split: u256,
        admin_split: u256,
        caller_balances: @Array<u256>,
        owner_balances: @Array<u256>,
        admin_balances: @Array<u256>,
    ) {
        if index == 0_usize {
            return ();
        }

        if (*differences.at(index) >= u256 { low: 0_u128, high: 0_u128 }) {
            caller_balances.append(*differences.at(index) * caller_split);
            owner_balances.append(*differences.at(index) * owner_split);
            admin_balances.append(*differences.at(index) * admin_split);

            return loop_calculate_distribution_balances(
                index,
                differences_len - 1_usize,
                differences,
                caller_split,
                owner_split,
                admin_split,
                ref caller_balances,
                ref owner_balances,
                ref admin_balances,
            );
        } else {
            return loop_calculate_distribution_balances(
                index + 1_usize,
                differences_len - 1_usize,
                differences,
                caller_split,
                owner_split,
                admin_split,
                ref caller_balances,
                ref owner_balances,
                ref admin_balances,
            );
        }
    }
}
