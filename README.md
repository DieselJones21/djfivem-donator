# Rebel Donator (`dj-donator`)

FiveM donator store with a **Rebel Coins** currency, a red / white / black dashboard UI, oxmysql persistence, and Discord webhook logs for every purchase and admin action.

Open with **F7** or `/donator`.

## Features

- **Vehicles** — bronze, silver, and gold tiers, stored in **JG Advanced Garages** after purchase (ESX / QB / Qbox fallback if JG is not started)
- **Weapons & extras** — granted through **ox_inventory** (`CanCarryItem`, `AddItem`, `RemoveItem`)
- **Images** — shop UI and inventory icons from **Fivemanage** CDN links (`metadata.imageurl`)
- **City exclusives** — unique one-per-character vehicles, weapons, and access cards
- **Limited time** — server-enforced windows, stock counts, and countdown in the UI
- **Pets** — buy a companion ped, spawn / despawn it from ox_inventory
- **Rebel Coins** — stored per character identifier, granted from chat commands or the in-menu admin panel
- **Gifting** — buy an item for another player by server ID
- **Redeem codes** — admins can mint codes that grant coins and/or catalog items
- **Inventory + history** — owned items, 7-day spend chart, purchase log
- **Refunds** — admins can look up a player and refund a purchase
- **Discord logs** — purchases, coin grants, admin actions, and errors
- **Exports** — other resources (Tebex, VIP scripts) can grant coins

## Install

1. Drop this resource in `resources` as `dj-donator` (or keep the repo folder name and ensure it in `server.cfg`).
2. Import [`sql/install.sql`](sql/install.sql) into the same database oxmysql uses.
3. Add to `server.cfg`:

```cfg
ensure oxmysql
ensure ox_inventory
ensure jg-advancedgarages
ensure dj-donator

add_ace group.admin donator.admin allow
```

`jg-advancedgarages` is optional. If it is not started, vehicles still insert into ESX `owned_vehicles` or QB `player_vehicles`.

4. Open [`config.lua`](config.lua) and set:
   - `Config.Images.baseUrl` to your Fivemanage folder URL
   - `Config.JGGarages.defaultGarage` to a JG garage **name** (example: `legion`)
   - `Config.Webhooks` Discord URLs
5. Restart the server.

## Fivemanage images

Every catalog card and every ox_inventory grant can use a Fivemanage URL.

1. Upload images in the Fivemanage dashboard (vehicles, weapons, extras, pets).
2. Set the folder URL in `config.lua`:

```lua
Config.Images = {
    provider = 'fivemanage',
    baseUrl = 'https://r2.fivemanage.com/YOUR_TEAM_ID', -- no trailing slash
    extension = 'webp', -- or png
    urls = {
        -- optional per-key overrides
        -- sultan = 'https://r2.fivemanage.com/YOUR_TEAM_ID/sultan.webp',
    },
}
```

3. Name files after the spawn / ox item key:

| Kind | Example file |
|---|---|
| Vehicle | `sultan.webp` |
| Weapon | `weapon_pistol.webp` |
| Extra | `armour.webp`, `bandage.webp` |
| Pet | `pet_husky.webp` |
| Custom | `donator_plate.webp`, `penthouse_card.webp` |

You can also paste a full URL on any catalog row (`image = 'https://r2.fivemanage.com/...'`) or set `imageKey = 'armour'` when the listing id does not match the filename.

ox_inventory already allows `r2.fivemanage.com` and `i.fmfile.com` in `inventory:validhosts`. Grants set `metadata.imageurl` to the Fivemanage link so the item shows in inventory.

If `baseUrl` is empty, vehicles fall back to `docs.fivem.net` and items fall back to `nui://ox_inventory/web/images`.

## ox_inventory

This resource is linked to ox_inventory for **weight/slot checks**, **AddItem / RemoveItem**, and **usable pets**. Images come from Fivemanage first, then ox_inventory.

Put this above the donator resource:

```cfg
ensure oxmysql
ensure ox_inventory
ensure dj-donator
```

### Inventory actions

