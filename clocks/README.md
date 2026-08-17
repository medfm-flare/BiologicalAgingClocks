# Vendored clock implementations

See [`../clocks_table.md`](../clocks_table.md) for the full catalog, citations,
and which clocks still have no located public implementation at all.

**This directory is Python-only.** Every folder here vendors a Python
implementation. Clocks with no known Python implementation are not part of
this catalog and are not listed here or in `clocks_table.md`.

## Structure

Not every clock has its own dedicated upstream repo — some are commonly
computed via shared multi-clock packages. To reflect that honestly instead of
duplicating the same package under multiple folders, this repo uses two kinds
of entries:

- **Standalone folders** — a direct copy of a clock's own dedicated repo
  (e.g. `organage/`, `cpgpt/`, `delphi2m/`).
- **Pointer folders** — a thin `README.md` with usage instructions, for
  clocks implemented inside a shared package vendored elsewhere
  (e.g. `horvath/`, `hannum/`, `grimage/`, `dunedinpace/`).

Every standalone/shared package folder has a `SOURCE.md` recording the exact
upstream commit and date it was vendored, since git history is stripped on
import (direct copy, not submodules).

## Shared multi-clock packages

One package covers the great majority of epigenetic clocks in this repo:

| Package | Covers |
|---|---|
| [`biolearn/`](biolearn/) | Horvath, Horvath2, Hannum, PhenoAge, GrimAge, GrimAge2, DunedinPACE, DunedinPoAm38, DNAmTL, Zhang10, YingAdaptAge, YingDamAge, YingCausAge, and more |

## Full clock index

| Clock | Folder | Type |
|---|---|---|
| Horvath | [`horvath/`](horvath/) | pointer → `biolearn/` |
| Horvath2 | [`horvath2/`](horvath2/) | pointer → `biolearn/` |
| Hannum | [`hannum/`](hannum/) | pointer → `biolearn/` |
| Zhang10 | [`zhang10/`](zhang10/) | pointer → `biolearn/` |
| PhenoAge | [`phenoage/`](phenoage/) | pointer → `biolearn/` |
| GrimAge (v1) | [`grimage/`](grimage/) | pointer → `biolearn/` (coefficients proprietary, see note) |
| GrimAge2 | [`grimage2/`](grimage2/) | pointer → `biolearn/` (coefficients proprietary, see note) |
| DunedinPACE | [`dunedinpace/`](dunedinpace/) | pointer → `biolearn/` |
| DunedinPoAm | [`dunedinpoam/`](dunedinpoam/) | pointer → `biolearn/` (as `DunedinPoAm38`) |
| AdaptAge / DamAge | [`adaptage-damage/`](adaptage-damage/) | pointer → `biolearn/` |
| DNAmTL | [`dnamtl/`](dnamtl/) | pointer → `biolearn/` |
| PathwayAge | [`pathwayage/`](pathwayage/) | standalone |
| CpGPT | [`cpgpt/`](cpgpt/) | standalone (weights likely external) |
| LifeClock | [`lifeclock/`](lifeclock/) | standalone |
| "Conventional" + organ clocks (Oh et al.) | [`organage/`](organage/) | standalone |
| Organ clocks (analysis code, Argentieri) | [`proteomic-age-ukb/`](proteomic-age-ukb/) | standalone (analysis code only, no runnable weights) |
| ClockBase | [`clockbase/`](clockbase/) | standalone (large agentic-AI system) |
| Delphi-2M | [`delphi2m/`](delphi2m/) | standalone (training data access-controlled) |
| Diffusion imaging topological clock | [`diffusion-topological/`](diffusion-topological/) | standalone (mostly MATLAB + Python; one statistical-modeling step has a gap, see `SOURCE.md`) |

Not yet vendored (no known Python implementation exists): cell clocks,
brevican brain clock, Dementia SomaSignal Test (commercial), SITH, MileAge,
sperm sncRNA clock, IMM-AGE, iAge (commercial), retinal eyeAge, MRI+EEG brain
clock, "Intrinsic capacity" clock, TraMA, "Pace of aging" clock, Proteomic
healthspan score.

## Notes for reuse

- **Licensing varies per package** — check each folder's `SOURCE.md` before
  reuse beyond internal research reference. Several upstream repos ship no
  LICENSE file at all (flagged individually in `SOURCE.md`), and GrimAge/
  GrimAge2 coefficients specifically are not public-domain (see `biolearn/SOURCE.md`).
- **Total size**: ~275MB — mostly legitimate model coefficient/weight data
  (organage, biolearn, clockbase), not incidental bloat.
