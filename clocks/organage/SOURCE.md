# Source

- **Upstream repo**: https://github.com/hamiltonoh/organage
- **Vendored commit**: `59303fd0dccc191be1ff34bf0bbf5efd8b90387a` (2024-06-01)
- **Vendored on**: 2026-08-16
- **License**: MIT (see `LICENSE` in this directory)
- **PyPI**: `organage`

Vendored here as the implementation source for two rows in `clocks_table.md`:

- **"Conventional" whole-body proteomic clock** and **Organ clocks** (brain,
  heart, lung, liver, kidney, immune, artery, etc.) - Oh, H. S. et al. "Organ
  aging signatures in the plasma proteome track health and disease." *Nature*
  624, 164–172 (2023). https://doi.org/10.1038/s41586-023-06802-1

`src/organage/data/` (~87MB) contains the trained model weights/coefficients
and SomaScan annotation files needed to actually compute organ ages - this is
the bulk of this vendored copy's size, not incidental data.

Direct copy at the commit above, git history stripped. To update, re-clone
upstream at a newer commit and replace this directory.
