// const fs = require('fs');

// const privateKey = fs.readFileSync(".secret").toString().trim() || "01234567890123456789";
// const infuraId = fs.readFileSync(".infuraid").toString().trim() || "";

// let secrets = require('./secrets.json');

require('@nomiclabs/hardhat-waffle');
require('dotenv').config();

const { RINKEBY_URL, PRIVATE_KEY } = process.env;

module.exports = {
	networks: {
		rinkeby: {
			url: RINKEBY_URL,
			accounts: [PRIVATE_KEY],
		},
	},
	//   defaultNetwork: "hardhat",
	//   networks: {
	//     hardhat: {
	//       chainId: 1337
	//     },
	//     /*
	//     mumbai: {
	//       // Infura
	//       // url: `https://polygon-mumbai.infura.io/v3/${infuraId}`
	//       url: "https://rpc-mumbai.matic.today",
	//       accounts: [privateKey]
	//     },
	//     matic: {
	//       // Infura
	//       // url: `https://polygon-mainnet.infura.io/v3/${infuraId}`,
	//       url: "https://rpc-mainnet.maticvigil.com",
	//       accounts: [privateKey]
	//     }
	//     */
	//   },
	solidity: {
		version: '0.8.4',
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
};
