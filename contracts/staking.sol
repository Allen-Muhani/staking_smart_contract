// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * Holds staking rate data for history purposes.
 */
struct StakingRateData {
    uint256 updatedTimestamp;
    address upgraderAddress;
    uint256 rate;
}

/**
 * Staking smart contract.
 */
contract Staking {
    mapping(address => uint256) stakedAmount;
    mapping(address => uint256) stakingStartTimestamp;

    mapping(uint256 => StakingRateData) stakingRateHistory;

    uint256 totalStakedAmount = 0;

    uint256 totalRewardedAmount = 0;

    uint256 rewardRate = 0;

    event NewStake(address staker, address token, uint256 amount, uint256 rate);

    event Withdraw(
        address staker,
        address token,
        uint256 totalAmount,
        uint256 reward
    );

    event UpdateRewardRate(uint256 newRate);

    /**
     * Updates the reward rate;
     * @param rate the reward rate;
     */
    function updateRewardRate(uint256 rate) public {
        rewardRate = rate;

        uint256 timestamp = block.timestamp;
        StakingRateData storage rateData = stakingRateHistory[timestamp];
        rateData.updatedTimestamp = timestamp;
        rateData.upgraderAddress = msg.sender;
        rateData.rate = rate;

        emit UpdateRewardRate(rate);
    }

    /**
     * Calculate the reward of a stake
     * @param targetAddress the address that has staked funds.
     * @return the calculated reward.
     */
    function calculateStakeReward(
        address targetAddress
    ) public returns (uint256) {
        require(stakingStartTimestamp[targetAddress] > 0);
        uint256 reward = rewardRate *
            stakedAmount[targetAddress] *
            (block.timestamp - stakingStartTimestamp[targetAddress]);
        return reward;
    }

    /**
     * Stakes funds for a given user.
     * @param amount the staked amount.
     * @param tokenAddress the token address.
     */
    function stake(uint256 amount, address tokenAddress) public {
        require(
            stakedAmount[msg.sender] == 0,
            "You have alread placed a stake."
        );
        require(amount > 0, "You can not stake a negative value");
        require(
            ERC20(tokenAddress).balanceOf(address(msg.sender)) > amount,
            "Amount exeeeds your current balance"
        );

        require(
            ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount),
            "You don't have enough tokens to accept this request."
        );

        emit NewStake(msg.sender, tokenAddress, amount, rewardRate);
    }

    /**
     * Withdraws stake and earned reward based on time, rate and amount staked.
     */
    function withdraw(address tokenAddress) public {
        require(stakingStartTimestamp[msg.sender] > 0);

        uint256 reward = calculateStakeReward(msg.sender);
        totalRewardedAmount = reward + totalRewardedAmount;

        require(
            ERC20(tokenAddress).transferFrom(
                address(this),
                msg.sender,
                reward + stakedAmount[msg.sender]
            ),
            "Not enough tokens at the moment to withdraw."
        );

        emit Withdraw(
            msg.sender,
            tokenAddress,
            stakedAmount[msg.sender],
            reward
        );

        stakingStartTimestamp[msg.sender] = 0;
        stakedAmount[msg.sender] = 0;
    }
}
