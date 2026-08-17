# Hannum clock

- **Paper**: Hannum, G. et al. "Genome-wide methylation profiles reveal
  quantitative views of human aging rates." *Mol. Cell* 49, 359–367 (2013).
  https://doi.org/10.1016/j.molcel.2012.10.016
- **Implementation**: provided by the vendored [`../biolearn/`](../biolearn/)
  package.

## Usage (Python)

```python
from biolearn.model_gallery import ModelGallery
gallery = ModelGallery()
result = gallery.get("Hannum").predict(geo_data)
```
