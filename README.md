# Guildly Contracts

An implementation for having guilds for on-chain games on Starknet.

_Disclaimer: This code is not intended for production use and has not been audited or tested thoroughly_

## Description

The purpose of this project is to create a multi owner guild where players can share the game assets between eachother. The guild is token gated, a certificate is minted to identify roles, tokens you own etc.

## Instructions

In order to create a guild follow these steps:

- Deploy a guild contract from the Guild Manager (Factory contract).
- Initialize permissions of the guild, this is setting some contracts addresses and selectors which the guild can interact with.
- Add members to your guild, choosing their access roles.
- Deposit some tokens into the guild.
- Members of the guild can interact with functions permitted, while also using tokens withiin it.

## Testing

Some tests have been created in snforge. You can run `scarb test` to run them in the main directory.

## TODO

- [x] Add proxy testing
- [ ] Bit mapped roles
- [ ] Reward distribution
