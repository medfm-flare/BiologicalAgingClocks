# Source

- **Upstream repo**: https://github.com/miargentieri/proteomic-age-ukb
- **Vendored commit**: `eda0b4e9fbef3dd971570bb0bc8c47ee97db5c36` (2025-07-30)
- **Vendored on**: 2026-08-16
- **License**: MIT (see `LICENSE` in this directory)
- **Paper**: Argentieri, M. A. et al. "Proteomic aging clock predicts mortality
  and risk of common age-related diseases in diverse populations." *Nat. Med.*
  30, 2450–2460 (2024). https://doi.org/10.1038/s41591-024-03164-7

**Important**: this is analysis code only. The trained ProtAge/ProtAge20 model
weights themselves are *not* included - the original authors indicated a
scoring package was "in development" as of publication, with access on request.
Use `clocks/organage/` (Oh et al. 2023) as the working organ-clock
implementation for this table row; this repo is here for reference/methods
reproduction, not as a runnable clock out of the box.

This is a Python-only vendored copy. Data import/recoding/cleaning scaffolding
present upstream is not included here; the actual ProtAge model code
(`code/UKB-proteomic-age-model-*.py`, `lgbm_functions.py`,
`UKB-ProtAge20-*.py`) is pure Python and intact. As noted above, this was
already analysis/reference code, not a runnable clock (no released weights).

Direct copy at the commit above, git history stripped. To update, re-clone
upstream at a newer commit and replace this directory.
