import brownie
from brownie import *

"""
  TODO: test flow, types, returns, checks
"""


def test_my_custom_test(set, deployed):
    (exchange) = deployed
    print(set.address)

    x = exchange.getEstimatedNav(set.address)
    print(x)
    assert True
