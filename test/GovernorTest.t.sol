// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Box} from "../src/Box.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract GovernorTest is Test {
    uint256 public constant INITIAL_SUPPLY = 100 ether;
    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a proposal passes
    uint256 public constant VOTING_DELAY = 7200; //? How many blocks till a vote is active
    uint256 public constant VOTING_PERIOD = 50400;

    address[] proposers;
    address[] executors;
    uint256[] values;
    bytes[] calldatas;
    address[] targets;

    Box box;
    MyGovernor governor;
    GovernanceToken govToken;
    TimeLock timelock;

    address public USER = makeAddr("USER");

    function setUp() public {
        govToken = new GovernanceToken();
        govToken.mint(USER, INITIAL_SUPPLY);

        vm.startPrank(USER);
        //? needed to allow the USER to 'spend' the token for voting proposals
        govToken.delegate(USER);
        timelock = new TimeLock(MIN_DELAY, proposers, executors);
        governor = new MyGovernor(govToken, timelock);

        //? we want to assign this role to the governor, so that only it can propose
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, USER);
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timelock));
    }

    function test_CantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }

    function test_GovernanceUpdatesBox() public {
        uint256 valueToStore = 21;

        //? This is the actual proposal
        string memory description = "store 21 in Box";
        bytes memory encodedFuncCall = abi.encodeWithSignature("store(uint256)", valueToStore);
        calldatas.push(encodedFuncCall);
        values.push(0);
        targets.push(address(box));

        //1. Propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        //? View the state -> See IGovernor::ProposalState
        console.log("Proposal State:", uint256(governor.state(proposalId)));

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        //2. Vote
        string memory reason = "il grillo del marchese sempre zompa... chi zompa allegramente bene campa!!!";

        // See GovernorCountingSimple::VoteType
        uint8 voteWay = 1; // vote yes
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        //3. Queue the TX
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);

        //4. Execute
        governor.execute(targets, values, calldatas, descriptionHash);

        assert(box.getNumber() == valueToStore);
        console.log("Box value:", box.getNumber());
    }
}