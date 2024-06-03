const {Web3} = require("web3");
const {abi, bytecode} = require("../../out/TwentyOne.sol/TwentyOne.json");
require("dotenv").config();

async function main() {
	const web3 = new Web3(
		new Web3.providers.HttpProvider(process.env.SEPOLIA_API)
	);

	const signer = web3.eth.accounts.privateKeyToAccount(
		process.env.SENDER_PRIVATE_KEY
	);
	web3.eth.accounts.wallet.add(signer);

	const account2 = web3.eth.accounts.privateKeyToAccount(
		process.env.ACCOUNT2_PRIVATE_KEY
	);
	web3.eth.accounts.wallet.add(account2);

	const account3 = web3.eth.accounts.privateKeyToAccount(
		process.env.ACCOUNT3_PRIVATE_KEY
	);
	web3.eth.accounts.wallet.add(account3);

	const contract = new web3.eth.Contract(
		abi,
		"0xa939128Bfb587d0Ab02c5806bF63F95941D013C1"
	);
	contract.options.data = bytecode.object;
	contract.handleRevert = true;

	const enterContest =
		contract.methods.drawCard(
			89717814153306320011181716697424560163256864414616650038987186496166826726056n
		);
	enterContest
		.send({from: account2.address})
		.on("transactionHash", function (txHash) {
			console.log(txHash);
		});
}

main().catch((err) => {
	console.log(err);
});
