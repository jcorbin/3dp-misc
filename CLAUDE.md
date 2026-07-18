# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal "dumping ground" of miscellaneous 3D-printable models (per `README.md`), each authored as an [OpenSCAD](https://openscad.org/) script using the [BOSL2](https://github.com/BelfrySCAD/BOSL2) library. Units are millimeters throughout. Licensed CC BY-SA 4.0.

Models come in two shapes:

- **Root-level `*.scad`** — one model (or model family) per file, self-contained apart from the shared dependencies below.
- **Subdirectory projects** — `<name>/model.scad` (e.g. `cup_cap/`, `knee_rod_case/`, `riser_stand/`), which use `include <../BOSL2/std.scad>` and often carry a free-form `notes.md` of measurements plus reference photos. Some subdirs (`a11y/`, `screwfinity/`, `pluslife_kit/`) hold only third-party/remixed binaries.

Shared local dependencies (the "no shared libraries" rule has exceptions — check before assuming a file is standalone):

- **`grid2.scad`** — a real local library: Gridfinity base/foot/stack/platform primitives, pulled in with `use <grid2.scad>` by `airpods_grid`, `airpods_riser`, `ctl_holder`, `mantis_clamp_holder`, `phone_mount`, `watch_mount`. Changing it affects all six.
- **`fonts/`** and `noto-emoji-2.051/` — `use <...ttf>` assets for `plant_marker.scad` and `craft_eye.scad`.

Built outputs (`.stl`, `.3mf`, `.zip`) are **committed alongside their source**, stored via Git LFS. `.gitignore` is empty, so a stray render shows up in `git status` — don't commit renders that aren't intended artifacts.

## Setup

BOSL2 is vendored as a git submodule at `BOSL2/`. After cloning:

```
git submodule update --init
git config --local include.path ../.gitconfig    # wires up the Git LFS filter
```

`make init` does both. The in-repo `.gitconfig` defines the LFS filter; `.gitattributes` marks `*.stl`, `*.3mf`, `*.zip` as LFS.

## Building models (STL export)

Export geometry is declarative, driven by `//@make` comment directives embedded in the `.scad` file. A directive is the literal argument list passed to the `openscad` CLI:

```
//@make -o handle.stl -D mode=1
//@make -o ring_sizer/us_7.stl -p ring_sizer.json -P us_7
```

The `Makefile` greps these out of a single target file and renders each output:

```
make SCAD=handle.scad          # build all //@make outputs declared in handle.scad
make clean SCAD=handle.scad    # remove them
```

`SCAD` defaults to `handle.scad`; override it to build a different model. The Makefile is single-file-scoped (its top comment notes "TODO generalize past 1 file"); `ring_sizer.mk` is a parallel copy pinned to `ring_sizer.scad` (`make -f ring_sizer.mk`).

**Only `handle.scad` and `ring_sizer.scad` currently carry `//@make` directives.** Every other committed `.stl`/`.3mf` was exported by hand (GUI or ad-hoc CLI). Adding directives to a file you're working on is an improvement, not a required convention — but don't assume `make SCAD=foo.scad` will do anything for an arbitrary `foo`.

Ad hoc render / does-it-still-compile check (no test suite exists; rendering *is* the check):

```
openscad handle.scad -o handle.stl -D mode=1
openscad --hardwarnings --export-format binstl -o /dev/null kurtis_foot.scad   # smoke test
```

Includes resolve relative to the `.scad` file's own directory, so these run from anywhere. `-o` needs an explicit `--export-format` when the target has no recognized suffix (e.g. `/dev/null`).

Because outputs are committed, `make SCAD=handle.scad` is normally a no-op — the `.stl` is already newer than the source. Use `make -Bn SCAD=handle.scad` to see the commands, and remember a real `make` **overwrites the committed LFS artifacts**; render to a scratch path instead unless you intend to update them.

## Model file conventions

`handle.scad` is the richest exemplar (mode dispatch, presets, preview assembly); `kurtis_foot.scad` is a minimal single-part one.

- **Includes first:** `include <BOSL2/std.scad>;` plus any needed BOSL2 modules (`rounding.scad`, `screws.scad`, `walls.scad`, `threading.scad`, `structs.scad`).
- **OpenSCAD Customizer sections:** parameters grouped under `/* [Section Name] */` banners, each preceded by a `//` doc comment that becomes its Customizer label. Inline `// [0:Assembly, 1:Handle, ...]` sets dropdown/range options. Recurring sections: `[Geometry Detail]`, `[Fitment and Quality]`, `[Part-iculars]`.
- **`module __customizer_limit__() {}`** is a sentinel: parameters above it are Customizer-visible, everything below is implementation. Most non-trivial files use it — put new tunables above, derived values and geometry below.
- **Common tuning params** recur across files: `$fa`/`$fs` (fragment detail), `$eps` (nudge to avoid coincident-face flicker when differencing), and fitment (`tolerance`, `feature` ≈ nozzle width, `chamfer`, `rounding`). These are OpenSCAD special variables, so they propagate into called modules — set them once at file top.
- **Part selection via `mode`:** multi-part models expose a top-level `mode` parameter and dispatch with an `if (mode == 0) {...} else if (mode == 1) {...}` chain at file bottom. Convention: `0` = preview assembly, `1..n` = individual printable parts, `100+` = cross-sections, outline paths, and fit-test coupons. Each printable mode gets a `//@make -o NAME.stl -D mode=N` directive immediately above its branch.
- **Customizer preset JSON** (`ring_sizer.json`, `crail.json`) holds `parameterSets` used via `-p FILE -P PRESET` — the mechanism for parameter-swept families (sizes, fan dimensions) rather than a `mode` chain.
- **BOSL2 attachment idiom, not raw CSG:** geometry is composed with `diff()` + `tag("remove")`/`tag("keep")`, `attach(FROM, TO, overlap=...)`, `position()`, `zrot_copies()`/`grid_copies()`, and custom `attachable()` modules exposing **named anchors** (e.g. `attach(["left_nut", "right_nut"], CENTER)`). New modules should take `anchor`/`spin`/`orient` and wrap their geometry in `attachable()` so they compose. `handle.scad` ends with a commented "module dev assist" scaffold (`show_anchors()`, `$parent_size` cube) worth copying when building a new attachable.
- **`struct_val`/`struct_set` info records:** larger models (`grid2.scad`, `handle.scad`, `trinket.scad`) factor derived dimensions into a function returning a BOSL2 struct, so geometry modules read values instead of recomputing them. Follow that when a model grows past a handful of coupled dimensions.
- Preview-only helpers (screws, nuts, explode offsets, cutaways gated on `$preview`) must not affect exported geometry.

## Commits

Commit messages use a `topic: summary` prefix keyed to the model/family being worked (e.g. `handle: ...`, `kurtis_foot: ...`, `flex_itx: ...`, `a11y: ...`). Work is organized in per-topic bursts. `WIP ...` prefixes mark in-progress commits. Print-verified milestones sometimes get a `SUCH <thing> in situ` message.
