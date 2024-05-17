// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {WorldPvpPool, ERC20} from "../src/WorldPvpPool.sol";
import {WorldPvpPoolFactory} from "../src/WorldPvpPoolFactory.sol";


// Tests should be run with --fork-url option, with a Base mainnet rpc.
// Address 'potus' should have some balance of 'USA' token to wrap + vote with
contract WorldPvpPoolFactoryTest is Test {
    WorldPvpPoolFactory factory;
    address usaToken = 0x3BCB4D6523b98806Dca200833723fFb32bA672c5;
    address potus = 0x5010D54ADB45b39f97a663fF135d93872A7740f2;

    function setUp() public {
        factory = new WorldPvpPoolFactory();
    }

    function test_PoolCreate() public {
        WorldPvpPool pool = WorldPvpPool(factory.createPool(usaToken));

        assertEq(pool.countryToken(), usaToken);
        assertNotEq(pool.governor(), address(0));
        assertNotEq(pool.timelock(), address(0));

        vm.expectRevert();
        factory.createPool(usaToken);

        assertEq(factory.poolAtIndex(0), address(pool));
        assertEq(factory.poolForToken(usaToken), address(pool));
    }
}
