# Rebel Donator (`dj-donator`)

FiveM donator store with a **Rebel Coins** currency, a red / white / black dashboard UI, oxmysql persistence, and Discord webhook logs for every purchase and admin action.

Open with **F7** or `/donator`.

## Features

- **Vehicles** — bronze, silver, and gold tiers, delivered to ESX / QB / Qbox garages (or spawned in standalone)
- **Weapons** — bronze, silver, and gold tiers via ox_inventory, qb-inventory, ESX, or native give
- **Extra items** — armor, meds, lockpicks, ammo crates, starter pack
- **City exclusives** — unique one-per-character vehicles, weapons, and access cards
- **Limited time** — server-enforced windows, stock counts, and countdown in the UI
- **Pets** — buy a companion ped, spawn / despawn it from Inventory
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
ensure dj-donator

add_ace group.admin donator.admin allow
```

4. Open [`config.lua`](config.lua) and set:
   - `Config.Webhooks` Discord URLs
   - `Config.Framework` / `Config.Inventory` (`auto` is fine on ESX, QBCore, Qbox, ox_inventory)
   - Extra item names so they match your inventory items
5. Restart the server.

Players open the store with **F7** or `/donator`. `/coins` prints the current Rebel Coin balance.

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

- `price`, `label`, `description`, `image`
- `model` for vehicles
- `weapon` / `item` / `ammo` for weapons
- `extras = { { item = 'bandage', count = 10 } }` for inventory grants
- `petModel` for companion peds
- `unique = true` to block duplicate ownership
- `stock = 25` for a global remaining count
- `limitedFrom` / `limitedUntil` as ISO UTC timestamps (`2026-09-15T23:59:59Z`)

Vehicle images default to `https://docs.fivem.net/vehicles/<model>.webp`.

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

Then open `http://127.0.0.1:4173`. Preview mode uses sample data and does not talk to FiveM.

## Notes

- Unique city exclusives and pets are one per character.
- Limited listings vanish when the timestamp passes, even if they are still in the Lua file.
- Pending inventory grants (offline gifts) are applied the next time that player loads.
- If your garage columns differ from default ESX `owned_vehicles` or QB `player_vehicles`, adjust `Framework.GiveVehicle` in [`server/framework.lua`](server/framework.lua).
