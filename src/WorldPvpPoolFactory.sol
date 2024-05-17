pragma solidity >=0.8.23;

import {WorldPvpPool} from "./WorldPvpPool.sol";

contract WorldPvpPoolFactory {
    mapping(address => address) public poolForToken;
    uint256 public numPools;
    address[] pools;

    error DuplicatePool();

    event PoolCreated(address countryToken, address pool);

    function createPool(address _countryToken) external returns (address) {
        if (poolForToken[_countryToken] != address(0)) revert DuplicatePool();

        WorldPvpPool p = new WorldPvpPool(_countryToken);
        p.initialize();

        poolForToken[_countryToken] = address(p);
        pools.push(address(p));
        numPools++;

        emit PoolCreated(_countryToken, address(p));
        return address(p);
    }

    function poolAtIndex(uint256 index) external view returns (address) {
        return pools[index];
    }
}
