# Doppler

[![Test](https://github.com/whetstoneresearch/doppler/actions/workflows/test.yml/badge.svg)](https://github.com/whetstoneresearch/doppler/actions/workflows/test.yml)

This reposity contains the [Doppler](docs/Doppler.md) Protocol, and the integration scripts and contracts for Long to build on top of Doppler.

## Installation

First, you will need to install [Foundry](https://book.getfoundry.sh/getting-started/installation) if you don't already have it. Then, run the following commands:

```shell
# Clone the repository
$ git clone https://github.com/Nim-Network-Foundation/longxyz-contracts.git

# Install the dependencies
$ forge install
```

## Usage

**BEFOREHAND** - Prepare the _RPC URL_ and _private key_ in `.env` for running scripts

```shell
$ cp .env.example .env
```

```
UNICHAIN_SEPOLIA_RPC_URL="https://sepolia.unichain.org"
PRIVATE_KEY=0x...
```

### Migrate after token graduation

```shell
# load the environment variables
source .env

# --broadcast can be removed to simulate the call
forge script ./script/MigratePool.s.sol --rpc-url $UNICHAIN_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Test

```shell
$ forge test
```

Tests can be tweaked from the `.env` file, this is a nice way to try different testing scenarios without recompiling the contracts:

```shell
IS_TOKEN_0=FALSE
USING_ETH=FALSE
FEE=30
```

### Deploy

First be sure to set the `PROTOCOL_OWNER` variable in your .env file. V1 contracts running on Uniswap V3 can be deployed using the following command:

```shell
# load the environment variables
source .env

# --rpc-url is the chain you want to deploy to
# --private-key is the deployer wallet (not the owner)
forge script ./script/V1DeploymentScript.s.sol --rpc-url $UNICHAIN_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```
