//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./RewardToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staker is Ownable {
    using SafeMath for uint256;
    RewardToken public rewardToken;

    event StakeFinished(address indexed user, uint256 amount);
    event WithdrawFinished(address indexed user, uint256 amount);
    event ClaimFinished(address indexed user, uint256 amount);
    event ChangedWithdrawFeeApplyStatus(
        address indexed user,
        bool applyFeeStatus
    );
    event ChangedRewardRate(uint256 _rewardRate);

    uint256 rewardRate = 10000; // per month as total rewards
    uint256 totalStakedAmount;
    uint256 MIN_AMOUNT = 1000; // per staking amount
    uint256 MIN_TIME = 24 * 3600; // can staking minimum time

    struct StakeList {
        uint256 stakesAmount;
        uint256 rewardsAmount;
        uint256 lastUpdateTime;
    }

    /**
     * @notice The accumulated stake status for each stakeholder.
     */
    mapping(address => StakeList) public stakeLists;
    mapping(address => bool) public withdrawFeeApplyStatus;

    /**
     * @dev Creates a staker contract that handles the diposite, withdraw, getReward features
     * for RewardToken tokens.
     * @param _tokenAddress RewardToken contract addresss that is already deployed
     */
    constructor(RewardToken _tokenAddress) {
        rewardToken = _tokenAddress;
    }

    /**
     * @notice A method for investor/staker to create/add the diposite.
     * @param _amount The amount of the diposite to be created.
     */
    function Stake(uint256 _amount) public returns (bool) {
        require(
            rewardToken.balanceOf(msg.sender) >= _amount,
            "Please stake more in your card!"
        );
        require(
            _amount > 0,
            "The amount to be transferred should be larger than 0"
        );

        rewardToken.transferFrom(msg.sender, address(this), _amount);
        StakeList storage _personStakeSatus = stakeLists[msg.sender];
        _personStakeSatus.rewardsAmount = updateReward(msg.sender);
        totalStakedAmount += _amount;
        _personStakeSatus.stakesAmount += _amount;
        _personStakeSatus.lastUpdateTime = block.timestamp;

        emit StakeFinished(msg.sender, _amount);

        return true;
    }

    /**
     * @notice A method for the stakeholder to withdraw.
     * @param _amount The amount of the withdraw.
     */
    function withdraw(uint256 _amount) public returns (bool) {
        StakeList storage _personStakeSatus = stakeLists[msg.sender];

        require(_personStakeSatus.stakesAmount != 0, "No stake");
        require(
            _amount > 0,
            "The amount to be transferred should be larger than 0"
        );
        require(
            _amount <= _personStakeSatus.stakesAmount,
            "The amount to be transferred should be equal or less than Stake"
        );
        require(
            _personStakeSatus.lastUpdateTime > MIN_TIME,
            "You should be wait at least 24 hours from scratch."
        );

        rewardToken.transfer(msg.sender, _amount);
        _personStakeSatus.rewardsAmount = updateReward(msg.sender);
        totalStakedAmount -= _amount;
        _personStakeSatus.stakesAmount -= _amount;
        _personStakeSatus.lastUpdateTime = block.timestamp;

        emit WithdrawFinished(msg.sender, _amount);

        return true;
    }

    /**
     * @notice A method to allow the stakeholder to claim his rewards.
     */
    function claimReward() public returns (bool) {
        StakeList storage _personStakeSatus = stakeLists[msg.sender];
        _personStakeSatus.rewardsAmount = updateReward(msg.sender);
        require(_personStakeSatus.rewardsAmount != 0, "No rewards");

        uint256 getRewardAmount = _personStakeSatus.rewardsAmount;

        rewardToken.transfer(msg.sender, getRewardAmount);
        _personStakeSatus.rewardsAmount = 0;
        _personStakeSatus.lastUpdateTime = block.timestamp;

        emit ClaimFinished(msg.sender, getRewardAmount);

        return true;
    }

    /**
     * @notice A method to calcaulate the stake rewards for a stakeholder for all transactions.
     * rewardRate with per-mille unit
     * withdrawFee with percentage unit
     * rewardRate - the total amount of rewards per month
     * @param _account The stakeholder to retrieve the stake rewards for.
     * @return uint256 The amount of tokens.
     */
    function updateReward(address _account) public view returns (uint256) {
        StakeList storage _personStakeSatus = stakeLists[_account];

        if (_personStakeSatus.stakesAmount == 0) {
            return _personStakeSatus.rewardsAmount;
        }
        return
            _personStakeSatus.rewardsAmount.add(
                block
                    .timestamp
                    .sub(_personStakeSatus.lastUpdateTime)
                    .mul(rewardRate)
                    .mul(_personStakeSatus.stakesAmount)
                    .div(totalStakedAmount)
                    .div(86400)
                    .div(30)
            );
    }

    /**
     * @notice A method for only owner to change whether it will be applied withdraw fee for a stakeholder or not.
     * false by the default - user pays the fee
     * If true owner pays the fee
     * @param _stakeholder The stakeholder address.
     */
    function setWithdrawFeeApplyStatus(address _stakeholder, bool _applyFee)
        public
        onlyOwner
        returns (bool)
    {
        withdrawFeeApplyStatus[_stakeholder] = _applyFee;
        emit ChangedWithdrawFeeApplyStatus(_stakeholder, _applyFee);

        return true;
    }

    /**
     * @notice A method for only owner to change the reward rate.
     * @param _rewardRate new reward rate
     */
    function setRewardRate(uint256 _rewardRate)
        public
        onlyOwner
        returns (bool)
    {
        require(_rewardRate > 0, "The reward rate should be larger than 0");
        rewardRate = _rewardRate;
        emit ChangedRewardRate(_rewardRate);

        return true;
    }

    /**
     * @notice A method to retrieve the amount of depoiste for a stakeholder.
     * @param _stakeholder The stakeholder address.
     * @return uint256 The amount of tokens.
     */
    function stakeOf(address _stakeholder) public view returns (uint256) {
        StakeList storage _personStakeSatus = stakeLists[_stakeholder];
        return _personStakeSatus.stakesAmount;
    }

    /**
     * @notice A method to retrieve the amount of rewards for a stakeholder.
     * @param _stakeholder The stakeholder address.
     * @return uint256 The amount of tokens.
     */
    function rewardOf(address _stakeholder) public view returns (uint256) {
        StakeList storage _personStakeSatus = stakeLists[_stakeholder];
        return _personStakeSatus.rewardsAmount;
    }

    /**
     * @notice A method to get the total amount of the deposied tokens
     */
    function getTotalStakedAmount() public view returns (uint256) {
        return totalStakedAmount;
    }

    /**
     * @notice A method to get the reward rate
     */
    function getRewardRate() public view returns (uint256) {
        return rewardRate;
    }

    /**
     * @notice A method to retrieve withdraw fee apply status for stakeholder.
     * @param _stakeholder The stakeholder address.
     */
    function getWithdrawFeeApplyStatus(address _stakeholder)
        public
        view
        returns (bool)
    {
        return withdrawFeeApplyStatus[_stakeholder];
    }

    /* ========== TEST FUNCTION ============ */
    function setLastTime(address _stakeholder, uint256 _lastTime)
        public
        returns (bool)
    {
        StakeList storage _personStakeSatus = stakeLists[_stakeholder];
        _personStakeSatus.lastUpdateTime = _lastTime;
        return true;
    }

    function getLastTime(address _stakeholder) public view returns (uint256) {
        StakeList storage _personStakeSatus = stakeLists[_stakeholder];
        return _personStakeSatus.lastUpdateTime;
    }
}
