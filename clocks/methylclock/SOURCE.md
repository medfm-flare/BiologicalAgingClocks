# Source

- **Upstream repo**: https://github.com/isglobal-brge/methylclock
- **Vendored commit**: `c0e5c6703272a3b0551afc42fa9ac18b7acdc186` (2026-05-18)
- **Vendored on**: 2026-08-16
- **License**: MIT (see `LICENSE` in this directory)

This is a multi-clock R package, not a single-purpose repo. It's vendored here
as the shared implementation home for several clocks in `clocks_table.md` that
don't have their own dedicated upstream repos, including:

- **Horvath (Horvath1)** - Horvath, S. *Genome Biol.* 14, R115 (2013).
- **Horvath2** (skin & blood clock) - Horvath, S. et al. *Aging* 10, 1758–1775 (2018).
- **Hannum** - Hannum, G. et al. *Mol. Cell* 49, 359–367 (2013).
- **PhenoAge** - Levine, M. E. et al. *Aging* 10, 573–591 (2018).
- **DNAmTL** - Lu, A. T. et al. *Aging* 11, 5895–5923 (2019).

See `R/` for the clock-computation functions (`DNAmAge()` and friends) and
`data/coef*.rda` for each clock's per-CpG coefficients.

This is a direct copy of the upstream R package at the commit above, with git
history stripped. To update, re-clone upstream at a newer commit and replace
this directory, updating the commit hash/date here.
