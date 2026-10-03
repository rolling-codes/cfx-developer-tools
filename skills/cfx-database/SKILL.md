---
name: cfx-database
description: >-
  Guide oxmysql database queries, schema design, and migrations for FiveM/RedM
  resources. Use when the user asks about "database", "MySQL", "oxmysql",
  "save player data", "INSERT INTO", "SQL query", "database table", "migration",
  or "persistent storage". NOT for server-side scripting unrelated to the database
  (cfx-client-server); NOT for general SQL engine questions unrelated to oxmysql.
model: sonnet
allowed-tools: [Read, Grep, Glob, Edit, Write]
last-verified: 2026-10-03
volatility: high
---

# CFX Database Integration

Most FiveM and RedM RP servers use MySQL for persistent data. The standard library is **oxmysql**, which provides async MySQL queries from Lua and JavaScript resources.

## Iron Law

Always use parameterized queries with `@param` placeholders instead of string concatenation, because string-built queries are vulnerable to SQL injection from any untrusted input — and in FiveM, player-supplied strings (names, identifiers, messages) are untrusted input.

## Red Flags

| Excuse | Why it's wrong | What to do instead |
|---|---|---|
| "I'll build the query with string concatenation, it's easier to read" | String concatenation is SQL injection; a player named `'; DROP TABLE players; --` destroys the database | Always use `@param` placeholders; oxmysql handles escaping |
| "mysql-async is fine, the server already has it installed" | mysql-async and ghmattimysql are deprecated and unmaintained; new resources should not depend on them | Use oxmysql; mention migration if the codebase uses the old libraries |
| "I'll run queries from client scripts since the data is needed client-side" | Database access must only happen server-side; clients should receive data via TriggerClientEvent after a server-side query | All MySQL queries go in server scripts only |
| "I'll use `.await` directly in my event handler since it's cleaner" | `.await` variants suspend the coroutine — calling them outside a `Citizen.CreateThread` or ox_lib callback deadlocks the entire resource thread silently | Wrap any code that calls `.await` in `Citizen.CreateThread(function() ... end)` or use the callback variant instead |
| "I'll `SELECT *` for simplicity and filter in Lua" | Fetching all columns returns TEXT/BLOB fields and unneeded data across the network; on busy servers this compounds with every player query | Select only the columns you need: `SELECT identifier, money, job FROM players WHERE ...` |

## Output format

Lead with the complete working Lua code snippet. Append a compact safety note only when the request involves a pattern that could cause injection risk, a coroutine context issue, or a deprecated library — skip the note otherwise.

## Setup

### 1. Install oxmysql

Download from https://github.com/overextended/oxmysql/releases and place in the server's `resources/` folder.

### 2. Configure the connection string

In `server.cfg`:

```
set mysql_connection_string "mysql://user:password@localhost/database?charset=utf8mb4"
```

Or use the legacy format:

```
set mysql_connection_string "server=localhost;database=mydb;userid=user;password=pass;"
```

### 3. Add to fxmanifest.lua

```lua
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}
```

## Query patterns (Lua)

### Async with callback (non-blocking, preferred for performance)

```lua
MySQL.query('SELECT * FROM players WHERE identifier = @identifier', {
    ['@identifier'] = playerIdentifier
}, function(result)
    if result and #result > 0 then
        -- handle result
    end
end)
```

### Async with await (cleaner syntax, requires Lua coroutine or ox_lib)

```lua
local result = MySQL.query.await('SELECT * FROM players WHERE identifier = @identifier', {
    ['@identifier'] = playerIdentifier
})
if result and #result > 0 then
    -- handle result
end
```

### Insert

```lua
MySQL.insert('INSERT INTO player_vehicles (owner, model, plate) VALUES (@owner, @model, @plate)', {
    ['@owner'] = playerIdentifier,
    ['@model'] = vehicleModel,
    ['@plate'] = vehiclePlate
}, function(insertId)
    print('Inserted vehicle with id:', insertId)
end)
```

### Update

