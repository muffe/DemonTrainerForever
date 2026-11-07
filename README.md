# Demon Trainer

Warlock addon for WoW Forever. Shows which grimoires your demons can learn, at which level, and which they already know, without walking to the demon trainer.

## Features

- Grimoires grouped by level, with count and total cost per level, so you can tell whether a trainer visit is worth it.
- Learned grimoires are detected from your demon's spellbook. Summon each demon once.
- Grimoires in your bags show as "In bags".
- Succubus and Incubus are tracked separately.
- Click a demon icon to hide demons you don't use.
- Chat notice on login and level up when new grimoires are available.

Open the window with `/grim` or bind a key under Key Bindings → AddOns.

## Data

`Data.lua` is generated from the WoW Forever client data on [wago.tools](https://wago.tools). After a game patch:

```sh
python3 tools/generate_data.py
```

Without arguments the script uses the latest Forever build. Pass a build number (e.g. `1.60.1.70862`) to pin one.

## Tests

The tests run the addon against stubbed WoW APIs with Lua 5.1:

```sh
lua5.1 tests/run.lua
```

## Thanks

Grimoire data was originally cross-checked against [What's Training?](https://github.com/fusionpit/WhatsTraining).

## License

MIT
