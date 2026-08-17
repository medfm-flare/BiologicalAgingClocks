# BiologicalAgingClocks

A catalog and working code collection for biological aging clocks - computational
models that estimate biological (rather than chronological) age from molecular,
proteomic, cellular, or imaging data.

This repo was seeded from Wyss-Coray, T. & Topol, E. J. "Biological aging clocks
in health and disease." *Nature Medicine* 32, 2383–2394 (2026).
https://doi.org/10.1038/s41591-026-04495-3 - every named clock mentioned in that
review is tracked here, along with its original paper and, where public code
exists, a working implementation vendored directly into this repo.

## Contents

- **[`clocks_table.md`](clocks_table.md)** - the full catalog: every clock,
  grouped by type (epigenetic/DNA methylation, proteomic, and other omic/imaging
  modalities), with its original paper citation, a **Vendored Implementation**
  column pointing into this repo, and an **Other Implementations** column for
  public code we found but haven't vendored.
- **[`clocks/`](clocks/)** - the vendored code itself. See
  [`clocks/README.md`](clocks/README.md) for the directory structure (standalone
  vs. pointer folders, shared multi-clock packages) and the full index of what's
  vendored vs. not yet available.

## Status

~20 of the ~30 clocks in the catalog have a working vendored implementation.
The remainder have no public implementation located as of this writing (some
are commercial-only tests, some are simply unreleased) - see the Notes section
of `clocks_table.md` for details on each.

## Provenance

Every vendored package includes a `SOURCE.md` recording the exact upstream
commit, vendor date, and license status. Code is vendored as a direct copy
(git history stripped) rather than as submodules - see `SOURCE.md` in each
folder for how to pull in updates from upstream.
