# AdaptAge / DamAge (YingAdaptAge / YingDamAge)

- **Paper**: Ying, K. et al. "Causality-enriched epigenetic age uncouples
  damage and adaptation." *Nat. Aging* 4, 231–246 (2024). PMID:
  [38243142](https://pubmed.ncbi.nlm.nih.gov/38243142/).
  https://doi.org/10.1038/s43587-023-00557-0
- **Implementation**: provided by the vendored [`../biolearn/`](../biolearn/) package.
  Coefficients also available via the vendored [`../clockbase/`](../clockbase/) system.

**Note**: see [`../clocks_table.md`](../../clocks_table.md) Notes section - the
review's own Table 1 files this under "4th generation (deep learning)," but
this is actually a causal-inference (Mendelian randomization + elastic net)
model trained on aging-related traits, not chronological age.

## Usage (Python)

```python
from biolearn.model_gallery import ModelGallery
gallery = ModelGallery()
adapt_result = gallery.get("YingAdaptAge").predict(geo_data)
dam_result = gallery.get("YingDamAge").predict(geo_data)
# A third related model, YingCausAge, is also available in the same package
```
