\donttest{
if (torch::torch_is_installed()) {
	set.seed(123)
	n <- 200
	C <- rnorm(n)
	D <- rbinom(n, 1, plogis(C))
	L <- rnorm(n, D + C)
	M <- rnorm(n, D + L + C)
	Y <- rnorm(n, D + L + M + C)
	dat <- data.frame(C, D, L, M, Y)

	res <- ria.test(
		data = dat,
		trt = "D",
		outcome = "Y",
		mediators = "M",
		pre = "C",
		post = "L",
		d0 = \(data, trt) rep(0, nrow(data)),
		d1 = \(data, trt) rep(1, nrow(data)),
		control = ria.test.control(
			crossfit_folds = 1L,
			mlr3superlearner_folds = 2L,
			lprime_folds = 2L,
			epochs = 2L,
			torch_seed = 123L
		)
	)

	print(res)
	tidy(res)
}
}
