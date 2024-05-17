pragma solidity >=0.8.23;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "openzeppelin-contracts/contracts/utils/Nonces.sol";
import {TimelockController} from "openzeppelin-contracts/contracts/governance/TimelockController.sol";
import "openzeppelin-contracts/contracts/governance/Governor.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorSettings.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorCountingSimple.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorVotes.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorTimelockControl.sol";

contract WorldPvpPool is ERC20, ERC20Votes, ERC20Permit {

    address public countryToken;
    address public governor;
    address public timelock;

    // reentrancy lock
    uint8 private unlocked = 1;

    error Reentrant();
    error OnlyGovernance();
    error NaughtyCall();
    error AlreadyInitialized();

    event ArbitraryCall(address who, bytes data);
    event Deposit(address from, uint256 amountDeposited, uint256 amountMinted);
    event Withdraw(address to, uint256 amountBurned);
    event Initialize(address countryToken, address timelock, address governor);

    modifier lock {
        if (unlocked != 1) revert Reentrant();
        unlocked = 2;
        _;
        unlocked = 1;
    }

    modifier onlyGovernance() {
        if (msg.sender != timelock) revert OnlyGovernance();
        _;
    }

    constructor(address _countryToken) 
        ERC20("WorldPvp Pool", "WPVP-POOL") 
        ERC20Permit("WorldPvp Pool") 
    {
        countryToken = _countryToken;
    }

    function initialize() public {
        if (governor != address(0) || timelock != address(0)) revert AlreadyInitialized();

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);

        TimelockController t = new TimelockController(86400, proposers, executors, address(this));
        WorldPvpPoolGovernor g = new WorldPvpPoolGovernor(IVotes(address(this)), t);
        
        t.grantRole(t.PROPOSER_ROLE(), address(g));
        t.grantRole(t.EXECUTOR_ROLE(), address(g));
        t.renounceRole(t.DEFAULT_ADMIN_ROLE(), address(this));
        
        timelock = address(t);
        governor = address(g);

        emit Initialize(countryToken, timelock, governor);
    }

    function deposit(uint256 amount) public lock {
        // Be careful of tax shenanigans
        uint256 balanceBefore = ERC20(countryToken).balanceOf(address(this));
        ERC20(countryToken).transferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = ERC20(countryToken).balanceOf(address(this));
        uint256 mintAmount = balanceAfter - balanceBefore;

        _mint(msg.sender, mintAmount);
        emit Deposit(msg.sender, amount, mintAmount);
    }

    function withdraw(uint256 amount) public lock {
        _burn(msg.sender, amount);

        // Taxes will reduce the actual amount of countryToken received
        ERC20(countryToken).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function arbitraryCall(address who, bytes calldata data) external lock onlyGovernance {
        if (who == address(this) || who == countryToken) revert NaughtyCall();

        (bool success, ) = who.call(data);
        require(success);

        emit ArbitraryCall(who, data);
    }

    function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._update(from, to, amount);
    }

    function nonces(address owner) public view virtual override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}

contract WorldPvpPoolGovernor is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction, GovernorTimelockControl {
    constructor(IVotes _token, TimelockController _timelock)
        Governor("MyGovernor")
        GovernorSettings(1 days, 1 days, 0)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(1)
        GovernorTimelockControl(_timelock)
    {}

    // The following functions are overrides required by Solidity.

    function votingDelay()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function proposalNeedsQueuing(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _queueOperations(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint48)
    {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _executeOperations(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
    {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }
}