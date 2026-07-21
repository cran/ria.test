test_that("the package estimates only the quantities needed for the test", {
	params <- ria.test:::estimation_parameters

	expect_named(params, c("natural", "randomized"))
	expect_length(params$natural, 2L)
	expect_length(params$randomized, 3L)
	expect_false("estimand" %in% names(formals(ria.test)))
	expect_true(all(c("pre", "post") %in% names(formals(ria.test))))
	expect_identical(formals(ria.test)$pre, quote(expr = ))
	expect_identical(formals(ria.test)$post, quote(expr = ))
})

test_that("the test estimand set contains all Table 1 quantities", {
	natural_eif <- list("111" = 8, "000" = 1)
	ria_eif <- list("1111" = 9, "1100" = 5, "0000" = 3)
	estimates <- ria.test:::calculate_estimates(natural_eif, ria_eif)

	expect_named(estimates, c("TE", "TE^R", "TE - TE^R", "NIE^R", "NDE^R"))
	expect_equal(
		unlist(estimates),
		c("TE" = 7, "TE^R" = 6, "TE - TE^R" = 1, "NIE^R" = 4, "NDE^R" = 2)
	)
})
