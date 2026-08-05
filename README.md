# Lightweight-DependencyLoader-ROBLOX-LUAU
## ModuleLoader

A lightweight, dependency-aware module loader for Roblox (Luau). It requires your service/controller ModuleScripts, resolves load order based on declared dependencies, instantiates them, and initializes them — with automatic retries and fail-fast behavior if a core module can't come up.

## Why

Most "service loader" patterns either load everything in folder order (breaking if `B` depends on `A` but loads first) or require you to manually order your `require()` calls. This loader:

- Resolves dependency order automatically via topological sort
- Detects circular dependencies and fails loudly instead of hanging or crashing silently
- Retries failed instantiation/initialization with exponential backoff (in case of transient startup issues)
- Fails the entire load if any core module can't be created or initialized — no silent partial state

## How it works

The loader runs in four phases:

1. **Require** — `ModuleLoader.Require(folder)` walks the direct children of a folder, requires each `ModuleScript`, and validates it returns a table with a `.new` function.
2. **Order** — `SetOrder` performs a depth-first topological sort based on each module's `Dependencies` list, so dependencies always come before dependents.
3. **Create** — `CreateClasses` calls `Module.new(ContextTable)` for each module in order, skipping/retrying on failure.
4. **Initialize** — `InitializeModules` calls `Module:Init()` on each created instance, in the same dependency order.

`ModuleLoader.Load(ContextTable, RequiredModules)` runs all four phases and returns `(Container, success)`.

## Folder structure

Modules must be **direct children** of the folder you pass in (subfolders are not traversed):

```
ServerServices/
├── DataService.lua
├── EconomyService.lua
└── CombatService.lua
```

## Writing a module

Every module must return a table with a `.new` constructor. `Init` and `Dependencies` are optional:

```luau
-- EconomyService.lua
local EconomyService = {}
EconomyService.__index = EconomyService

EconomyService.Dependencies = { "DataService" } -- names, or direct ModuleScript references

function EconomyService.new(ContextTable)
    local self = setmetatable({}, EconomyService)
    self.Context = ContextTable
    return self
end

function EconomyService:Init()
    -- runs after all dependencies are created AND initialized
end

return EconomyService
```

`Dependencies` can mix strings (module names) and direct `ModuleScript` references — both are resolved to the same thing internally.

## Usage

```luau
local ModuleLoader = require(ReplicatedStorage.Shared.ModuleLoader)

local RequiredModules = ModuleLoader.Require(ServerScriptService.Services)
if not RequiredModules then
    -- one or more modules failed to require; check output for warnings
    return
end

local Container, success = ModuleLoader.Load(ContextTable, RequiredModules)
if not success then
    -- one or more modules failed to create/initialize
    -- Container may be partially populated; treat the whole boot as failed
    return
end

-- Container[ModuleName] now holds live instances
```

## Design decisions (read before "fixing" these)

These are intentional, not bugs:

- **Fail-fast, not partial-load.** If any module fails to build or initialize, `Load` returns `success = false` and the framework does not attempt to skip just the broken module and continue with the rest. The assumption is that a core service failing means the game shouldn't boot in a half-working state. If you want partial-load tolerance, you'll need to change `CreateClasses`/`InitializeModules` to `continue` instead of `return false` on dependency-check failures.
- **Retries use exponential backoff** (`task.wait(i ^ 2)`, 3 attempts → up to ~14s total per module) for both `.new()` and `:Init()`. This assumes failures are transient (e.g. waiting on an external resource). If a module has a genuine bug, boot time will be slower before the loader gives up — this is expected, not a hang.
- **Only direct children are required** — no recursive folder scanning. Keep your services/controllers flat, or extend `RequireServices` to use `GetDescendants()` if you need nesting.
- **Circular dependencies and missing modules throw `error()`** inside `SetOrder`, but are caught via `pcall` at the call site in `LoadModules`, so they surface as a normal `warn` + `return false` rather than crashing the calling script.

## API reference

