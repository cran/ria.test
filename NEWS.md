# ria.test 0.2.1

## Reproducibility

* Add `torch_seed` to `ria.test.control()` to control Torch neural-network
  initialization and dropout independently of R's random-number generator.
* Delay Torch device initialization until after R-randomized estimation steps,
  so first-use Torch initialization cannot change cross-fitting or Z-prime folds.

# ria.test 0.2.0

## Breaking changes

* Restrict estimation to natural effects, randomized interventional analogues,
  and the TE - TE^R falsification test.
* Replace `effect` with `estimand = "test"`, `"natural"`, or `"ria"`; the test
  is now the default.
* Align returned estimand names with the paper and remove nuisance fits from the
  returned object.

# ria.test 0.1.3

## Bug fixes

* Synced fold construction and influence-function identifiers with upstream
  fixes.

# ria.test 0.1.2

## Bug fixes

* Fixed a bug caused by upgrading to `S7` 0.2.0.

# ria.test 0.1.0

## General

* Initial CRAN submission.
* Uses `ife` for storing effect estimates.
