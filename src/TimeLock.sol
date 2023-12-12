// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
    /**
     *
     * @param minDelay is the time you have to wait before executing
     * @param proposers is the list of addressed that can propose
     * @param executors is the list of addressed that can execute
     */
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors /* , address admin */ )
        TimelockController(minDelay, proposers, executors, msg.sender)
    {}
}
