require('dotenv').config();

import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-web3";

const AURORA_PRIVATE_KEY = process.env.AURORA_PRIVATE_KEY;

module.exports = {
    solidity: "0.6.10",
    networks: {
        mainnet_aurora: {
            url: 'https://mainnet.aurora.dev',
            accounts: [`0x${AURORA_PRIVATE_KEY}`],
            chainId: 1313161554,
            gasPrice: 1 * 1000000000
        },
    }
};


