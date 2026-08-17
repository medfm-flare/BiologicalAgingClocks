# Horvath2 (skin & blood clock)

- **Paper**: Horvath, S. et al. "Epigenetic clock for skin and blood cells applied
  to Hutchinson–Gilford Progeria Syndrome and ex vivo studies." *Aging* 10,
  1758–1775 (2018). https://doi.org/10.18632/aging.101508
- **Implementation**: no standalone repo; provided by two vendored packages.

## Option A - `methylclock` (R)

```r
devtools::load_all("../methylclock")
age_estimates <- DNAmAge(x, clocks = "skinHorvath", age = age)
```

## Option B - `biolearn` (Python)

```python
from biolearn.model_gallery import ModelGallery
gallery = ModelGallery()
result = gallery.get("Horvathv2").predict(geo_data)
```
