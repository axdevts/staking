//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/IERC20.sol";
import "./utils/Initializable.sol";
import "./utils/SafeMath.sol";
import "./utils/Ownable.sol";

contract Staker is Initializable, Ownable {
    using SafeMath for uint256;
    IERC20 public cbcToken;
    IERC20 public rewardToken;

    event DepositFinished(
        address indexed user,
        uint256 amount,
        uint256 depositAt
    );
    event WithdrawFinished(
        address indexed user,
        uint256 amount,
        uint256 withdrawAt
    );
    event ClaimFinished(address indexed user, uint256 amount, uint256 claimAt);
    event ChangedWithdrawFeeApplyStatus(
        address indexed user,
        bool applyFeeStatus
    );
    event ChangedRewardRate(uint256 _rewardRate);

    uint256 minDeposit;
    uint256 rewardRate; // per month as total rewards
    uint256 totalDepositAmount;
    uint256 lockTime;
    bool lockEnabled;

    struct StakeList {
        uint256 stakesAmount;
        uint256 rewardsAmount;
        uint256 availableClaimTime;
        uint256 lastUpdateTime;
    }

    bool enabled;

    /**
     * @notice The accumulated stake status for each stakeholder.
     */
    mapping(address => StakeList) public stakeLists;
    mapping(address => bool) public withdrawFeeApplyStatus;

    /**
     * @dev Creates a staker contract that handles the diposit, withdraw, getReward features
     * for RewardToken tokens.
     * @param _tokenAddress RewardToken contract addresss that is already deployed
     * @param _cbcAddress cbc contract addresss that is already deployed
     */
    function initialize(IERC20 _tokenAddress, IERC20 _cbcAddress)
        public
        initializer
    {
        rewardToken = _tokenAddress;
        cbcToken = _cbcAddress;

        minDeposit = 1000;
        rewardRate = 1000;
        lockTime = 86400; /// 24 hours
        enabled = true;
        lockEnabled = false;

        __Ownable_init();
    }

    /**
     * @notice A method for investor/staker to create/add the diposit.
     * @param _amount The amount of the diposit to be created.
     */
    function deposit(uint256 _amount) external {
        require(enabled == true, "Staking Contract is disabled for a while");
        require(
            cbcToken.balanceOf(msg.sender) >= _amount,
            "Please deposit more cbc to your wallet!"
        );
        require(
            _amount > minDeposit,
            "Deposit amount should be larger than minimum deposit amount"
        );

        cbcToken.transferFrom(msg.sender, address(this), _amount);
        StakeList storage _personStakeStatus = stakeLists[msg.sender];
        _personStakeStatus.rewardsAmount = updateReward(msg.sender);
        if (_personStakeStatus.stakesAmount == 0) {
            _personStakeStatus.availableClaimTime = block.timestamp + lockTime;
        }
        totalDepositAmount += _amount;
        _personStakeStatus.stakesAmount += _amount;
        _personStakeStatus.lastUpdateTime = block.timestamp;

        emit DepositFinished(
            msg.sender,
            _amount,
            _personStakeStatus.lastUpdateTime
        );
    }

    /**
     * @notice A method for the stakeholder to withdraw.
     * @param _amount The amount of the withdraw.
     */
    function withdraw(uint256 _amount) external {
        require(enabled == true, "Staking Contract is disabled for a while");
        StakeList storage _personStakeStatus = stakeLists[msg.sender];

        require(_personStakeStatus.stakesAmount != 0, "No stake");
        require(
            _amount > 0,
            "The amount to be transferred should be larger than 0"
        );
        require(
            _amount <= _personStakeStatus.stakesAmount,
            "The amount to be transferred should be equal or less than Deposite"
        );

        cbcToken.transfer(msg.sender, _amount);
        _personStakeStatus.rewardsAmount = updateReward(msg.sender);
        totalDepositAmount -= _amount;
        _personStakeStatus.stakesAmount -= _amount;
        _personStakeStatus.lastUpdateTime = block.timestamp;

        emit WithdrawFinished(
            msg.sender,
            _amount,
            _personStakeStatus.lastUpdateTime
        );
    }

    /**
     * @notice A method to allow the stakeholder to claim his rewards.
     */
    function claimReward() external {
        require(enabled == true, "Staking Contract is disabled for a while");
        StakeList storage _personStakeStatus = stakeLists[msg.sender];
        if (lockEnabled) {
            require(
                _personStakeStatus.availableClaimTime > block.timestamp,
                "Cannot withdraw within lock time from first deposit"
            );
        }
        _personStakeStatus.rewardsAmount = updateReward(msg.sender);
        require(_personStakeStatus.rewardsAmount != 0, "No rewards");

        uint256 getRewardAmount = _personStakeStatus.rewardsAmount;

        rewardToken.mint(msg.sender, getRewardAmount);
        _personStakeStatus.rewardsAmount = 0;
        _personStakeStatus.lastUpdateTime = block.timestamp;

        emit ClaimFinished(
            msg.sender,
            getRewardAmount,
            _personStakeStatus.lastUpdateTime
        );
    }

    /**
     * @notice A method to calcaulate the stake rewards for a stakeholder for all transactions.
     * rewardRate with per-mille unit
     * withdrawFee with percentage unit
     * rewardRate - the total amount of rewards per month
     * @param _account The stakeholder to retrieve the stake rewards for.
     * @return uint256 The amount of tokens.
     */
    function updateReward(address _account) internal view returns (uint256) {
        StakeList storage _personStakeStatus = stakeLists[_account];

        if (_personStakeStatus.stakesAmount == 0) {
            return _personStakeStatus.rewardsAmount;
        }
        return
            _personStakeStatus.rewardsAmount.add(
                block
                    .timestamp
                    .sub(_personStakeStatus.lastUpdateTime)
                    .mul(rewardRate)
                    .mul(_personStakeStatus.stakesAmount)
                    .div(100000000)
                    .div(86400)
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
     * @notice update minimum deposit amount
     * @param _amount new minimum deposit amount
     */
    function setMinimumDepositAmount(uint256 _amount) external onlyOwner {
        minDeposit = _amount;
    }

    /**
     * @notice change staking contract status
     * @param _status updated status
     */
    function updateStatus(bool _status) external onlyOwner {
        enabled = _status;
    }

    /**
     * @notice change lock time status
     * @param _status updated status
     */
    function updateLockEnabled(bool _status) external onlyOwner {
        lockEnabled = _status;
    }

    /**
     * @notice set lock time
     * @param _lockTime new lock time
     */
    function setLockTime(uint256 _lockTime) external onlyOwner {
        lockTime = _lockTime;
    }

    /**
     * @notice A method to retrieve the amount of depoiste for a stakeholder.
     * @param _stakeholder The stakeholder address.
     * @return uint256 The amount of tokens.
     */
    function depositeOf(address _stakeholder) public view returns (uint256) {
        StakeList storage _personStakeStatus = stakeLists[_stakeholder];
        return _personStakeStatus.stakesAmount;
    }

    /**
     * @notice A method to retrieve the amount of rewards for a stakeholder.
     * @param _stakeholder The stakeholder address.
     * @return uint256 The amount of tokens.
     */
    function rewardOf(address _stakeholder) public view returns (uint256) {
        StakeList storage _personStakeStatus = stakeLists[_stakeholder];
        return _personStakeStatus.rewardsAmount;
    }

    /**
     * @notice A method to get the total amount of the deposied tokens
     */
    function getTotalDepositAmount() public view returns (uint256) {
        return totalDepositAmount;
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
}
