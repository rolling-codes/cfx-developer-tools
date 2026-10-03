# Examples

Complete, runnable FiveM resources demonstrating production patterns from the cfx-developer-tools skill pack.

## Available examples

| Example | Skills demonstrated | Key patterns |
|---|---|---|
| `doorlock/` | cfx-state-bags, cfx-client-server | Server-authoritative state, StateBags replication, range check, anti-spam |
| `playtime-tracker/` | cfx-database, cfx-client-server | oxmysql prepared statements, periodic flush, `/playtime` command |
| `secure-shop/` | cfx-client-server, cfx-framework-detect | Never-trust-client pricing, 8 input validations, refund on failure |
| `speedometer-hud/` | cfx-nui, cfx-performance | Rate-limited SendNUIMessage, dynamic Wait(0/500), vanilla NUI |

## Setup

Each example has its own `README.md` with specific setup instructions. General steps:

1. Copy the example folder to your server's resources directory.
2. Run any SQL files in `sql/` against your database.
3. Adjust `config.lua` for your server.
4. `ensure <example-name>` in your server config.

## Notes

- All examples are standalone — no external framework required unless noted in the example's README.
- None of these examples use `lua54` — the directive is deprecated.
- Event names are namespaced to the resource. In production, replace `myResource:` with your actual resource name.
- Server scripts validate all client input. The server is always the authority.
