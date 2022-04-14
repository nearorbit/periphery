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
    WETH = '0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB'
    DAI = '0xe3520349F477A5F6EB06107066048508498A291b'

    UNI_FACTORY = '0xc66F594268041dB60507F00703b152492fb176E7'
    UNI_ROUTER = '0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB'

    SUSHI_FACTORY = '0x7928D4FeA7b2c90C732c10aFF59cf403f0C38246'
    SUSHI_ROUTER = '0xa3a1eF5Ae6561572023363862e238aFA84C72ef5'

    CONTROLLER = '0x5636444570D6308963b05354C39f8174a9710EdA'
    ISSUANCE = '0x1Aa35A9c1e942A9bf8f9C83Adb36b83355Fef5b0'

    dev = connect_account()

    """
    deploy all contracts in system
    """
    exchange = deploy_exchange(
        dev, WETH, DAI, UNI_FACTORY, UNI_ROUTER, SUSHI_FACTORY, SUSHI_ROUTER, CONTROLLER, ISSUANCE)

    print('exchange deployed at:', exchange.address)


def deploy_exchange(dev, WETH, DAI, UNI_FACTORY, UNI_ROUTER, SUSHI_FACTORY, SUSHI_ROUTER, CONTROLLER, ISSUANCE):
    instance = NavCalculator.deploy(
        WETH, DAI, UNI_FACTORY, UNI_ROUTER, SUSHI_FACTORY, SUSHI_ROUTER, CONTROLLER, ISSUANCE, {'from': dev, 'allow_revert': True})
    return instance


def connect_account():
    click.echo(f"You are using the '{network.show_active()}' network")
    dev = accounts.load(click.prompt(
        "Account", type=click.Choice(accounts.load())))
    click.echo(f"You are using: 'dev' [{dev.address}]")
    return dev
