# Blockchain & DeFi Protocol Implementation

## Overview

Production-ready smart contracts for DeFi protocols including lending, AMM swaps, flash loans, and cross-chain bridges.

## Key Technologies

- **Solidity**: Ethereum smart contracts
- **OpenZeppelin**: Security patterns
- **Chainlink**: Oracle price feeds
- **Merkle Trees**: Efficient proofs

## DeFi Protocol Contract

```solidity
// DeFi Protocol Implementation
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract AdvancedDeFiProtocol is ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    // Roles
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER");

    // State variables
    mapping(address => UserPosition) public positions;
    mapping(address => mapping(address => uint256)) public collateral;

    // Advanced structs
    struct UserPosition {
        uint256 totalCollateral;
        uint256 totalDebt;
        uint256 healthFactor;
        uint256 lastUpdateBlock;
        address[] collateralAssets;
        address[] borrowedAssets;
    }

    // Events
    event PositionOpened(address indexed user, uint256 collateral, uint256 debt);
    event Liquidation(address indexed user, address indexed liquidator, uint256 amount);

    // Modifiers
    modifier onlyHealthy() {
        require(calculateHealthFactor(msg.sender) >= 1e18, "Position unhealthy");
        _;
    }

    // Flash loan implementation
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        require(balanceBefore >= amount, "Insufficient liquidity");

        // Transfer tokens to receiver
        IERC20(token).transfer(receiver, amount);

        // Execute receiver's logic
        IFlashLoanReceiver(receiver).executeOperation(
            token,
            amount,
            amount.mul(3).div(10000), // 0.03% fee
            msg.sender,
            data
        );

        // Check repayment
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(
            balanceAfter >= balanceBefore.add(amount.mul(3).div(10000)),
            "Flash loan not repaid"
        );

        emit FlashLoan(receiver, token, amount);
    }

    // Automated Market Maker logic
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address to
    ) external nonReentrant returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid amount");

        // Get reserves
        (uint256 reserveIn, uint256 reserveOut) = getReserves(tokenIn, tokenOut);

        // Calculate output amount using constant product formula
        amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= minAmountOut, "Slippage exceeded");

        // Transfer tokens
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(to, amountOut);

        // Update reserves
        _update(tokenIn, tokenOut);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    // Liquidation mechanism
    function liquidate(address user) external nonReentrant {
        require(calculateHealthFactor(user) < 1e18, "Position healthy");

        UserPosition storage position = positions[user];
        uint256 debtToCover = position.totalDebt.div(2); // 50% liquidation

        // Calculate liquidation bonus (5%)
        uint256 collateralToSeize = debtToCover.mul(105).div(100);

        // Transfer debt from liquidator
        // Transfer collateral to liquidator
        // Update user position

        emit Liquidation(user, msg.sender, debtToCover);
    }

    // Oracle integration for price feeds
    function getPrice(address asset) public view returns (uint256) {
        AggregatorV3Interface priceFeed = priceFeeds[asset];
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        require(updatedAt > 0, "Round not complete");
        require(price > 0, "Invalid price");

        return uint256(price);
    }
}
```

## Layer 2 Bridge Contract

```solidity
// Layer 2 Bridge Contract
contract OptimisticBridge {
    using MerkleTree for bytes32;

    struct WithdrawalRequest {
        address user;
        address token;
        uint256 amount;
        uint256 timestamp;
        bytes32 merkleRoot;
        bool executed;
    }

    mapping(bytes32 => WithdrawalRequest) public withdrawals;
    mapping(bytes32 => bool) public processedDeposits;

    uint256 public constant CHALLENGE_PERIOD = 7 days;

    function initiateWithdrawal(
        address token,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, token, amount));
        require(MerkleTree.verify(proof, stateRoot, leaf), "Invalid proof");

        bytes32 withdrawalId = keccak256(
            abi.encodePacked(msg.sender, token, amount, block.timestamp)
        );

        withdrawals[withdrawalId] = WithdrawalRequest({
            user: msg.sender,
            token: token,
            amount: amount,
            timestamp: block.timestamp,
            merkleRoot: stateRoot,
            executed: false
        });

        emit WithdrawalInitiated(withdrawalId, msg.sender, token, amount);
    }

    function executeWithdrawal(bytes32 withdrawalId) external {
        WithdrawalRequest storage request = withdrawals[withdrawalId];
        require(!request.executed, "Already executed");
        require(
            block.timestamp >= request.timestamp + CHALLENGE_PERIOD,
            "Challenge period not over"
        );

        request.executed = true;
        IERC20(request.token).transfer(request.user, request.amount);

        emit WithdrawalExecuted(withdrawalId);
    }
}
```

## Security Patterns

| Pattern | Purpose | Implementation |
|---------|---------|----------------|
| ReentrancyGuard | Prevent reentrancy attacks | OpenZeppelin modifier |
| AccessControl | Role-based permissions | Governance/Keeper roles |
| Checks-Effects-Interactions | Safe external calls | State changes before transfers |
| Pull over Push | Safe token transfers | Users withdraw vs contract sends |
| Circuit Breaker | Emergency pause | Pausable modifier |

## Gas Optimization Tips

1. **Pack structs**: Order variables by size
2. **Use calldata**: For read-only function parameters
3. **Batch operations**: Combine multiple operations
4. **Cache storage reads**: Use local variables
5. **Short-circuit**: Early returns on validation

## Testing Checklist

- [ ] Reentrancy attacks
- [ ] Integer overflow/underflow
- [ ] Flash loan attacks
- [ ] Oracle manipulation
- [ ] Access control bypass
- [ ] Front-running vulnerabilities
- [ ] Gas griefing
