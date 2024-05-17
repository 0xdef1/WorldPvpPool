// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {WorldPvpPool, ERC20, WorldPvpPoolGovernor, GovernorCountingSimple} from "../src/WorldPvpPool.sol";


contract WorldPvpPoolTest is Test {
    WorldPvpPool pool;
    address usaToken = 0x3BCB4D6523b98806Dca200833723fFb32bA672c5;
    address potus = 0x5010D54ADB45b39f97a663fF135d93872A7740f2;

    function setUp() public {
        pool = new WorldPvpPool(usaToken);
        pool.initialize();
    }

    function test_PoolCreate() public {
        assertEq(pool.countryToken(), usaToken);
        assertNotEq(pool.governor(), address(0));
        assertNotEq(pool.timelock(), address(0));
    }

    function test_InitializeOnce() public {
        vm.expectRevert();
        pool.initialize();
    }

    function test_DepositWithdraw() public {
        uint256 bal = ERC20(usaToken).balanceOf(potus);
        
        vm.startPrank(potus);
        ERC20(usaToken).approve(address(pool), bal);
        pool.deposit(bal);
        vm.stopPrank();

        assertEq(pool.balanceOf(potus), ERC20(usaToken).balanceOf(address(pool)));
        assertNotEq(pool.balanceOf(potus), 0);
        assertNotEq(ERC20(usaToken).balanceOf(address(pool)), 0);

        bal = pool.balanceOf(potus);

        vm.startPrank(potus);
        pool.approve(address(pool), bal);
        pool.withdraw(bal);
        vm.stopPrank();

        assertEq(pool.balanceOf(potus), 0);
        assertEq(pool.totalSupply(), 0);
        assertEq(ERC20(usaToken).balanceOf(address(pool)), 0);
        assertNotEq(ERC20(usaToken).balanceOf(potus), 0);
    }

    function test_Governance() public {
        uint256 start = block.number;
        uint256 bal = ERC20(usaToken).balanceOf(potus);

        // Deposit into pool
        vm.startPrank(potus);
        ERC20(usaToken).approve(address(pool), bal);
        pool.deposit(bal);
        pool.delegate(potus);
        vm.stopPrank();

        // Create a proposal
        vm.roll(start + 1);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(pool);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("arbitraryCall(address,bytes)", address(0), "arbitrary calldata");

        vm.startPrank(potus);
        WorldPvpPoolGovernor gov = WorldPvpPoolGovernor(payable(pool.governor()));
        uint256 proposalId = gov.propose(targets, values, calldatas, "test proposal");
        vm.stopPrank();

        // Vote on the proposal
        vm.roll(start + 1 days + 2);
        vm.startPrank(potus);
        gov.castVote(proposalId, uint8(GovernorCountingSimple.VoteType.For));
        vm.stopPrank();

        // Queue the proposal into the timelock
        vm.roll(start + 2 days + 3);
        vm.startPrank(potus);
        gov.queue(targets, values, calldatas, keccak256("test proposal"));
        
        // Execute the proposal
        vm.roll(start + 2 days + 4);
        vm.warp(gov.proposalEta(proposalId) + 1);
        vm.expectEmit(true, true, false, false, address(pool));
        emit WorldPvpPool.ArbitraryCall(address(0), "arbitrary calldata");
        gov.execute(targets, values, calldatas, keccak256("test proposal"));
        vm.stopPrank();
    }
}