| Function | Description |
|---|---|
| `ModuleLoader.Require(folder: Folder)` | Requires all ModuleScripts directly under `folder`. Returns a table of `{[Name] = Module}` or `false` on failure. |
| `ModuleLoader.Load(ContextTable, RequiredModules)` | Runs order/create/init phases. Returns `(Container, success)`. |
| `ModuleLoader.LoadModules(ContextTable, RequiredModules, ContainerOfModules)` | Lower-level entry point used internally by `Load`. |
| `ModuleLoader.SetOrder(LoaderOptions, ModuleName, Modulescripts)` | Recursively resolves topological order for a single module. |
| `ModuleLoader.CreateClasses(ContextTable, LoaderOptions, RequiredModules, Container)` | Instantiates modules in order via `.new()`. |
| `ModuleLoader.InitializeModules(LoaderOptions, RequiredModules, Container)` | Calls `:Init()` on created modules in order. |
| `ModuleLoader.Heartbeat(Services, Key?)` | **Optional.** Connects `RunService.Heartbeat` and calls `Heartbeat`/`heartbeat` (`DeltaTime`) on every module in `Services` that has one. Must be called manually, outside of `Load`. |
| `ModuleLoader.Stepped(Services, Key?)` | **Optional.** Connects `RunService.Stepped` and calls `Stepped`/`stepped` (`Time`, `DeltaTime`) on every module in `Services` that has one. Fires before physics simulation. Must be called manually, outside of `Load`. |
| `ModuleLoader.RenderStepped(Services, Key?)` | **Optional, client-only.** Connects `RunService.RenderStepped` and calls `RenderStepped`/`renderstepped` (`DeltaTime`) on every module in `Services` that has one. Must be called manually, outside of `Load`. |
| `ModuleLoader.PreRender(Services, Key?)` | **Optional, client-only.** Connects `RunService.PreRender` and calls `PreRender`/`prerender` (`DeltaTime`) on every module in `Services` that has one. Must be called manually, outside of `Load`. |
| `ModuleLoader.Remove(Key)` | Removes every entry tagged with `Key` from all four event containers. Call this from `PlayerRemoving` (or your equivalent per-key teardown) to stop calling into modules that no longer exist. |

## Optional: per-frame updates (`Heartbeat` / `Stepped` / `RenderStepped` / `PreRender`)

`ModuleLoader.Heartbeat`, `ModuleLoader.Stepped`, `ModuleLoader.RenderStepped`, and `ModuleLoader.PreRender` are **completely optional** — the loader works fine without them, and `Load`/`LoadModules` never call these automatically. If you want a module to run logic every frame, you have to opt in explicitly, after loading:

```luau
local Container, success = ModuleLoader.Load(ContextTable, RequiredModules)
if not success then
    return
end

ModuleLoader.Heartbeat(Container) -- server/client: runs every physics step, after simulation
ModuleLoader.Stepped(Container) -- server/client: runs every physics step, before simulation
-- or, client-side:
ModuleLoader.RenderStepped(Container) -- runs every rendered frame, after camera update
ModuleLoader.PreRender(Container) -- runs every rendered frame, before camera update
```

**Important:** none of these are part of the `Load`/`LoadModules` pipeline — you must call `ModuleLoader.Heartbeat(Container)`, `ModuleLoader.Stepped(Container)`, `ModuleLoader.RenderStepped(Container)`, and/or `ModuleLoader.PreRender(Container)` yourself, after `Load` succeeds, passing it the `Container` you got back. A module can be registered to more than one event at once if it needs to run logic on multiple ticks.

### Each event calls its own matching method name — not a shared `Update`

Each of the four functions above looks for a method on the module **named after that specific event** (in either casing), not a generic `Update`. This is deliberate: if a single module were registered to both `Heartbeat` and `RenderStepped` and both looked for the same `Update` method, there'd be no way for the module to tell which event actually fired, or to run different logic per event.

So define exactly the method(s) matching whichever event(s) you register the module for:

```luau
-- ExampleService.lua
local ExampleService = {}
ExampleService.__index = ExampleService

function ExampleService.new(ContextTable)
    local self = setmetatable({}, ExampleService)
    return self
end

function ExampleService.Heartbeat(DeltaTime)
    -- only runs if this module was registered via ModuleLoader.Heartbeat(...)
end

function ExampleService.RenderStepped(DeltaTime)
    -- only runs if this module was registered via ModuleLoader.RenderStepped(...)
    -- can coexist with Heartbeat above without colliding
end

return ExampleService
```

