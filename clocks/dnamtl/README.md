# DNAmTL (DNA methylation-based telomere length)

- **Paper**: Lu, A. T. et al. "DNA methylation-based estimator of telomere
  length." *Aging* 11, 5895–5923 (2019). https://doi.org/10.18632/aging.102173
- **Implementation**: provided by the vendored [`../biolearn/`](../biolearn/)
  package.

## Usage (Python)

```python
from biolearn.model_gallery import ModelGallery
gallery = ModelGallery()
result = gallery.get("DNAmTL").predict(geo_data)
```
