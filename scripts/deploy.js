const { ethers } = require("hardhat");

async function main() {
	let publicHiddenURL = "";
	let presaleHiddenURL = "";
	let wallets = await ethers.getSigners()
	console.log('owner address-------', wallets[0].address)
	const Instance = await ethers.getContractFactory("Staker");
	const contract = await Instance.deploy();

	console.log("Box deployed to:", contract.address);
}

main();