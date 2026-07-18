# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal "dumping ground" of miscellaneous 3D-printable models, each authored as an [OpenSCAD](https://openscad.org/) script using the [BOSL2](https://github.com/BelfrySCAD/BOSL2) library. Every `*.scad` at the repo root is an independent, self-contained model — there are no shared local libraries between them (BOSL2 is the only shared dependency). Units are millimeters throughout.

## Setup

BOSL2 is vendored as a git submodule at `BOSL2/`. After cloning:

```
git submodule update --init
```

The `Makefile`'s `init` target does this plus wires up the Git LFS filter (`git config --local include.path ../.gitconfig`). STL/3MF/ZIP outputs are stored via **Git LFS** (see `.gitattributes`) — the `.gitconfig` in-repo defines the LFS filter.

## Building models (STL export)

Export geometry is declarative, driven by `//@make` comment directives embedded in each `.scad` file. A directive is the literal argument list passed to the `openscad` CLI:

```
//@make -o handle.stl -D mode=1
//@make -o ring_sizer/us_7.stl -p ring_sizer.json -P us_7
```

The `Makefile` greps these out of a single target file and renders each output:

```
make SCAD=handle.scad          # build all //@make outputs declared in handle.scad
make clean SCAD=handle.scad    # remove them
```

`SCAD` defaults to `handle.scad`; override it to build a different model. The Makefile is single-file-scoped (its top comment notes "TODO generalize past 1 file"); `ring_sizer.mk` is a parallel copy pinned to `ring_sizer.scad` (`make -f ring_sizer.mk`). To render ad hoc without make, run the directive directly: `openscad handle.scad -o handle.stl -D mode=1`.

## Model file conventions

Follow the structure of existing files (`handle.scad`, `kurtis_foot.scad` are good exemplars):

- **Includes first:** `include <BOSL2/std.scad>;` plus any needed BOSL2 modules (`screws.scad`, etc.).
- **OpenSCAD Customizer sections:** parameters are grouped under `/* [Section Name] */` banners, and each parameter is preceded by a `//` doc comment that becomes its Customizer label. Inline `// [0:Assembly, 1:Handle, ...]` sets Customizer dropdown/range options.
- **Part selection via `mode`:** multi-part models expose a top-level `mode` parameter and dispatch with an `if (mode == 0) {...} else if (mode == 1) {...}` chain at file bottom (assembly = 0; individual printable parts and test/cross-section modes get higher numbers). Each printable mode is paired with a `//@make -o NAME.stl -D mode=N` directive immediately above its branch.
- **Common tuning params** recur across files: geometry detail (`$fa`, `$fs`, `$eps` nudge for differencing), and fitment (`tolerance`, `feature` ≈ nozzle width, `chamfer`, `rounding`).
- Preview-only helpers (screws, cutaways gated on `$preview`) must not affect exported geometry.

## Commits

Commit messages use a `topic: summary` prefix keyed to the model/family being worked (e.g. `handle: ...`, `kurtis_foot: ...`, `flex_itx: ...`). Work is organized in per-topic bursts.
