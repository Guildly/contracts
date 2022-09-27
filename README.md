# Guildly Contracts

An implementation for having guilds for on-chain games on Starknet.

_Disclaimer: This code is not intended for production use and has not been audited or tested thoroughly_

## Description

The purpose of this project is to create a multi owner guild where players can share the game assets between eachother. The guild is token gated, a certificate is minted to identify roles, tokens you own etc.

## Instructions

In order to create a guild follow these steps:

- Deploy a guild contract from the Guild Manager (Factory contract).
- Initialize permissions of the guild, this is setting some contracts addresses and selectors which the guild can interact with.
- Whitelist members to your guild, choosing their acess roles (after which they can then opt to join).
- Deposit some tokens into the guild.
- Members of the guild can interact with functions permitted, while also using tokens withiin it.

## Browser Extension

There is a browser extension in development to allow easy use and access to guild contracts. The browser extension code and instructions are in this [Repo](https://github.com/Guildly/guildly-extension).

## Testing

- Starknet client in pytest used for unit tests (tests)
- Nile scripts used for testnet deployment (under guildly_cli)

## TODO

- [x] Add proxy testing
- [ ] Dynamic roles
- [ ] Reward distribution

## Setup

```
python3.9 -m venv venv
source venv/bin/activate
python -m pip install cairo-nile
nile install
```

## Acknowledgements

[udayj](https://twitter.com/udayj) for their implementation of a [token gated account](https://github.com/udayj/token_gated_account)
