from brownie import (
    accounts,
    config,
    network,
    NavCalculator,
    interface
)

import click


def main():
    """
    add contract arguments for deployment
    """
    WETH = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2'
    DAI = '0x6b175474e89094c44da98b954eedeac495271d0f'

    UNI_FACTORY = '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f'
    UNI_ROUTER = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D'

    SUSHI_FACTORY = '0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac'
    SUSHI_ROUTER = '0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F'

    CONTROLLER = '0xa4c8d221d8BB851f83aadd0223a8900A6921A349'
    ISSUANCE = '0xd8EF3cACe8b4907117a45B0b125c68560532F94D'

    dev = connect_account()

    """
    deploy all contracts in system
    """
    exchange = deploy_exchange(
        dev, WETH, DAI, UNI_FACTORY, UNI_ROUTER, SUSHI_FACTORY, SUSHI_ROUTER, CONTROLLER, ISSUANCE)

    """
    return system fixture
    """
    return (exchange)


def deploy_exchange(dev, WETH, DAI, UNI_FACTORY, UNI_ROUTER, SUSHI_FACTORY, SUSHI_ROUTER, CONTROLLER, ISSUANCE):
    instance = NavCalculator.deploy(
        WETH, DAI, UNI_FACTORY, UNI_ROUTER, SUSHI_FACTORY, SUSHI_ROUTER, CONTROLLER, ISSUANCE, {'from': dev})
    return instance


def connect_account():
    click.echo(f"You are using the '{network.show_active()}' network")
    dev = accounts.load(click.prompt(
        "Account", type=click.Choice(accounts.load())))
    click.echo(f"You are using: 'dev' [{dev.address}]")
    return dev
