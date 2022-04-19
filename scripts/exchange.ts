import { ethers, providers, Wallet } from "ethers";
import { ContractTransaction, Signer } from "ethers";
import { BigNumber as BN } from "bignumber.js";
import chalk from "chalk";
require("dotenv").config();
const hre = require("hardhat");

/*
 * PARAMS
 * */

const WETH = "0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB";

const UNI_FACTORY = "0xc66F594268041dB60507F00703b152492fb176E7";
const UNI_ROUTER = "0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB";

const SUSHI_FACTORY = "0x7928D4FeA7b2c90C732c10aFF59cf403f0C38246";
const SUSHI_ROUTER = "0xa3a1eF5Ae6561572023363862e238aFA84C72ef5";

const CONTROLLER = "0x5636444570D6308963b05354C39f8174a9710EdA";
const ISSUANCE = "0x1Aa35A9c1e942A9bf8f9C83Adb36b83355Fef5b0";

/*
 * DEPLOY
 * */
async function main() {
  let provider = new ethers.providers.JsonRpcProvider(
    "https://mainnet.aurora.dev"
  );
  const deployerWallet = new ethers.Wallet(
    `${process.env.AURORA_PRIVATE_KEY}`,
    provider
  );
  const Exchange = await hre.ethers.getContractFactory("ExchangeIssuanceV2");
  const exchange = await Exchange.connect(deployerWallet).deploy(
    WETH,
    UNI_FACTORY,
    UNI_ROUTER,
    SUSHI_FACTORY,
    SUSHI_ROUTER,
    CONTROLLER,
    ISSUANCE
  );
  await exchange.deployed();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
