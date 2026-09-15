test_that("baseline C and the observation indicator remain separate", {
	x <- data.frame(D = c(0, 1, 0, 1), C1 = 1:4, C2 = 4:1,
		L = c(0, 0, 1, 1), M = 0, Y = c(1, NA, 0, NA), seen = c(1, 0, 1, 0))
	vars <- ria.test_vars(D = "D", C = c("C1", "C2"), L = "L",
		M = "M", Y = "Y", observed = "seen")
	cd <- ria.test_data(x, vars, rep(1, 4),
		function(data, trt) rep(0, nrow(data)),
		function(data, trt) rep(1, nrow(data)))
	expect_identical(cd@vars@C, c("C1", "C2"))
	expect_identical(censored(cd@data, cd@vars@observed), c(TRUE, FALSE, TRUE, FALSE))
	for (shifted in list(cd@data_0, cd@data_1)) {
		expect_identical(shifted[c("C1", "C2")], x[c("C1", "C2")])
		expect_equal(shifted$seen, rep(1, 4))
	}
})

test_that("detects missing variables", {
	foo <- data.frame(d = 1, C = 1, m = 1, l = NA, y = 1)
	expect_error(
		ria.test(foo, "d", "y", "m", "l", "C"),
		"Assertion on 'data' failed: Missing data found in treatment/covariate/mediator/observed nodes."
	)
})
