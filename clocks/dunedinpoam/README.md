# DunedinPoAm

- **Paper**: Belsky, D. W. et al. "Quantification of the pace of biological
  aging in humans through a blood test, the DunedinPoAm DNA methylation
  algorithm." *eLife* 9, e54870 (2020). https://doi.org/10.7554/eLife.54870
- **Implementation**: provided by the vendored [`../biolearn/`](../biolearn/)
  package as `DunedinPoAm38`, the updated version of this clock.

## Usage (Python)

```python
from biolearn.model_gallery import ModelGallery
gallery = ModelGallery()
result = gallery.get("DunedinPoAm38").predict(geo_data)
```