- Purchases call `CanCarryItem` before coins are taken
- Grants use `AddItem` (weapons include ammo metadata and `imageurl`)
- If AddItem fails, coins are refunded and any partial items are removed
- Admin refunds call `RemoveItem` for the same grants
- Pets are ox_inventory items (`pet_husky`, etc.). Using the item in inventory spawns or dismisses the pet

### Custom items

Merge [`install/ox_inventory_items.lua`](install/ox_inventory_items.lua) into `ox_inventory/data/items.lua`, then restart ox_inventory. That file registers:

- `donator_plate`, `penthouse_card`, `repairkit`
- Pet items with `client.export = 'dj-donator.usePet'`

Players open the store with **F7** or `/donator`. `/coins` prints the current Rebel Coin balance.

## JG Advanced Garages

When `jg-advancedgarages` is started, a purchased vehicle is **stored** (not spawned):

- QB / Qbox: `player_vehicles` with `in_garage = 1`, `garage_id` / `garage` = configured garage, `state = 1`
- ESX: `owned_vehicles` with `in_garage = 1`, `garage_id` = configured garage, `stored = 1`

The player takes it out from that JG garage. Helicopters (`garageType = 'heli'`, e.g. Buzzard) map to JG `air` and auto-select a public air garage unless you set `Config.JGGarages.defaultGarages.air`.

`Config.JGGarages.defaultGarage` must match a garage **name** from JG (`exports['jg-advancedgarages']:getAllGarages()`), not the map label. Default example is `legion`.

Leave `jg-advancedgarages` as a soft dependency. Do not rename that resource.

## Admin

Admins are anyone with ACE `donator.admin`, ESX groups `admin` / `superadmin`, or QB / Qbox `god` / `admin`.

| Command | What it does |
|---|---|
| `/givecoins [id] [amount] [reason]` | Add coins |
| `/removecoins [id] [amount] [reason]` | Remove coins |
| `/setcoins [id] [amount]` | Set an exact balance |
| `/checkcoins [id]` | Inspect a player (or yourself) |
| `/givecoinsid [identifier] [amount] [reason]` | Grant coins to an offline identifier |
| `/coins` | Show your own balance |

The **Admin** tab inside the store can do the same things, create redeem codes, inspect history, and refund purchases.

## Catalog

Edit [`shared/catalog.lua`](shared/catalog.lua). Each listing supports:

- `price`, `label`, `description`, `image`, `imageKey`
- `model` for vehicles
- `garageId` / `garageType` for JG (`car`, `heli` → `air`, `boat` → `sea`)
- `weapon` / `item` / `ammo` for weapons
- `extras = { { item = 'bandage', count = 10 } }` for ox_inventory grants
- `petModel` for companion peds
- `unique = true` to block duplicate ownership
- `stock = 25` for a global remaining count
- `limitedFrom` / `limitedUntil` as ISO UTC timestamps (`2026-09-15T23:59:59Z`)

## Discord webhooks

Set any of these in `config.lua`. Leave a field blank to skip that channel.

- `purchases` — buys and gifts
- `coins` — give / remove / set
- `admin` — codes, refunds, redeems
- `errors` — SQL / callback failures

## Exports

```lua
exports['dj-donator']:GetCoins(source)
exports['dj-donator']:AddCoins(source, amount, 'Tebex VIP')
exports['dj-donator']:AddCoinsIdentifier('license:abc', 500, 'Tebex VIP')
```

Use `AddCoinsIdentifier` from a Tebex command when the buyer may not be in-game.

## UI preview

The NUI also runs in a browser for theme checks. From `html/`:

```bash
python3 -m http.server 4173
```

Then open `http://127.0.0.1:4173`. Preview mode uses sample data and does not talk to FiveM. Set `FM_BASE` in `html/app.js` `mockCatalog()` if you want the preview to load your Fivemanage folder.

## Notes

- Unique city exclusives and pets are one per character.
- Limited listings vanish when the timestamp passes, even if they are still in the Lua file.
- Pending inventory grants (offline gifts) are applied the next time that player loads.
- Offline vehicle gifts still insert into JG / framework garages.
- If JG is not running and your garage columns differ from default ESX `owned_vehicles` or QB `player_vehicles`, adjust `Framework.GiveVehicle` in [`server/framework.lua`](server/framework.lua).
