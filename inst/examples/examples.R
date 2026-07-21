\donttest{
if (torch::torch_is_installed()) {
	set.seed(123)
	n <- 200
	w <- rnorm(n)
	a <- rbinom(n, 1, plogis(w))
	l <- rnorm(n, a + w)
	m <- rnorm(n, a + l + w)
	y <- rnorm(n, a + l + m + w)
	dat <- data.frame(w, a, l, m, y)

	res <- ria.test(
		data = dat,
		trt = "a",
		outcome = "y",
		mediators = "m",
		pre = "w",
		post = "l",
		d0 = \(data, trt) rep(0, nrow(data)),
		d1 = \(data, trt) rep(1, nrow(data)),
		control = ria.test.control(
			crossfit_folds = 1L,
			mlr3superlearner_folds = 2L,
			zprime_folds = 2L,
			epochs = 2L,
			torch_seed = 123L
		)
	)

	print(res)
	tidy(res)
}
}
