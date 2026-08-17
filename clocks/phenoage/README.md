# PhenoAge

- **Paper**: Levine, M. E. et al. "An epigenetic biomarker of aging for lifespan
  and healthspan." *Aging* 10, 573–591 (2018). https://doi.org/10.18632/aging.101414
- **Implementation**: provided by the vendored [`../biolearn/`](../biolearn/)
  package.

## Usage (Python)

```python
from biolearn.model_gallery import ModelGallery
gallery = ModelGallery()
result = gallery.get("PhenoAge").predict(geo_data)
```
