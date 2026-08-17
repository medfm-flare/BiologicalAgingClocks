# Horvath clock (Horvath1)

- **Paper**: Horvath, S. "DNA methylation age of human tissues and cell types."
  *Genome Biol.* 14, R115 (2013). https://doi.org/10.1186/gb-2013-14-10-r115
- **Implementation**: provided by the vendored [`../biolearn/`](../biolearn/)
  package (see [`../biolearn/SOURCE.md`](../biolearn/SOURCE.md) for
  provenance). No standalone Horvath-only repo exists from the original
  author; this community package is the standard way to compute it.

## Usage (Python)

```python
from biolearn.model_gallery import ModelGallery
gallery = ModelGallery()
result = gallery.get("Horvathv1").predict(geo_data)
```
