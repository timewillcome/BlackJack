const {Web3} = require("web3");
const {abi, bytecode} = require("../../out/Contest.sol/Contest.json");
require("dotenv").config();

async function main() {
	const web3 = new Web3(
		new Web3.providers.HttpProvider(process.env.SEPOLIA_API)
	);

	const signer = web3.eth.accounts.privateKeyToAccount(
		process.env.SENDER_PRIVATE_KEY
	);

	const contract = new web3.eth.Contract(abi);
	contract.options.data = bytecode.object;
	contract.handleRevert = true;

	const contractTx = contract.deploy({
		arguments: [10547],
	});

	contractTx
		.send({
			from: signer.address,
			gas: contractTx.estimateGas(),
		})
		.on("receipt", (receipt) => {
			receipt.contractAddress;
		});
}

main();
