# Hannum clock

- **Paper**: Hannum, G. et al. "Genome-wide methylation profiles reveal
  quantitative views of human aging rates." *Mol. Cell* 49, 359–367 (2013).
  https://doi.org/10.1016/j.molcel.2012.10.016
- **Implementation**: no standalone repo; provided by vendored multi-clock packages.

## Option A - `methylclock` (R)

```r
devtools::load_all("../methylclock")
age_estimates <- DNAmAge(x, clocks = "Hannum", age = age)
```

## Option B - `biolearn` (Python)

```python
from biolearn.model_gallery import ModelGallery
gallery = ModelGallery()
result = gallery.get("Hannum").predict(geo_data)
```
