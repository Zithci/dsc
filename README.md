# Decentralised Stablecoin (DSC)

A decentralised, algorithmic stablecoin pegged to USD, backed by exogenous collateral (WETH, WBTC). Built with Foundry as part of Patrick Collins' Foundry course.

## Overview

DSC is an overcollateralised stablecoin — users must deposit at least 200% collateral value to mint DSC. If a position drops below 200% collateralisation, it becomes eligible for liquidation.

**Contracts:**
- `DecentralisedStableCoin.sol` — ERC20 stablecoin token, owned and controlled by DSCEngine
- `DSCEngine.sol` — Core protocol logic: deposit, mint, redeem, burn, liquidate

**Key mechanics:**
- Liquidation threshold: 50% (must maintain 200% collateral ratio)
- Liquidation bonus: 10% incentive for liquidators
- Price feeds: Chainlink oracles with 3-hour staleness check

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Setup

```bash
git clone https://github.com/Zithci/dsc.git
cd dsc
forge install
```

### Environment

Create a `.env` file:

```
SEPOLIA_RPC_URL=your_rpc_url
PRIVATE_KEY=your_private_key
ETHERSCAN_API_KEY=your_api_key
```

## Usage

```bash
# Build
forge build

# Test
forge test

# Test with gas report
forge test --gas-report

# Format
forge fmt

# Deploy to Sepolia
forge script script/DeplyoyDSC.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

## Test Coverage

14 unit tests covering:
- Deployment
- Collateral deposit / revert cases
- DSC minting / revert cases
- Health factor enforcement
- Collateral redemption
- DSC burning
- Liquidation (happy path + revert cases)
