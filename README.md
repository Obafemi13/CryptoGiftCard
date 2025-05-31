# CryptoGiftCard

A Clarity smart contract for sending and redeeming STX gift cards on the Stacks blockchain.

## Overview

CryptoGiftCard allows users to create STX-backed gift cards that can be redeemed by anyone who knows the secret code. Each gift card is protected by a hash of a secret, and can be claimed or cancelled (if expired and unclaimed) by the sender.

## Features

- **Create Gift Card:** Lock STX with a hash of a secret and an expiry block.
- **Redeem Gift Card:** Anyone with the secret can claim the STX before expiry.
- **Cancel Gift Card:** Sender can reclaim funds if the card is unclaimed and expired.
- **View Gift Card:** Read-only function to check the status of a gift card.

## How It Works

1. **Create:**  
   The sender generates a secret, hashes it (using `hash160`), and calls `create-gift` with the hash, amount, and expiry block. STX is transferred to the contract.

2. **Redeem:**  
   The recipient calls `redeem-gift` with the secret. If the hash matches and the card is unclaimed, the STX is transferred to the redeemer.

3. **Cancel:**  
   If the card is unclaimed and expired, the sender can call `cancel-gift` to reclaim the STX.

## Contract Functions

- `create-gift (hash-code (buff 32)) (amount uint) (expiry-block uint)`  
  Create a new gift card.

- `redeem-gift (secret (buff 32))`  
  Redeem a gift card using the secret.

- `cancel-gift (hash-code (buff 32))`  
  Cancel an expired, unclaimed gift card and reclaim funds.

- `get-gift (hash-code (buff 32))`  
  View gift card details (read-only).

## Error Codes

- `u100` Gift already exists
- `u101` Gift already claimed
- `u102` Invalid secret
- `u103` Gift not found
- `u104` Gift not expired
- `u105` Unauthorized
- `u106` STX transfer failed
- `u107` Invalid amount
- `u108` Invalid expiry

## Usage Example

1. **Create a gift card:**
   - Generate a secret (e.g., `my-secret`).
   - Hash it: `hash160('my-secret')`.
   - Call `create-gift` with the hash, amount, and expiry block.

2. **Redeem:**
   - Call `redeem-gift` with the original secret.

3. **Cancel:**
   - After expiry, sender calls `cancel-gift` with the hash.

## Security Notes

- Only the hash of the secret is stored on-chain.
- Only the sender can cancel an expired gift.
- Claimed gifts cannot be redeemed or cancelled again.

