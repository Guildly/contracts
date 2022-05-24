# Game Guilds
An implementation for having guilds for on-chain games on Starknet.

_Disclaimer: This code is not intended for production use and has not been audited or tested thoroughly_

## Description
The purpose of this project is to create a multi owner guild where players can share the game assets between eachother. The guild is token gated, a certificate is minted to identify roles, tokens you own etc.

This project provides the following:

  - Contract deployed by a guild master with the certificate address.
  - Function callable by master to set permissions on transactions allowed.
  - Master can add some original owners.
  - Owners can deposit ERC721 tokens. These are stored in the certificate.
  - Owners can withdraw the tokens they have deposited.
  - Members can only make transactions from the guild that are permitted.

## Testing

<<<<<<< HEAD
- Starknet client in pytest used for unit tests (tests)
=======
- Starknet client in pytest used for unit tests(tests)
>>>>>>> 8baf405da090f9ece294e27ec8557063a70104a0
- Nile scripts used for testnet deployment (nile)
- Ape used for integration testing (ape - pending library updates)

## Setup

```
python3.7 -m venv venv
source venv/bin/activate
python -m pip install cairo-nile
nile install
```

## Acknowledgements

[udayj](https://twitter.com/udayj) for their implementation of a [token gated account](https://github.com/udayj/token_gated_account)
