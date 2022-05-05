# DeFi Staking Protocol

This project is my attempt at understanding how a defi staking protocol Dapp works, and I believe the best way to learn about how all this stuff works is to actually do it. This is part of the Chainlink 2022 hackathon, and the initial references are from there.

My plan is to add onto this code as my knowledge expands and I learn more. And currently plan to use this Dapp as an exploration into [Fleek](https://fleek.co) hosting and it's capabilities

I encourage you to take a look at the [Staking contract](./contracts/Staking.sol) and read some comments, as a majority of the logic and some small details are written there as I code.

## How it works

This is the most common staking protocol used in DeFi. This is a very minimalistic contract that has a Stake function, a Withdraw function, and a Claim (rewards from staking) function. This contract pays out 100 tokens per second, divided by the total value staked in the contract. Natually, as more users utilize this contract, the less rewards are paid out, and the less APR percentage is paid. This is by design to not bankrupt the protocol.

This does not take into account what the staked tokens are used for at this time, so ideally the protocol owner can determine what to do with the tokens staked to leverage the tokens of other people, while rewarding the investors.

## Front End

I also have a simple front end to utilize these contracts and can be found [here](https://github.com/auto-mausx/Defi-Staking-Protocol-Front-End), also from the Chainlink Hackathon 2022.

## Getting Started

- run `yarn install` to install all needed dependancies

- run `yarn hardhat` if you wish to start your own project, I recommend starting with just a hardhat.config.js

- if you want to reuse what I have here, you can complie the contract(s) with `yarn hardhat compile`

## Technologies Used

- Hardhat
- OpenZeppelin
- Solidity

## Useful Detailed information

- [Staking Protocol Math](youtube.com/watch?v=LWWsjw3cgDk)
- [Reentrancy Explained](https://solidity-by-example.org/hacks/re-entrancy)
