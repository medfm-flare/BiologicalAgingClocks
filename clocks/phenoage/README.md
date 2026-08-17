# PhenoAge

- **Paper**: Levine, M. E. et al. "An epigenetic biomarker of aging for lifespan
  and healthspan." *Aging* 10, 573–591 (2018). https://doi.org/10.18632/aging.101414
- **Implementation**: provided by the vendored [`methylclock`](../methylclock/) package
  (see [`../methylclock/SOURCE.md`](../methylclock/SOURCE.md) for provenance).
  Internally, `methylclock` refers to this clock as `"Levine"` (after the
  paper's first author) rather than `"PhenoAge"`.

## Usage (R)

```r
devtools::load_all("../methylclock")  # or install locally, see methylclock/README.md

# `x`: a data frame of beta values (CpGs x samples, rownames = CpG IDs)
# `age`: optional vector of chronological ages, for accuracy stats
age_estimates <- DNAmAge(x, clocks = "Levine", age = age)
```
