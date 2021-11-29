const { ethers, upgrades } = require("hardhat");

async function main() {
	// deploy reward gem token
	const gemInstance = await ethers.getContractFactory("RewardToken");
	const gemContract = await gemInstance.deploy();
	await gemContract.deployed();
	console.log("gem deployed to:", gemContract.address);

	// deploy staking contract
	const stakingInstance = await ethers.getContractFactory("Staker");
	const stakingContract = await upgrades.deployProxy(stakingInstance, [
		gemContract.address,
		'0x183c8EcB4d974f8351512bd7B8bB3AC76f42Ed56'
	]);
	await stakingContract.deployed();

	console.log('staking deployed', stakingContract.address);

	await gemContract.transferOwnership(stakingContract.address);
	console.log('gem ownership moved into staking contract address');
}

main();