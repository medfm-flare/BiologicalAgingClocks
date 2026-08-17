# BiologicalAgingClocks

A catalog and working code collection for biological aging clocks - computational
models that estimate biological (rather than chronological) age from molecular,
proteomic, cellular, or imaging data.

This repo was seeded from Wyss-Coray, T. & Topol, E. J. "Biological aging clocks
in health and disease." *Nature Medicine* 32, 2383-2394 (2026).
https://doi.org/10.1038/s41591-026-04495-3 - every named clock mentioned in that
review is tracked here, along with its original paper and, where public Python
code exists, a working implementation vendored directly into this repo.

**This repo is Python-only.** Every vendored implementation here is Python.
Clocks for which no Python implementation exists are not part of this catalog.

## Clock summary table

19 clocks currently have a working, vendored Python implementation. Model keys
are the exact string passed to `ModelGallery().get(...)` for `biolearn`-based
clocks (see [`clocks/biolearn/`](clocks/biolearn/)).

### Epigenetic (DNA methylation)

| Clock | Python package | Model key / entry point |
|---|---|---|
| Horvath (Horvath1) | [`biolearn`](clocks/biolearn/) | `Horvathv1` |
| Horvath2 (skin & blood) | [`biolearn`](clocks/biolearn/) | `Horvathv2` |
| Hannum | [`biolearn`](clocks/biolearn/) | `Hannum` |
| Zhang10 | [`biolearn`](clocks/biolearn/) | `Zhang_10` |
| PhenoAge | [`biolearn`](clocks/biolearn/) | `PhenoAge` |
| GrimAge (v1) | [`biolearn`](clocks/biolearn/) | `GrimAgeV1` (coefficients proprietary, see `biolearn/SOURCE.md`) |
| GrimAge2 | [`biolearn`](clocks/biolearn/) | `GrimAgeV2` (coefficients proprietary, see `biolearn/SOURCE.md`) |
| DunedinPACE | [`biolearn`](clocks/biolearn/) | `DunedinPACE` |
| DunedinPoAm | [`biolearn`](clocks/biolearn/) | `DunedinPoAm38` |
| AdaptAge / DamAge | [`biolearn`](clocks/biolearn/) | `YingAdaptAge` / `YingDamAge` |
| DNAmTL | [`biolearn`](clocks/biolearn/) | `DNAmTL` |
| PathwayAge | [`pathwayage`](clocks/pathwayage/) | standalone package |
| CpGPT | [`cpgpt`](clocks/cpgpt/) | PyPI: `CpGPT`, HuggingFace weights |

### Proteomic

| Clock | Python package | Notes |
|---|---|---|
| "Conventional" whole-body clock | [`organage`](clocks/organage/) | PyPI: `organage` |
| Organ clocks (brain, heart, lung, liver, kidney, immune, artery, etc.) | [`organage`](clocks/organage/) | Full working clock (Oh et al. 2023) |
| Organ clocks (Argentieri et al.) | [`proteomic-age-ukb`](clocks/proteomic-age-ukb/) | Python model code, analysis-only - ProtAge weights not released |
| ClockBase | [`clockbase`](clocks/clockbase/) | Large agentic-AI codebase, multi-species |

### Other modalities

| Clock | Python package | Notes |
|---|---|---|
| LifeClock | [`lifeclock`](clocks/lifeclock/) | EHRFormer, PyTorch transformer |
| Delphi-2M | [`delphi2m`](clocks/delphi2m/) | PyTorch, UK Biobank training data access-controlled |
| Diffusion imaging topological clock | [`diffusion-topological`](clocks/diffusion-topological/) | Mostly MATLAB + Python; one statistical-modeling step has a gap, see `SOURCE.md` |

**Never had public code** (commercial, unreleased, or paywalled): SITH, cell
clocks, brevican brain clock, Dementia SomaSignal Test, MileAge, sperm sncRNA
clock, IMM-AGE, iAge, retinal eyeAge, MRI+EEG brain clock.

## Contents

- **[`clocks_table.md`](clocks_table.md)** - the full catalog: every clock,
  grouped by type (epigenetic/DNA methylation, proteomic, and other omic/imaging
  modalities), with its original paper citation, a **Vendored Implementation**
  column pointing into this repo, and an **Other Implementations** column for
  public Python code we found but haven't vendored.
- **[`clocks/`](clocks/)** - the vendored code itself. See
  [`clocks/README.md`](clocks/README.md) for the directory structure (standalone
  vs. pointer folders, shared multi-clock packages) and the full index of what's
  vendored vs. not yet available.

## Provenance

Every vendored package includes a `SOURCE.md` recording the exact upstream
commit, vendor date, and license status. Code is vendored as a direct copy
(git history stripped) rather than as submodules - see `SOURCE.md` in each
folder for how to pull in updates from upstream.
