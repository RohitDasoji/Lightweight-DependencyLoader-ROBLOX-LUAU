# Credits / Third-Party Software

This repository (`rohitdasoji/Dependencyloader`) does **not** include or bundle the following third-party packages. They are external dependencies that must be installed separately via [Wally](https://wally.run/) (using the `wally.toml` in this repo) before the code will run. Each remains under its own original author's license — none of this is covered by this repository's own `LICENSE`.

---

### ProfileService
- **Origin author:** loleris (MadStudioRoblox)
- **Origin repo:** https://github.com/MadStudioRoblox/ProfileService
- **Wally package used here:** `brittonfischer/profileservice@2.1.5`
- **License:** MIT
- **Purpose:** DataStore session-locking and player profile management.
- **Not included** — install via `wally install`.

### GoodSignal
- **Origin author:** Mark Langen (stravant)
- **Origin repo:** https://github.com/stravant/goodsignal
- **Wally package used here:** `ddust1n/goodsignal@0.3.2`
- **License:** MIT
- **Purpose:** Fast custom Signal implementation with `RBXScriptSignal`-like API.
- **Not included** — install via `wally install`.

---

## Setup

Run the following in the repo root before syncing into Studio:

```
wally install
```

This pulls both packages above (and any others in `wally.toml`) into a local `Packages/` folder, which is git-ignored and not part of this repository.

---

Note: the Wally scopes above (`brittonfischer`, `ddust1n`) are the accounts these specific package versions were published under on the Wally registry, which may differ from the original author's repo — this is normal for Wally, where packages are sometimes re-published or mirrored under a different scope. Credit above goes to the original authors linked.

If you fork this repo, keep this file (or equivalent credit) alongside any redistribution that still includes these packages, per their MIT license terms (attribution + license text must be preserved).
