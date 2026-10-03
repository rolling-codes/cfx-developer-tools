# Templates

Ready-to-copy resource starters for every major FiveM/RedM framework. Copy the relevant folder into your server's resources directory and rename it.

## Available templates

| Template | Game | Framework |
|---|---|---|
| `standalone/` | GTA5 + RDR3 | No framework |
| `esx/` | GTA5 | ESX (es_extended) |
| `qbcore/` | GTA5 | QBCore (qb-core) |
| `qbox/` | GTA5 | Qbox (qbx_core) |
| `oxcore/` | GTA5 | ox_core + ox_lib |
| `rsg/` | RDR3 | RSG-core |
| `vorp/` | RDR3 | VORP Core |
| `javascript/` | GTA5 | Vanilla JS (no framework) |
| `nui/` | GTA5 | Vanilla NUI (HTML/CSS/JS) |

## Usage

1. Copy the template folder:
   ```
   cp -r templates/esx/ path/to/resources/my-resource
   ```

2. Rename the resource in `fxmanifest.lua`:
   ```lua
   name 'my-resource'
   ```

3. Add to your server config:
   ```
   ensure my-resource
   ```

## Notes

- All templates are framework-minimal — only the init boilerplate, no business logic.
- Event names use the `myResource:` prefix. Replace with your actual resource name to avoid conflicts.
- Templates **do not include `lua54`** — that directive is deprecated and ignored by the CFX runtime.
- For oxcore templates: `ox_lib` must be started before your resource.
