"""Fee policy calculations test"""
import pytest
import asyncio
import os

CONTRACTS_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "contracts")
OZ_CONTRACTS_PATH = os.path.join(
    os.path.dirname(__file__), "..", "..", "lib", "cairo_contracts", "src"
)

here = os.path.abspath(os.path.dirname(__file__))

CAIRO_PATH = [CONTRACTS_PATH, OZ_CONTRACTS_PATH,here]


@pytest.fixture(scope="module")
async def contract_factory():