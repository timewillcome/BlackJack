const {Web3} = require("web3");
const {abi, bytecode} = require("../../out/Contest.sol/Contest.json");

async function main() {
	const web3 = new Web3(
		new Web3.providers.HttpProvider("HTTP://127.0.0.1:7545")
	);

	const signer = await web3.eth.accounts.privateKeyToAccount(
		"0x99d6a7752535defcac5a67c47d1631c9de9bb7ad6655072e309b14c749ce92b8"
	);
	web3.eth.accounts.wallet.add(signer);

	const contract = new web3.eth.Contract(abi);
	contract.options.data = bytecode.object;
	contract.handleRevert = true;

	const contractTx = contract.deploy({
		arguments: [10547],
	});

	await contractTx
		.send({
			from: signer.address,
			gas: contractTx.estimateGas(),
		})
		.on("receipt", (receipt) => {
			receipt.contractAddress;
		});
}

main();
