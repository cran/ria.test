# ria.test 0.3.0

* Use D for treatment, C for baseline covariates, and L for post-treatment
  confounders throughout the implementation, examples, and documentation.
  The outcome-observation indicator is named `observed` internally.
  Rename the matched copy to L-prime and its control to `lprime_folds`.
  This is a breaking rename: use `lprime_folds` in place of `zprime_folds`.
  The public arguments `trt`, `pre`, and `post` are unchanged.
* L-prime permutations now bypass the LP when every treatment/baseline profile
  in a fold occurs at least twice. Random cycles within identical profiles give
  an exact zero-cost optimum without constructing distances or an LP. This also
  handles all-identical profiles without dividing by zero.
* Permutations return indices internally, and L is selected directly instead of
  multiplying by a dense permutation matrix. Folds with singleton profiles
  continue to use the full LP; solver status and permutation validity are checked.
  Folds with fewer than two observations produce an explicit error.
* The fast path is reproducible under `set.seed()`, but chooses tied optima and
  consumes random numbers differently from earlier versions. Permutations and
  downstream estimates can therefore change for the same seed.
* This bypasses the reported Rsymphony native crash for qualifying folds; it does
  not fix or diagnose the underlying native defect. The general LP path still
  depends on Rsymphony and retains its quadratic size.

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
