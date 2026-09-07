# Reusable UI Components for Godot

*Reusable, composition-first UI pieces for Godot — built to be combined with each other and with vanilla nodes.*

## Overview

**Reusable UI Components** is a collection of generic, framework-agnostic UI components and base classes for Godot 4, built around composition rather than inheritance-heavy customization.

Each component solves one focused problem and is designed to be dropped into any project and combined with the others and with vanilla Godot nodes.

The addon ships with a runnable demo for every component, so you can see exactly how each one behaves and how it's wired up before using it in your own project.

## Features

### Reusable components
Plug-and-play nodes/scripts — attach them and configure their exported properties, no subclassing required.

- **`IconValueDisplay`** — Displays an icon plus a numeric value, with support for custom string formatting (e.g. currency, counters).
- **`Node2DWrapper`** — Wraps a `Node2D` (and its children) so it can be used as a `Control`, e.g. inside `Container`s or as button visuals.
- **`ScaleWrapper`** — Lets a child `Control` scale itself freely without its parent `Container` overriding that scale.
- **`SlotWheel`** — A slot-machine-style wheel that scrolls through a looping list of items and spins to land on a chosen one, with pausable/resumable/serializable spin state.
- **`StatefulButton`** — A visual-less button (`BaseButton`) that tracks and exposes its interaction state (`NORMAL`, `HOVER`, `PRESSED`, `DISABLED`), useful for composing buttons whose visuals go beyond what `Button` supports.
- **`TextureRepeater`** — Instantiates a configurable number of identical `TextureRect` nodes, useful for grids/slots/tiled backgrounds.

### Base classes / framework primitives
Intended to be subclassed to fit your own data and visuals; they provide the lifecycle/contract, not a finished look.

- **`ListDisplay`** (`@abstract`) — Displays a dynamic list of `Control` nodes bound to arbitrary data, with support for adding, updating, removing, sorting and batch-loading elements efficiently. Subclass it and implement `_create_node`, `_update_node` and `_get_id`.
- **`ToggleableDisplay`** — Base class for dismissable UI displays (dialogs, menus, popups) managed by external systems or local scene logic. Provides shared request signals, input hooks, and input-blocking behavior while remaining agnostic to how the display is actually shown/hidden or mounted/unmounted.

## Requirements

- Godot **4.7** or later is recommended. It may work on older versions, but I haven't tested it.
- No external dependencies or plugins.

## Installation

### Via the Godot Asset Library (recommended)
1. In the Godot editor, open the **AssetLib** tab.
2. Search for **"Reusable UI Components"**.
3. Click **Download**, then **Install** — only the `addons/reusable-ui-components/` folder will be added to your project.

### Manual installation
1. Download or clone this repository.
2. Copy the `addons/reusable-ui-components/` folder into your own project's `addons/` folder.
3. (Optional) Enable it as a plugin under **Project > Project Settings > Plugins** if you want it listed there — none of the components require the plugin to be enabled to work, since they're plain `class_name` scripts/scenes.

## Demos

Every component has a corresponding demo scene under `demos/`, each runnable individually (F6) to see the component in action:

| Demo | Showcases |
|---|---|
| `demos/icon_value_display/` | `IconValueDisplay` bound to a live value |
| `demos/inventory/` | `ListDisplay` subclassed into an `ItemListDisplay`, plus `TextureRepeater` |
| `demos/node_2d_wrapper/` | `Node2DWrapper` embedding a `Node2D` scene inside a `Control` layout |
| `demos/scale_wrapper/` | `ScaleWrapper` letting a child `Control` scale independently of its container |
| `demos/slot_wheel/` | `SlotWheel` spinning, pausing and resuming; embedded in a slot machine |
| `demos/stateful_button/` | `StatefulButton` composed with a `Node2DWrapper`-wrapped sprite to build a custom animated button |
| `demos/toggleable_display/` | `ToggleableDisplay` subclassed into a `ConfirmationDialog` and a `PauseMenu` |

Clone the repository and open the project in Godot to explore them all.

## AI Disclosure

This project was developed with the assistance of AI tools.
The majority of the code was written by hand; AI was used for code review, help with architecture and design decisions, and to assist with writing documentation.

Everything in this repository has been reviewed and is maintained by the author.

## License

Distributed under the MIT License — see [`LICENSE`](LICENSE) for details.
