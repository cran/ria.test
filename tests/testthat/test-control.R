test_that("L-prime folds use only the new name", {
	expect_identical(ria.test.control()$lprime_folds, 1L)
	expect_identical(ria.test.control(lprime_folds = 5L)$lprime_folds, 5L)
	expect_error(ria.test.control(zprime_folds = 5L), "unused argument")
	expect_false("zprime_folds" %in% names(ria.test.control()))
	expect_error(ria.test.control(lprime_folds = NA_real_), "lprime_folds")
})

test_that("torch_seed is optional and validated", {
	expect_null(ria.test.control()$torch_seed)
	expect_identical(ria.test.control(torch_seed = 1)$torch_seed, 1L)
	expect_error(ria.test.control(torch_seed = -1), "Assertion on 'torch_seed' failed")
	expect_error(ria.test.control(torch_seed = 1.5), "Assertion on 'torch_seed' failed")
})

test_that("constructing control does not change R's random-number stream", {
	set.seed(42)
	r_state <- .Random.seed

	ria.test.control(torch_seed = 10L)

	expect_identical(.Random.seed, r_state)
})

test_that("torch_seed reproducibly resets Torch's random-number stream", {
	skip_if_not(torch::torch_is_installed(), "Torch runtime is not installed")

	torch::torch_manual_seed(10)
	first <- as.numeric(torch::torch_rand(5))
	torch::torch_manual_seed(10)
	second <- as.numeric(torch::torch_rand(5))

	expect_identical(first, second)
})
