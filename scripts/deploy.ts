import { ethers, providers, Wallet } from "ethers";
import { ContractTransaction, Signer } from "ethers";
import { BigNumber as BN } from "bignumber.js";
import chalk from "chalk";
require('dotenv').config();
const hre = require("hardhat");

/*
* PARAMS
* */
const WETH = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2'
const DAI = '0x6b175474e89094c44da98b954eedeac495271d0f'

const UNI_FACTORY = '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f'
const UNI_ROUTER = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D'

const SUSHI_FACTORY = '0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac'
const SUSHI_ROUTER = '0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F'

const CONTROLLER = '0xa4c8d221d8BB851f83aadd0223a8900A6921A349'
const ISSUANCE = '0xd8EF3cACe8b4907117a45B0b125c68560532F94D'

/*
* DEPLOY
* */
async function main() {
    const provider = hre.ethers.provider;
    const deployerWallet = new hre.ethers.Wallet(process.env.AURORA_PRIVATE_KEY, provider);

    const Exchange = await hre.ethers.getContractFactory("NavCalculator");
    const exchange = await Exchange
        .connect(deployerWallet)
        .deploy(WETH, DAI, UNI_FACTORY, UNI_ROUTER, SUSHI_FACTORY, SUSHI_ROUTER, CONTROLLER, ISSUANCE);
    await exchange.deployed();
}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });