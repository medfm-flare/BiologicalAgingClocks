# Horvath clock (Horvath1)

- **Paper**: Horvath, S. "DNA methylation age of human tissues and cell types."
  *Genome Biol.* 14, R115 (2013). https://doi.org/10.1186/gb-2013-14-10-r115
- **Implementation**: provided by the vendored [`methylclock`](../methylclock/) package
  (see [`../methylclock/SOURCE.md`](../methylclock/SOURCE.md) for provenance).
  No standalone Horvath-only repo exists from the original author; this
  community package is the standard way to compute it.

## Usage (R)

```r
devtools::load_all("../methylclock")  # or install locally, see methylclock/README.md

# `x`: a data frame of beta values (CpGs x samples, rownames = CpG IDs)
# `age`: optional vector of chronological ages, for accuracy stats
age_estimates <- DNAmAge(x, clocks = "Horvath", age = age)
```

Other closely related clocks available in the same package: `"skinHorvath"`
(Horvath2) and `"Hannum"`.
