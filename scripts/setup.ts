import { ethers, providers, Wallet } from "ethers";
import { ContractTransaction, Signer } from "ethers";
import { BigNumber as BN } from "bignumber.js";
import chalk from "chalk";
require("dotenv").config();
const hre = require("hardhat");

/*
 * PARAMS
 * */

const AURORA = "0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79";
const WETH = "0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB";
const DAI = "0xe3520349F477A5F6EB06107066048508498A291b";
const USDT = "0x4988a896b1227218e4A686fdE5EabdcAbd91571f";
const USDC = "0xB12BFcA5A55806AaF64E99521918A4bf0fC40802";

const EXCHANGE = "0x74373626449a57c8d0322faf2e864efd99d7bd56";

const TOKENS = [AURORA, WETH, DAI, USDT, USDC];

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
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
  const exchange = await Exchange.connect(deployerWallet).attach(EXCHANGE);

  for (let token of TOKENS) {
    await exchange.approveToken(token);
    await delay(30000);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
