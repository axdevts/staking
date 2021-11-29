const { expect } = require("chai");
const { ethers } = require("hardhat");
const { expectRevert } = require("@openzeppelin/test-helpers");
const { BigNumber, Wallet, utils } = require("ethers");
var Web3 = require("web3");
var web3 = new Web3(Web3.givenProvider);
const tokenABI = require("../artifacts/contracts/RewardToken.sol/RewardToken.json");
const stakerABI = require("../artifacts/contracts/Staker.sol/Staker.json");
const { serializeTransaction } = utils;
let rewardTokenInstance;
let rewardTokenContract;
let stakerInstance;
let stakerContract;
let owner, account1, account2, account3;
let rateReward = 10000; // reward tokens per month
let tokenDecimals = 18;

const provider = ethers.getDefaultProvider("http://127.0.0.1:8545/");

describe("RewardToken", () => {
  beforeEach(async () => {
    [owner, account1, account2, account3] = await ethers.getSigners();
    rewardTokenInstance = await ethers.getContractFactory("RewardToken");
    rewardTokenContract = await rewardTokenInstance.deploy();
    await rewardTokenContract.deployed();
  });
  describe("when mint", function () {
    it("Not approve to mint for common users", async () => {
      await expectRevert(
        rewardTokenContract
          .connect(account1)
          .mintRewardToken(account1.address, ethers.utils.parseEther("100")),
        "Ownable: caller is not the owner"
      );
    });
    it("mint to test stake features for users", async () => {
      await rewardTokenContract.mintRewardToken(
        account1.address,
        ethers.utils.parseEther("100")
      );
      await rewardTokenContract.mintRewardToken(
        account2.address,
        ethers.utils.parseEther("200")
      );

      expect(await rewardTokenContract.balanceOf(account1.address)).to.be.equal(
        ethers.utils.parseEther("100")
      );
      expect(await rewardTokenContract.balanceOf(account2.address)).to.be.equal(
        ethers.utils.parseEther("200")
      );
    });
  });
});
describe("when stake", function () {
  beforeEach(async () => {
    [owner, account1, account2, account3] = await ethers.getSigners();
    rewardTokenInstance = await ethers.getContractFactory("RewardToken");
    rewardTokenContract = await rewardTokenInstance.deploy();
    await rewardTokenContract.deployed();

    stakerInstance = await ethers.getContractFactory("Staker");
    stakerContract = await stakerInstance.deploy(rewardTokenContract.address);
    await stakerContract.deployed();

    await rewardTokenContract.mintRewardToken(
      account1.address,
      ethers.utils.parseEther("200")
    );
    await rewardTokenContract.mintRewardToken(
      account2.address,
      ethers.utils.parseEther("300")
    );
    await rewardTokenContract.mintRewardToken(
      account3.address,
      ethers.utils.parseEther("500")
    );
    await rewardTokenContract.mintRewardToken(
      stakerContract.address,
      ethers.utils.parseEther("500")
    );
  });
    it("deposite fail when balance < amount or amount = 0 ", async () => {
      await expectRevert(
        stakerContract.connect(account1).deposite(ethers.utils.parseEther("300")),
        "Please deposite more in your card!"
      );
      await expectRevert(
        stakerContract.connect(account1).deposite(ethers.utils.parseEther("0")),
        "The amount to be transferred should be larger than 0"
      );
      expect(await rewardTokenContract.balanceOf(account1.address)).to.be.equal(
        ethers.utils.parseEther("200")
      );
    });
    it("deposite success", async () => {
      // account1 deposite
      await rewardTokenContract
        .connect(account1)
        .approve(stakerContract.address, ethers.utils.parseEther("30"));
      await stakerContract
        .connect(account1)
        .deposite(ethers.utils.parseEther("30"));
      expect(await stakerContract.depositeOf(account1.address)).to.be.equal(
        ethers.utils.parseEther("30")
      );
      expect(await rewardTokenContract.balanceOf(account1.address)).to.be.equal(
        ethers.utils.parseEther("170")
      );
      expect(
        await rewardTokenContract.balanceOf(stakerContract.address)
      ).to.be.equal(ethers.utils.parseEther("530"));
      // get the total amount of deposited tokens
      expect(await stakerContract.getTotalDepositedAmount()).to.be.equal(
        ethers.utils.parseEther("30")
      );
      // account2 deposite
      await rewardTokenContract
        .connect(account2)
        .approve(stakerContract.address, ethers.utils.parseEther("50"));
      await stakerContract
        .connect(account2)
        .deposite(ethers.utils.parseEther("50"));
      expect(await stakerContract.depositeOf(account2.address)).to.be.equal(
        ethers.utils.parseEther("50")
      );
      expect(await rewardTokenContract.balanceOf(account2.address)).to.be.equal(
        ethers.utils.parseEther("250")
      );
      expect(
        await rewardTokenContract.balanceOf(stakerContract.address)
      ).to.be.equal(ethers.utils.parseEther("580"));
      // get the total amount of deposited tokens
      expect(await stakerContract.getTotalDepositedAmount()).to.be.equal(
        ethers.utils.parseEther("80")
      );
    });
    describe("when withdraw", function () {
      describe("cases of withdraw fail", function () {
        it("withdraw fail when didn't stake yet", async () => {
          await expectRevert(
            stakerContract
              .connect(account1)
              .withdraw(ethers.utils.parseEther("10")),
            "No stake"
          );
        });
        it("withdraw fail when the amount of withdraw is 0", async () => {
          // account1 deposite/withdraw
          await rewardTokenContract
            .connect(account1)
            .approve(stakerContract.address, ethers.utils.parseEther("30"));
          await stakerContract
            .connect(account1)
            .deposite(ethers.utils.parseEther("30"));
          await expectRevert(
            stakerContract
              .connect(account1)
              .withdraw(ethers.utils.parseEther("0")),
            "The amount to be transferred should be larger than 0"
          );
        });
        it("withdraw fail when the amount of withdraw < the amount of stake", async () => {
          // account1 deposite/withdraw
          await rewardTokenContract
            .connect(account1)
            .approve(stakerContract.address, ethers.utils.parseEther("30"));
          await stakerContract
            .connect(account1)
            .deposite(ethers.utils.parseEther("30"));
          await expectRevert(
            stakerContract
              .connect(account1)
              .withdraw(ethers.utils.parseEther("50")),
            "The amount to be transferred should be equal or less than Deposite"
          );
        });
      });
      it("withdraw success", async () => {
        // account1 deposite/withdraw
        await rewardTokenContract
          .connect(account1)
          .approve(stakerContract.address, ethers.utils.parseEther("60"));
        await stakerContract
          .connect(account1)
          .deposite(ethers.utils.parseEther("60"));
        await stakerContract
          .connect(account1)
          .withdraw(ethers.utils.parseEther("25"));
        expect(await stakerContract.depositeOf(account1.address)).to.be.equal(
          ethers.utils.parseEther("35")
        );
        expect(await rewardTokenContract.balanceOf(account1.address)).to.be.equal(
          ethers.utils.parseEther("165")
        );
        expect(
          await rewardTokenContract.balanceOf(stakerContract.address)
        ).to.be.equal(ethers.utils.parseEther("535"));

        expect(await stakerContract.getTotalDepositedAmount()).to.be.equal(
          ethers.utils.parseEther("35")
        );
        // account2 deposite/withdraw
        await rewardTokenContract
          .connect(account2)
          .approve(stakerContract.address, ethers.utils.parseEther("150"));
        await stakerContract
          .connect(account2)
          .deposite(ethers.utils.parseEther("150"));
        await stakerContract
          .connect(account2)
          .withdraw(ethers.utils.parseEther("70"));
        expect(await stakerContract.depositeOf(account2.address)).to.be.equal(
          ethers.utils.parseEther("80")
        );
        expect(await rewardTokenContract.balanceOf(account2.address)).to.be.equal(
          ethers.utils.parseEther("220")
        );
        expect(
          await rewardTokenContract.balanceOf(stakerContract.address)
        ).to.be.equal(ethers.utils.parseEther("615"));

        expect(await stakerContract.getTotalDepositedAmount()).to.be.equal(
          ethers.utils.parseEther("115")
        );
      });
    });
  describe("when claim reward", function () {
    describe("cases of getreward fail", function () {
      it("claim reward fail when no rewards", async () => {
        await expectRevert(
          stakerContract.connect(account1).claimReward(),
          "No rewards"
        );
      });
    });
    describe("claim reward success", function () {
      it("check if the amount of the calculated rewards is correct", async () => {
        // account1 deposite
        await rewardTokenContract
          .connect(account1)
          .approve(stakerContract.address, ethers.utils.parseEther("100"));
        await stakerContract
          .connect(account1)
          .deposite(ethers.utils.parseEther("100"));

        const lastUpdatedTime = new Date(2021, 9, 18).getTime() / 1000; // 1634486400
        await stakerContract.setLastTime(account1.address, lastUpdatedTime);
        // account1 withdraw
        await stakerContract
          .connect(account1)
          .withdraw(ethers.utils.parseEther("100"));

        const nowTime = new Date() / 1000;
        const rewardAmountCal =
          ((nowTime - lastUpdatedTime) * rateReward * 100) / 100 / 86400 / 30;
        console.log("The calculated rewardAmount is ", rewardAmountCal);
        rewardAmount = await stakerContract.rewardOf(account1.address);
        rewardAmountDecimal = rewardAmount.toNumber();
        console.log("The amount of real rewards is ", rewardAmountDecimal);
        expect(rewardAmountDecimal).to.be.closeTo(rewardAmountCal, 1);

        getRewardsResult = await stakerContract.connect(account1).claimReward();

        expect(getRewardsResult)
          .to.emit(stakerContract, "ClaimFinished")
          .withArgs(account1.address, rewardAmount);
        expect(await stakerContract.rewardOf(account1.address)).to.be.equal(0);

        const account1Balance = BigNumber.from(200)
          .mul(BigNumber.from(10).pow(tokenDecimals))
          .add(rewardAmountDecimal);
        expect(
          await rewardTokenContract.balanceOf(account1.address)
        ).to.be.equal(account1Balance);

        const contractBalance = BigNumber.from(500)
          .mul(BigNumber.from(10).pow(tokenDecimals))
          .sub(rewardAmountDecimal);
        expect(
          await rewardTokenContract.balanceOf(stakerContract.address)
        ).to.be.equal(contractBalance);

        expect(await stakerContract.getTotalDepositedAmount()).to.be.equal(
          ethers.utils.parseEther("0")
        );
      });
    });
    describe("when reward rate changes", function () {
      it("fail changing when non-owner set new reward rate", async () => {
        await expectRevert(
          stakerContract.connect(account1).setRewardRate(20000),
          "Ownable: caller is not the owner"
        );
      });
      it("fail changing when new reward rate is 0", async () => {
        await expectRevert(
          stakerContract.setRewardRate(0),
          "The reward rate should be larger than 0"
        );
      });

      it("success when owner set and new reward rate is 0", async () => {
        await stakerContract.setRewardRate(20000);
        expect(await stakerContract.getRewardRate()).to.be.equal(20000);
      });
    });
    describe("check the calculation for it when the setting of reward rate success", async () => {
      beforeEach(async () => {
        rateReward = 20000;
        await stakerContract.setRewardRate(rateReward);

        // account1 deposite
        await rewardTokenContract
          .connect(account1)
          .approve(stakerContract.address, ethers.utils.parseEther("100"));
        await stakerContract
          .connect(account1)
          .deposite(ethers.utils.parseEther("100"));

        // account2 deposite
        await rewardTokenContract
          .connect(account2)
          .approve(stakerContract.address, ethers.utils.parseEther("200"));
        await stakerContract
          .connect(account2)
          .deposite(ethers.utils.parseEther("200"));
      });
      it("check if new rate is set correctly", async () => {
        expect(await stakerContract.getRewardRate()).to.be.equal(20000);
      });
      it("check the total amount of the deposited tokens", async () => {
        expect(await stakerContract.getTotalDepositedAmount()).to.be.equal(
          ethers.utils.parseEther("300")
        );
      });
      it("check the reward amount", async () => {
        const lastUpdatedTime = new Date(2021, 9, 18).getTime() / 1000; // 1634486400
        await stakerContract.setLastTime(account1.address, lastUpdatedTime);

        // account1 withdraw
        await stakerContract
          .connect(account1)
          .withdraw(ethers.utils.parseEther("100"));

        const nowTime = new Date() / 1000;
        const rewardAmountCal =
          ((nowTime - lastUpdatedTime) * rateReward * 100) / 300 / 86400 / 30;
        console.log("The calculated rewardAmount is ", rewardAmountCal);
        rewardAmount = await stakerContract.rewardOf(account1.address);
        rewardAmountDecimal = rewardAmount.toNumber();
        console.log("The amount of real rewards is ", rewardAmountDecimal);
        expect(rewardAmountDecimal).to.be.closeTo(rewardAmountCal, 1);
      });
      it("check the balances after withdraw, claim rewards", async () => {
        const lastUpdatedTime = new Date(2021, 9, 18).getTime() / 1000; // 1634486400
        await stakerContract.setLastTime(account1.address, lastUpdatedTime);

        // account1 withdraw
        await stakerContract
          .connect(account1)
          .withdraw(ethers.utils.parseEther("100"));

        rewardAmount = await stakerContract.rewardOf(account1.address);
        rewardAmountDecimal = rewardAmount.toNumber();

        getRewardsResult = await stakerContract.connect(account1).claimReward();
        expect(getRewardsResult)
          .to.emit(stakerContract, "ClaimFinished")
          .withArgs(account1.address, rewardAmount);

        const account1Balance = BigNumber.from(200)
          .mul(BigNumber.from(10).pow(tokenDecimals))
          .add(rewardAmountDecimal);
        expect(
          await rewardTokenContract.balanceOf(account1.address)
        ).to.be.equal(account1Balance);

        const contractBalance = BigNumber.from(700)
          .mul(BigNumber.from(10).pow(tokenDecimals))
          .sub(rewardAmountDecimal);
        expect(
          await rewardTokenContract.balanceOf(stakerContract.address)
        ).to.be.equal(contractBalance);

        expect(await stakerContract.getTotalDepositedAmount()).to.be.equal(
          ethers.utils.parseEther("200")
        );
      });
    });
    describe("setting to apply the withdraw fee", function () {
      it("check if user pays the fee by the default", async () => {
        const feeStatus = await stakerContract.getWithdrawFeeApplyStatus(
          account1.address
        );
        expect(feeStatus).to.be.equal(false);

        if (!feeStatus) {
          account1Balance = await ethers.provider.getBalance(account1.address);
          ownerBalance = await ethers.provider.getBalance(owner.address);
          // account1 deposite
          await rewardTokenContract
            .connect(account1)
            .approve(stakerContract.address, ethers.utils.parseEther("100"));
          await stakerContract
            .connect(account1)
            .deposite(ethers.utils.parseEther("100"));
          account1Balance1 = await ethers.provider.getBalance(account1.address);
          expect(account1Balance1).to.below(account1Balance);

          ownerBalance1 = await ethers.provider.getBalance(owner.address);
          expect(ownerBalance1).to.equal(ownerBalance);
        }
      });
      describe("when change feeApplyStatus", async () => {
        it("fail when non-owner change feeApplyStatus", async () => {
          const feeStatus = await stakerContract.getWithdrawFeeApplyStatus(
            account1.address
          );
          expect(feeStatus).to.be.equal(false);
          await expectRevert(
            stakerContract
              .connect(account1)
              .setWithdrawFeeApplyStatus(account1.address, true),
            "Ownable: caller is not the owner"
          );
        });
        it("success when owner change feeApplyStatus", async () => {
          const feeStatus = await stakerContract.getWithdrawFeeApplyStatus(
            account1.address
          );
          expect(feeStatus).to.be.equal(false);
          await stakerContract.setWithdrawFeeApplyStatus(
            account1.address,
            true
          );
          const feeStatus1 = await stakerContract.getWithdrawFeeApplyStatus(
            account1.address
          );
          expect(feeStatus1).to.be.equal(true);
        });
        it("check status when set to pay fee by owner", async () => {
          await stakerContract.setWithdrawFeeApplyStatus(
            account1.address,
            true
          );
          const feeStatus = await stakerContract.getWithdrawFeeApplyStatus(
            account1.address
          );
          expect(feeStatus).to.be.equal(true);
        });
      });
    });
  });
});
