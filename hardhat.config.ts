require('dotenv').config();

const AURORA_PRIVATE_KEY = process.env.AURORA_PRIVATE_KEY;

module.exports = {
    solidity: "0.6.10",
    networks: {
        testnet_aurora: {
            url: 'https://testnet.aurora.dev',
            accounts: [`0x${AURORA_PRIVATE_KEY}`],
            chainId: 1313161555,
            gasPrice: 120 * 1000000000
        },
        local_aurora: {
            url: 'http://localhost:8545',
            accounts: [`0x${AURORA_PRIVATE_KEY}`],
            chainId: 1313161555,
            gasPrice: 120 * 1000000000
        },
        ropsten: {
            url: `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [`0x${AURORA_PRIVATE_KEY}`],
            chainId: 3,
            live: true,
            gasPrice: 50000000000,
            gasMultiplier: 2,
        },
        mainnet_aurora: {
            url: 'https://mainnet.aurora.dev',
            accounts: "remote",
            chainId: 1313161554,
            gasPrice: 1 * 1000000000
        },
    }
};


