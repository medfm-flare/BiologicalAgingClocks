# Vendored clock implementations

See [`../clocks_table.md`](../clocks_table.md) for the full catalog, citations,
and which clocks still have no located public implementation at all.

## Structure

Not every clock has its own dedicated upstream repo - some are commonly
computed via shared multi-clock packages. To reflect that honestly instead of
duplicating the same package under multiple folders, this repo uses two kinds
of entries:

- **Standalone folders** - a direct copy of a clock's own dedicated repo
  (e.g. `dunedinpace/`, `trama/`, `organage/`).
- **Pointer folders** - a thin `README.md` with usage instructions, for
  clocks implemented inside a shared package vendored elsewhere
  (e.g. `horvath/`, `hannum/`, `grimage/`).

Every standalone/shared package folder has a `SOURCE.md` recording the exact
upstream commit and date it was vendored, since git history is stripped on
import (direct copy, not submodules).

## Shared multi-clock packages

A few packages implement many clocks at once and are vendored once, with
pointer folders for each named clock:

| Package | Covers |
|---|---|
| [`methylclock/`](methylclock/) | Horvath, Horvath2, Hannum, PhenoAge, DNAmTL |
| [`biolearn/`](biolearn/) | Horvath, Horvath2, Hannum, PhenoAge, GrimAge, GrimAge2, DunedinPACE, DunedinPoAm38, DNAmTL, Zhang10, YingAdaptAge, YingDamAge, YingCausAge, and more |
| [`methylcipher/`](methylcipher/) | Horvath, Hannum, PhenoAge (PC-Clocks), Zhang10, DNAmTL, and more |
| [`dnamethyage/`](dnamethyage/) | Horvath, Horvath2, Hannum, DunedinPACE, PC-Clocks, "Intrinsic capacity" (FuentealbaM2025), and more |

## Full clock index

| Clock | Folder | Type |
|---|---|---|
| Horvath | [`horvath/`](horvath/) | pointer → `methylclock/` |
| Horvath2 | [`horvath2/`](horvath2/) | pointer → `methylclock/` or `biolearn/` |
| Hannum | [`hannum/`](hannum/) | pointer → `methylclock/` or `biolearn/` |
| Zhang10 | [`zhang10/`](zhang10/) | pointer → `methylcipher/` or `biolearn/` |
| PhenoAge | [`phenoage/`](phenoage/) | pointer → `methylclock/` |
| GrimAge (v1) | [`grimage/`](grimage/) | pointer → `biolearn/` (coefficients proprietary, see note) |
| GrimAge2 | [`grimage2/`](grimage2/) | pointer → `biolearn/` (coefficients proprietary, see note) |
| DunedinPACE | [`dunedinpace/`](dunedinpace/) | standalone |
| DunedinPoAm | [`dunedinpoam/`](dunedinpoam/) | standalone (PoAm38 also in `dunedinpace/`) |
| AdaptAge / DamAge | [`adaptage-damage/`](adaptage-damage/) | pointer → `biolearn/` |
| DNAmTL | [`dnamtl/`](dnamtl/) | pointer → `methylclock/` or `biolearn/` |
| PathwayAge | [`pathwayage/`](pathwayage/) | standalone |
| CpGPT | [`cpgpt/`](cpgpt/) | standalone (weights likely external) |
| "Intrinsic capacity" clock | [`intrinsic-capacity/`](intrinsic-capacity/) | pointer → `dnamethyage/` |
| LifeClock | [`lifeclock/`](lifeclock/) | standalone |
| "Conventional" + organ clocks (Oh et al.) | [`organage/`](organage/) | standalone |
| Organ clocks (analysis code, Argentieri/Groves) | [`proteomic-age-ukb/`](proteomic-age-ukb/), [`nshd-proteomic-organ-ageing/`](nshd-proteomic-organ-ageing/) | standalone (analysis code, no runnable weights) |
| Proteomic healthspan score | [`proteomic-healthspan/`](proteomic-healthspan/) | standalone |
| ClockBase | [`clockbase/`](clockbase/) | standalone (large agentic-AI system) |
| TraMA | [`trama/`](trama/) | standalone |
| "Pace of aging" clock | [`pace-of-aging/`](pace-of-aging/) | standalone |
| Delphi-2M | [`delphi2m/`](delphi2m/) | standalone (training data access-controlled) |
| Diffusion imaging topological clock | [`diffusion-topological/`](diffusion-topological/) | standalone |

Not yet vendored (no public implementation located): cell clocks, brevican
brain clock, Dementia SomaSignal Test (commercial), SITH, MileAge, sperm
sncRNA clock, IMM-AGE, iAge (commercial), retinal eyeAge, MRI+EEG brain clock.
See `clocks_table.md` for details and citations on each.

## Notes for reuse

- **Licensing varies per package** - check each folder's `SOURCE.md` before
  reuse beyond internal research reference. Several upstream repos ship no
  LICENSE file at all (flagged individually in `SOURCE.md`), and GrimAge/
  GrimAge2 coefficients specifically are not public-domain (see `biolearn/SOURCE.md`).
- **Total size**: ~370MB, mostly legitimate model coefficient/weight data
  (organage, methylclock, biolearn, methylcipher, clockbase), not incidental bloat.
