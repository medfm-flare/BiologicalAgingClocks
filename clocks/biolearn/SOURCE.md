# Source

- **Upstream repo**: https://github.com/bio-learn/biolearn
- **Vendored commit**: `0d714f5a0c0ad5743b6315f3edab1f86112d394f` (2026-07-11)
- **Vendored on**: 2026-08-16
- **License**: New BSD (see `LICENSE` in this directory)

Multi-clock Python package. Vendored here primarily as the implementation source for:

- **GrimAge (v1)** - Lu, A. T. et al. *Aging* 11, 303–327 (2019). Coefficients are
  proprietary/not released by the original authors; biolearn's implementation
  exists with the original authors' direct permission, not from a public release.
- **GrimAge2** - Lu, A. T. et al. *Aging* 14, 9484–9549 (2022). Same licensing note as above.
- **AdaptAge / DamAge** (YingAdaptAge / YingDamAge) - Ying, K. et al. *Nat. Aging*
  4, 231–246 (2024).

Also includes Horvath, Hannum, PhenoAge, DunedinPACE, DNAmTL, and others - see
package docs for the full clock list.

**Licensing flag**: if this repo's GrimAge/GrimAge2 output is used beyond
internal research reference, confirm licensing terms directly - the original
GrimAge coefficients are not public domain.

Direct copy at the commit above, git history stripped. To update, re-clone
upstream at a newer commit and replace this directory.
