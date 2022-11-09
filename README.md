# Dotocrazy contracts

The process by which this community makes decisions is called on-chain governance, and it has become a central component of decentralized protocols, fueling varied decisions such as parameter integrations with other protocols, treasury management, grants, etc

## Ticket

The voting power of each account in the governance setup will be determined by an ERC721 token. The token has to implement the ERC721Votes extension. This extension will keep track of historical balances so that voting power is retrieved from past snapshots rather than current balance, which is an important protection that prevents double voting.

Thought to have a fast way of bootstraping projects with best practice's in mind. Having linters, prettiers, standards on how to commit, and changelog creation & maintenance.

## Ballot

The core logic is given by the Governor contract, the user will choose: how voting power is determined, how many votes are needed for quorum, what options people have when casting a vote and how those votes are counted, and what type of token should be used to vote. Each of these aspects are customizable.

## Setup

```bash
# Install dependencies
yarn install
# Copy Env example file
cp .env.example .env
```

## Tools

This boilerplate includes:

- [Hardhat](https://hardhat.org/)
- [Solhint](https://github.com/protofire/solhint)
- [Prettier](https://github.com/prettier-solidity/prettier-plugin-solidity)
- [Coverage](https://github.com/sc-forks/solidity-coverage)
- [Gas reporter](https://github.com/cgewecke/hardhat-gas-reporter/tree/master)
- [Commitlint](https://github.com/conventional-changelog/commitlint)
- [Standard version](https://github.com/conventional-changelog/standard-version)

---

## Commands

### **Coverage**

```bash
yarn coverage
```

Runs solidity code coverage
<br/>

### **Fork**

```bash
yarn fork
```

Runs a mainnet fork via hardhat's node forking util.

```bash
yarn fork:script {path}
```

Runs the script in mainnet's fork.

```
yarn fork:test
```

Runs tests that should be run in mainnet's fork.
<br/>

### **Lint**

```bash
yarn lint:check
```

Runs solhint.
<br/>

### **Prettier (lint fix)**

```bash
yarn lint:fix
```

Runs prettier
<br/>

### **Release**

```bash
yarn release
```

Runs standard changelog, changes package.json version and modifies CHANGELOG.md accordingly.
<br/>

### **Gas report**

```bash
yarn test:gas
```

Runs all tests and report gas usage.
