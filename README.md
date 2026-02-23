# MINT-authority

## Overview

`MINT-authority.clar` is a Clarity smart contract designed to govern mint permissions for an external token contract. It enforces strict controls over who can mint, tracks total minted supply, and provides emergency pause functionality.

## Features

- **Role-based Mint Authorization:** Only authorized minters (or the owner) can mint tokens.
- **Global Supply Cap:** Enforces a maximum supply limit for minted tokens.
- **Emergency Pause:** Allows the owner to pause or resume minting globally.
- **Total Minted Tracking:** Keeps a record of the total tokens minted via this authority.
- **Minter Management:** Owner can add or remove authorized minters.
- **Supply Configuration:** Owner can update the maximum supply, but not below already minted amount.

## Contract Structure

- **Ownership:** Deployer is the initial owner.
- **Minter Registry:** Maintains a list of authorized minters.
- **Supply Control:** Tracks total minted and enforces a hard cap.
- **Emergency Pause:** Enables/Disables minting globally.
- **Token Trait:** Requires external token contracts to implement a compatible mint function.

## Usage

1. **Deploy the contract.**  
   The deployer becomes the initial owner.

2. **Grant mint privileges** to this contract in your token contract.

3. **Add authorized minters** using `add-minter`.

4. **Mint tokens** via the `mint` function, which calls the external token contract.

5. **Pause or unpause minting** as needed for emergencies.

## Public Functions

- `mint(token, recipient, amount)`  
  Mints tokens to a recipient via the external token contract.

- `add-minter(minter)`  
  Adds a new authorized minter.

- `remove-minter(minter)`  
  Removes an authorized minter.

- `set-max-supply(new-max)`  
  Updates the maximum supply.

- `pause()`  
  Pauses minting globally.

- `unpause()`  
  Resumes minting.

## Read-Only Functions

- `get-owner()`  
- `get-total-minted()`  
- `get-max-supply()`  
- `is-authorized-minter(who)`  
- `is-paused()`

## Error Codes

- `ERR-UNAUTHORIZED` (u100)
- `ERR-PAUSED` (u101)
- `ERR-INVALID-AMOUNT` (u102)
- `ERR-SUPPLY-EXCEEDED` (u103)

## Requirements

- External token contract must implement the `mintable-trait`.