```lua
MySQL.update('UPDATE players SET money = @money WHERE identifier = @identifier', {
    ['@money'] = newMoney,
    ['@identifier'] = playerIdentifier
}, function(affectedRows)
    print('Updated', affectedRows, 'rows')
end)
```

### Single value

```lua
local money = MySQL.scalar.await('SELECT money FROM players WHERE identifier = @identifier', {
    ['@identifier'] = playerIdentifier
})
```

### Transaction (multiple queries atomically)

```lua
MySQL.transaction({
    { query = 'UPDATE players SET money = money - @cost WHERE identifier = @id', values = { ['@cost'] = cost, ['@id'] = sellerId } },
    { query = 'UPDATE players SET money = money + @cost WHERE identifier = @id', values = { ['@cost'] = cost, ['@id'] = buyerId } }
}, function(success)
    if success then
        -- transaction committed
    end
end)
```

## Parameterized queries

Always use `@paramName` syntax. oxmysql accepts both `@name` and `?` positional placeholders:

```lua
-- Named (recommended — readable, order-independent)
MySQL.query('SELECT * FROM vehicles WHERE owner = @owner AND model = @model', {
    ['@owner'] = identifier,
    ['@model'] = model
})

-- Positional (works but harder to maintain)
MySQL.query('SELECT * FROM vehicles WHERE owner = ? AND model = ?', {
    identifier, model
})
```

## Prepared statements (oxmysql v2.7+)

For queries executed repeatedly with different parameters (e.g., per-player lookups in tight loops), prepared statements avoid re-parsing the query on each call:

```lua
-- Create once (server startup or resource init)
local stmt = MySQL.prepare('SELECT money FROM players WHERE identifier = ?')

-- Execute as many times as needed
MySQL.prepare.await(stmt, { playerIdentifier })
```

Use the `?` positional placeholder (not `@name`) with prepared statements. The performance benefit is only meaningful for very high-frequency queries; default `.query` is fine for normal per-action use.

## Deprecated libraries — migration notes

**mysql-async** and **ghmattimysql** are deprecated and unmaintained. If the codebase uses them, suggest migration:

| Old | New |
|---|---|
| `MySQL.Async.fetchAll(query, params, cb)` | `MySQL.query(query, params, cb)` |
| `MySQL.Async.execute(query, params, cb)` | `MySQL.update(query, params, cb)` |
| `MySQL.Async.fetchScalar(query, params, cb)` | `MySQL.scalar(query, params, cb)` |
| `exports.oxmysql:execute(...)` | `MySQL.update(...)` (after `@oxmysql/lib/MySQL.lua` is in server_scripts) |

## Common schema patterns

### Players table

```sql
CREATE TABLE IF NOT EXISTS `players` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `money` INT NOT NULL DEFAULT 0,
    `job` VARCHAR(50) NOT NULL DEFAULT 'unemployed',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### Player vehicles table

```sql
CREATE TABLE IF NOT EXISTS `player_vehicles` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(60) NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `plate` VARCHAR(10) NOT NULL,
    `fuel` FLOAT NOT NULL DEFAULT 100.0,
    `body` FLOAT NOT NULL DEFAULT 1000.0,
    PRIMARY KEY (`id`),
    KEY `idx_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## Migration patterns

For schema migrations on resource start:

```lua
MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `my_resource_data` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `key` VARCHAR(100) NOT NULL,
        `value` TEXT,
        PRIMARY KEY (`id`),
        UNIQUE KEY `key` (`key`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]])
```

Run this in the resource's `onServerResourceStart` or at the top of the server script.

## Tips

- All database operations must run server-side only — clients receive results via events
- Use `.await` variants inside coroutines (ox_lib or Citizen.CreateThread with coroutine wrapping)
- Log query errors explicitly: oxmysql surfaces errors to the server console by default
- Index foreign keys (`owner`, `identifier` columns) to avoid full-table scans on join-heavy queries
- Keep transactions short — long transactions increase lock contention on busy servers
