"""math_utils.cairo test file."""
import pytest
import asyncio
import os

from starkware.starknet.testing.starknet import Starknet

from utils import (
    to_uint
)

MATH_UTILS = os.path.join("contracts/tests", "math_utils_test.cairo")
HELPERS = os.path.join("contracts/utils", "helpers.cairo")

@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope="module")
async def contract_factory():
    starknet = await Starknet.empty()
    math_utils = await starknet.deploy(
        source=MATH_UTILS,
        constructor_calldata=[]
    )
    helpers = await starknet.deploy(
        source=HELPERS,
        constructor_calldata=[]
    )

    return math_utils, helpers

@pytest.mark.asyncio
async def test_felt_sum(contract_factory):
    """Tests utils sum of felts."""
    math_utils, helpers = contract_factory

    execution_info = await math_utils.test_array_sum(
        [
            22, 30, 67, 2, 83
        ]
    ).call()

    assert execution_info.result == (204,)

@pytest.mark.asyncio
async def test_felt_product(contract_factory):
    """Tests utils product of felts."""
    math_utils, helpers = contract_factory

    execution_info = await math_utils.test_array_product(
        [
            22, 30, 67, 2, 83
        ]
    ).call()

    assert execution_info.result == (7340520,)

@pytest.mark.asyncio
async def test_uint256_sum(contract_factory):
    """Tests utils sum of uint256's."""

    math_utils, helpers = contract_factory

    execution_info = await math_utils.test_uint256_array_sum(
        [
            to_uint(22), to_uint(30), to_uint(67), to_uint(2), to_uint(83)
        ]
    ).call()

    assert execution_info.result == (to_uint(204),)

@pytest.mark.asyncio
async def test_uint256_product(contract_factory):
    """Tests utils product of uint256's."""

    math_utils, helpers = contract_factory
    

    execution_info = await math_utils.test_uint256_array_product(
        [
            to_uint(22), to_uint(30), to_uint(67), to_uint(2), to_uint(83)
        ]
    ).call()

    assert execution_info.result == (to_uint(7340520),)

@pytest.mark.asyncio
async def test_find_value(contract_factory):
    """Test find index of felt in array."""

    math_utils, helpers = contract_factory
    
    execution_info = await helpers.find_value(
        0, [1,2,3], 2
    ).call()

    assert execution_info.result == (1,)

@pytest.mark.asyncio
async def test_find_uint256_value(contract_factory):
    """Test find index of Uint256 in array."""

    math_utils, helpers = contract_factory
    
    execution_info = await helpers.find_uint256_value(
        0, [to_uint(1),to_uint(2),to_uint(3)], to_uint(3)
    ).call()

    assert execution_info.result == (2,)