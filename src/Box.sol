// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
    uint256 private s_number;

    event NumberChanged(uint256 number);

    constructor() Ownable(msg.sender) {}

    function store(uint256 _newNumber) public onlyOwner {
        s_number = _newNumber;
        emit NumberChanged(_newNumber);
    }

    function getNumber() external view returns (uint256) {
        return s_number;
    }
}
