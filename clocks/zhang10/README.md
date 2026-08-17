# Zhang10 (10-CpG mortality clock)

- **Paper**: Zhang, Y. et al. "DNA methylation signatures in peripheral blood
  strongly predict all-cause mortality." *Nat. Commun.* 8, 14617 (2017).
  https://doi.org/10.1038/ncomms14617
- **Implementation**: provided by the vendored [`../biolearn/`](../biolearn/)
  package.

## Usage (Python)

```python
from biolearn.model_gallery import ModelGallery
gallery = ModelGallery()
result = gallery.get("Zhang_10").predict(geo_data)
```
