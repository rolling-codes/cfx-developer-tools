# secure-shop

Demonstrates the server-authoritative shop model where prices and item definitions never reach the client.

## Security model

The client sends only `(itemName, quantity)` — never a price. The server:
1. Validates input types
2. Rejects non-integer or negative quantity
3. Looks up the item in its own catalogue (`Config.Items`)
4. Enforces max stack per item
5. Enforces per-player cooldown (anti-spam)
6. Checks server-side proximity (re-validates range the client already checked)
7. Checks player balance against server-computed total
8. Deducts money first, then grants item — refunds on inventory failure

## Patterns demonstrated

- `cfx-client-server`: never trust client-sent price or item availability
- `cfx-performance`: anti-spam cooldown table, O(1) lookup, cleanup on disconnect
- `cfx-framework-detect`: `getPlayerMoney`/`removeMoney`/`giveItem` are stubs — replace with your framework's calls

## Setup

1. Copy `secure-shop/` to your resources directory.
2. Replace the three stub functions at the top of `server/main.lua` with your framework's money and inventory calls.
3. Adjust `Config.Items` and `Config.ShopCoords` in `config.lua`.
4. `ensure secure-shop` in your server config.
