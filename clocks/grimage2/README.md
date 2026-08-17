# GrimAge2

- **Paper**: Lu, A. T. et al. "DNA methylation GrimAge version 2." *Aging* 14,
  9484–9549 (2022). https://doi.org/10.18632/aging.204434
- **Implementation**: provided by the vendored [`../biolearn/`](../biolearn/) package.
  **Licensing note**: original coefficients are not publicly released by the
  authors; `biolearn` includes them with the original authors' direct
  permission, not from a public release. See `../biolearn/SOURCE.md`.
  Alternative: official upload-based calculator at
  [dnamage.clockfoundation.org](https://dnamage.clockfoundation.org/).

## Usage (Python)

```python
from biolearn.model_gallery import ModelGallery
gallery = ModelGallery()
result = gallery.get("GrimAgeV2").predict(geo_data)
# Note: requires 'sex' and 'age' columns in geo_data metadata
```
