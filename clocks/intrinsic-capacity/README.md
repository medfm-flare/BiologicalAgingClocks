# "Intrinsic capacity" clock

- **Paper**: Fuentealba, M. et al. "A blood-based epigenetic clock for intrinsic
  capacity predicts mortality and is associated with clinical, immunological
  and lifestyle factors." *Nat. Aging* 5, 1207–1216 (2025).
  https://doi.org/10.1038/s43587-025-00883-5
- **Implementation**: no dedicated repo from the original authors. The 91-probe
  weights have been incorporated into the vendored
  [`../dnamethyage/`](../dnamethyage/) package. See `../dnamethyage/SOURCE.md`.

## Usage (R)

Confirmed via `../dnamethyage/R/availableClock.R` - the clock identifier is
`FuentealbaM2025`:

```r
devtools::load_all("../dnamethyage")
age_estimates <- methyAge(betas, clock = "FuentealbaM2025")
```
