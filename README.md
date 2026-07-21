<!-- README.md is generated from README.Rmd. Please edit that file -->

# ria.test

<!-- badges: start -->

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental) ![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)

<!-- badges: end -->

*ria.test* implements the empirical test introduced by Yu, Ge, and Elwert (2026) for detecting when randomized interventional analogues should not be interpreted as natural mediation effects. The test estimates `TE - TE^R`, the difference between the total effect and its randomized interventional analogue. Rejecting `TE - TE^R = 0` falsifies the composite null that the natural indirect and direct effects equal their randomized interventional analogues. The procedure remains valid in settings where the natural effects themselves are not identified, and `|TE - TE^R|` provides a lower bound on the total divergence between the natural and randomized interventional decompositions.

The implementation uses Riesz-regression machinery adapted from the upstream mediation-estimation codebase for the total-effect contrast and associated uncertainty estimates.

*ria.test* is derived from the *crumble* package. Attribution identifies authorship of incorporated code and does not imply endorsement of this package or its modifications.

### Installation

``` r
remotes::install_github("ang-yu/ria.test")
```

### Usage

``` r
library(ria.test)

# `set.seed()` controls R-level randomness; `torch_seed` controls Torch.
set.seed(123)
n <- 500
w <- rnorm(n)
a <- rbinom(n, 1, plogis(w))
l <- rnorm(n, a + w)
m <- rnorm(n, a + l + w)
y <- rnorm(n, a + l + m + w)
dat <- data.frame(w, a, l, m, y)

test_fit <- ria.test(
  data = dat,
  trt = "a",
  outcome = "y",
  mediators = "m",
  pre = "w",
  post = "l",
  d0 = \(data, trt) rep(0, nrow(data)),
  d1 = \(data, trt) rep(1, nrow(data)),
  control = ria.test.control(torch_seed = 123L)
)

tidy(test_fit)
```
