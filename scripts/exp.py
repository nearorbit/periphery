import brownie
import time
import sys
import signal
import click
import pytest

from rich.console import Console
from rich.table import Table
import json
from brownie import Contract, accounts, network, ExchangeIssuanceV2


def main():
    # abi = open('./external/abi/set/SetToken.json')
    # data = json.load(abi)
    # MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935

    # user = brownie.accounts.at(
    #     '0x63da4db6ef4e7c62168ab03982399f9588fcd198', force=True)
    # exchange = ExchangeIssuanceV2.at(
    #     '0x74373626449a57c8d0322faf2e864efd99d7bd56')

    # weth = brownie.interface.IWETH(
    #     '0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB')

    # set = '0x3c13c28cC30E2048C6d419Bad4886f1F4a3208db'

    # amt = 3680160589000000
    # sl = 1000000000000000000
    # print(amt)
    # print(sl)

    # payments = [
    #     '0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79',
    #     '0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB'
    # ]
    # for i in payments:
    #     exchange.approveToken(i, {'from': user})

    # weth.approve(exchange, MAX_UINT, {'from': user})

    # tx = exchange.issueExactSetFromToken(
    #     set, weth, sl, amt, {'from': user})

    # print(tx.call_trace(-10))

    # # archive
    # set = Contract.from_abi(
    #     'SetToken', '0x3c13c28cC30E2048C6d419Bad4886f1F4a3208db', data)

    # print(set.getComponents())

    # SYSTEM INIT
    dev = connect_account()

    exchange = ExchangeIssuanceV2.at(
        '0x74373626449a57c8d0322faf2e864efd99d7bd56')

    payments = [
        '0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79',  # aurora
        '0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB'  # weth
        '0xe3520349F477A5F6EB06107066048508498A291b',  # DAI
        '0x4988a896b1227218e4A686fdE5EabdcAbd91571f',  # USDT
        '0xB12BFcA5A55806AaF64E99521918A4bf0fC40802'  # USDC

    ]
    for i in payments:
        exchange.approveToken(i, {'from': dev})


def connect_account():
    click.echo(f"You are using the '{network.show_active()}' network")
    dev = accounts.load(click.prompt(
        "Account", type=click.Choice(accounts.load())))
    click.echo(f"You are using: 'dev' [{dev.address}]")
    return dev