Method names, matched per event (either casing works for each):

| Event | Method names checked |
|---|---|
| `Heartbeat` | `Heartbeat` or `heartbeat` |
| `Stepped` | `Stepped` or `stepped` |
| `RenderStepped` | `RenderStepped` or `renderstepped` |
| `PreRender` | `PreRender` or `prerender` |

As with `Update` before, these must be plain functions on the module itself, not methods called through `:` (define as `function Class.Heartbeat(DeltaTime)`, not `function Class:Heartbeat(DeltaTime)`).

Modules with no matching method for a given event are simply skipped for that event — nothing breaks, they're just not included in that event's per-frame loop. `Heartbeat` and `Stepped` fire on both server and client; `RenderStepped` and `PreRender` only fire on the client, so only register those from client-side code.

### The `Key` parameter and `ModuleLoader.Remove`

Every registration function takes an optional second argument, `Key: string | Player | number`, used to tag the modules you're registering so they can be removed later:

```luau
ModuleLoader.Heartbeat(PlayerContainer, player) -- tag every module in this call with `player`

Players.PlayerRemoving:Connect(function(leavingPlayer)
    ModuleLoader.Remove(leavingPlayer) -- untags and removes every entry registered with this key, across all four events
end)
```

Leave `Key` as `nil` for anything that should live for the server's entire lifetime (e.g. server-only services loaded once at startup) — untagged entries are never touched by `Remove`. This is what makes it safe to call `ModuleLoader.Heartbeat(...)` once per player join without leaking connections or growing the per-frame loop forever: each call only ever creates the underlying `RunService` connection once per event (subsequent calls just append into the existing loop), and `Remove(Key)` is how you clean up a specific player's (or any other keyed owner's) entries when they're no longer needed.

### Getting autocomplete for `Heartbeat` / `Stepped` / `RenderStepped` / `PreRender`

If the lowercase aliases (`heartbeat`, `stepped`, `renderstepped`, `prerender`) are assigned dynamically (e.g. via a loop or metatable) rather than as explicit fields, Luau's static analysis won't be able to infer them, and they won't show up in autocomplete. To fix that, declare an explicit type for the module and cast the return value to it at the bottom of `ModuleLoader.luau`:

```luau
export type ModuleLoaderType = {
    Require: (folder: Folder) -> (requiredmodules | boolean),
    Load: (ContextTable: ContextTable, RequiredModules: { [string]: any }) -> (Classmodules, boolean),

    Heartbeat: (Container: Classmodules) -> (),
    heartbeat: (Container: Classmodules) -> (),

    Stepped: (Container: Classmodules) -> (),
    stepped: (Container: Classmodules) -> (),

    RenderStepped: (Container: Classmodules) -> (),
    renderstepped: (Container: Classmodules) -> (),

    PreRender: (Container: Classmodules) -> (),
    prerender: (Container: Classmodules) -> (),
}

-- at the very bottom of the file:
return ModuleLoader :: ModuleLoaderType
```

This gives you autocomplete and hover documentation for all eight variants (both casings of all four events) in Roblox Studio's script editor and in VS Code via the Luau LSP extension, regardless of how the aliases are actually implemented internally.

## Third-party dependencies

**Note:** `ModuleLoader` itself has no dependency on ProfileService or GoodSignal — it doesn't require or reference either package anywhere in its own code. This repo is organized as two separate things: the loader script itself (`ModuleLoader.luau`), and all the other scripts/services in the repo that happen to use ProfileService and GoodSignal internally. The loader will work fine on its own with zero third-party packages installed; it's only the *other* scripts in this repo that need them.

This repo does **not** bundle ProfileService or GoodSignal — see [`CREDITS.md`](./CREDITS.md) for license/attribution details. Both packages are also used directly inside other scripts throughout this repo (not just in the examples below), so make sure they're installed before trying to run or sync the project — otherwise those scripts will fail to `require()` them. Below is how to get and use each one.

### Option A — Wally (recommended)

If you don't already have Wally installed, the easiest way is through a toolchain manager — either [Aftman](https://github.com/LPGhatguy/aftman) or its successor [Rokit](https://github.com/rojo-rbx/rokit) both work:

**Using Rokit:**
```
rokit add UpliftGames/wally
```

**Using Aftman:**
```
aftman add UpliftGames/wally
```

Either one reads/writes an `aftman.toml` or `rokit.toml` in your project root pinning the exact Wally version, so anyone else who clones the repo and runs `rokit install` / `aftman install` gets the same toolchain automatically — no separate manual Wally install needed.

Once Wally is available, the `wally.toml` in this repo already lists both packages. From the repo root:

```
wally install
```

This downloads both into a local `Packages/` folder (git-ignored, not committed). In your Rojo project, sync `Packages/` into `ReplicatedStorage` (or wherever your project file points it) as usual, then:

```luau
local ProfileService = require(Packages.profileservice)
local GoodSignal = require(Packages.goodsignal)
```

### Option B — Manual / instant install

If you're not using Wally, grab the modules directly from the original authors and drop them into your own `Packages` (or equivalent) folder:

- **ProfileService** — https://github.com/MadStudioRoblox/ProfileService (also available as a Roblox model, linked from that repo)
- **GoodSignal** — https://github.com/stravant/goodsignal

Either way, treat these as external, third-party code — don't modify the source files directly if you can avoid it, so you can update them cleanly later.

### Step-by-step: using ProfileService in a module loaded by this loader

```luau
-- DataService.lua
local ProfileService = require(Packages.profileservice)

local DataService = {}
DataService.__index = DataService

local ProfileStore = ProfileService.GetProfileStore("PlayerData", {
    Coins = 0,
})

function DataService.new(ContextTable)
    local self = setmetatable({}, DataService)
    self.Profiles = {}
    self.Context = ContextTable
    return self
end

function DataService:Init()
    game.Players.PlayerAdded:Connect(function(player)
        local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
        if not profile then
            player:Kick("Data failed to load, please rejoin.")
            return
        end

        profile:AddUserId(player.UserId)
        profile:Reconcile()
        profile:ListenToRelease(function()
            self.Profiles[player] = nil
        end)

        if player.Parent then
            self.Profiles[player] = profile
        else
            profile:Release()
        end
    end)
end

return DataService
```

1. Install ProfileService (Option A or B above).
2. Require it at the top of whichever service owns player data (commonly `DataService`).
3. Call `ProfileService.GetProfileStore(storeName, template)` once, outside of any function, to define your data template.
4. Load a profile per player inside `PlayerAdded`, following ProfileService's session-locking pattern (see their docs for `Reconcile`, `ListenToRelease`, etc. in full detail).
5. Add `"DataService"` to any other module's `Dependencies` if it needs to read/write player data — that guarantees `DataService` is created and initialized first.

### Step-by-step: using GoodSignal in a module loaded by this loader

```luau
-- EconomyService.lua
local GoodSignal = require(Packages.goodsignal)

local EconomyService = {}
EconomyService.__index = EconomyService

EconomyService.Dependencies = { "DataService" }

function EconomyService.new(ContextTable)
    local self = setmetatable({}, EconomyService)
    self.Context = ContextTable
    self.CoinsChanged = GoodSignal.new()
    return self
end

function EconomyService:Init()
    -- fire the signal whenever coins change
end

function EconomyService:AddCoins(player, amount)
    -- update data here, then:
    self.CoinsChanged:Fire(player, amount)
end

return EconomyService
```

1. Install GoodSignal (Option A or B above).
2. Require it in whichever module needs custom events (not tied to an Instance).
3. Create a signal with `GoodSignal.new()`, typically stored on `self` inside `.new()`.
4. Fire it with `:Fire(...)` wherever the relevant event happens.
5. Anywhere else you have access to the module instance, connect to it with `:Connect(function(...) ... end)`, same API shape as `RBXScriptSignal`.

## Contributing / forking

You're welcome to fork, modify, and improve this. See [`LICENSE`](./LICENSE) for terms, and [`CREDITS.md`](./CREDITS.md) for third-party attributions.
