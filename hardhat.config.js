require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");
const { mnemonic, apiKey, infuraKey } = require('./secrets.json');

module.exports = {
	solidity: {
		version: "0.8.0",
		settings: {
			optimizer: {
				enabled: true,
				runs: 10
			}
		}
	},
	networks: {
		rinkeby: {
			url: 'https://rinkeby.infura.io/v3/' + infuraKey,
			gas: 10000000,
			accounts: { mnemonic: mnemonic }
		},
		mainnet: {
			url: 'https://mainnet.infura.io/v3/' + infuraKey,
			gas: 3000000,
			accounts: { mnemonic: mnemonic }
		},
		ropsten: {
			url: 'https://ropsten.infura.io/v3/' + infuraKey,
			gas: 10000000,
			accounts: { mnemonic: mnemonic }
		},
		testnet: {
			url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
			gas: 10000000,
			accounts: { mnemonic: mnemonic }
		},
		main: {
			url: "https://bsc-dataseed.binance.org/",
			gas: 10000000,
			accounts: { mnemonic: mnemonic }
		}
	},
	etherscan: {
		apiKey: apiKey
	}
};