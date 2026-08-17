# DunedinPACE

- **Paper**: Belsky, D. W. et al. "DunedinPACE, a DNA methylation biomarker of
  the pace of aging." *eLife* 11, e73420 (2022).
  https://doi.org/10.7554/eLife.73420
- **Implementation**: provided by the vendored [`../biolearn/`](../biolearn/)
  package.

## Usage (Python)

```python
from biolearn.model_gallery import ModelGallery
gallery = ModelGallery()
result = gallery.get("DunedinPACE").predict(geo_data)
```
