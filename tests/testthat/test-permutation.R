expect_derangement <- function(index, n) {
	expect_type(index, "integer")
	expect_identical(sort(index), seq_len(n))
	expect_true(all(index != seq_len(n)))
}

permutation_cost <- function(data, index) {
	distances <- as.matrix(dist(data))
	sum(distances[cbind(seq_len(nrow(data)), index)])
}

test_that("repeated profiles bypass the LP and attain zero cost", {
	local_mocked_bindings(linear_permutation_lp = function(...) stop("LP called"))
	x <- rbind(c(0, 0), c(1, 0), c(0, 0), c(1, 1),
		c(1, 0), c(1, 1), c(1, 1))
	set.seed(23)
	index <- linear_permutation(x)
	expect_derangement(index, nrow(x))
	expect_equal(permutation_cost(x, index), 0)
	expect_equal(x[index, , drop = FALSE], x)
	set.seed(23)
	expect_identical(linear_permutation(x), index)
})

test_that("identical, empty-column, and two-row profiles are handled", {
	local_mocked_bindings(linear_permutation_lp = function(...) stop("LP called"))
	for (x in list(matrix(1, 7, 2), matrix(numeric(), 7, 0),
		matrix(0, 2, 1), data.frame(d = rep(1, 5)))) {
		expect_derangement(linear_permutation(x), nrow(x))
	}
	expect_identical(linear_permutation(matrix(0, 2, 1)), c(2L, 1L))
})

test_that("profile grouping uses exact equality", {
	old_rounding <- data.table::getNumericRounding()
	on.exit(data.table::setNumericRounding(old_rounding))
	data.table::setNumericRounding(2L)
	x <- matrix(c(1, 1, 1 + 1e-14, 1 + 1e-14), ncol = 1)
	expect_identical(linear_permutation(x), c(2L, 1L, 4L, 3L))
	local_mocked_bindings(linear_permutation_lp = function(data) "fallback")
	expect_identical(linear_permutation(x[-4, , drop = FALSE]), "fallback")
})

test_that("small or invalid folds fail before entering native code", {
	local_mocked_bindings(linear_permutation_lp = function(...) stop("LP called"))
	for (n in 0:1) {
		expect_error(linear_permutation(matrix(0, n, 2)), "at least two")
	}
	for (bad in c(NA, NaN, Inf)) {
		expect_error(linear_permutation(matrix(c(0, bad), 2)), "finite numeric")
	}
})

test_that("the fast path agrees with the original LP objective", {
	# The original constraint construction and dense return, kept independently
	# to check both the objective and the interpretation of solution indices.
	original_lp <- function(data) {
		distances <- dist(data)
		distances <- distances / max(distances)
		d <- as.vector(t(as.matrix(distances)))
		n <- nrow(data)
		rows <- c(as.numeric(gl(n, n, n^2)), as.numeric(gl(n, n, n^2)) + n)
		cols <- c(1:(n^2), unlist(lapply(0:(n - 2), function(j) j + seq(1, n^2, n))),
			(0:(n - 1) * (n + 1) + 1))
		A <- Matrix::sparseMatrix(i = rows, j = cols, x = 1)
		b <- c(rep(1, 2 * n - 1), 0)
		fit <- Rsymphony::Rsymphony_solve_LP(d, A, dir = rep("==", 2 * n), rhs = b)
		expect_equal(unname(fit$status), 0)
		matrix(fit$solution, n, n)
	}
	x <- matrix(c(0, 0, 1, 1, 2, 2, 2), ncol = 1)
	P <- original_lp(x)
	expect_equal(permutation_cost(x, linear_permutation(x)),
		sum(P * as.matrix(dist(x))))
	expect_equal(sum(P * as.matrix(dist(x))), 0)
})

test_that("singleton and continuous profiles retain a globally optimal fallback", {
	permutations <- function(x) {
		if (length(x) == 1L) return(matrix(x, nrow = 1L))
		do.call(rbind, lapply(seq_along(x), function(i) cbind(x[i], permutations(x[-i]))))
	}
	for (x in list(matrix(c(0, 0, 1), ncol = 1),
		matrix(c(0, 0, 1, 2, 2), ncol = 1),
		matrix(c(0.1, 0.7, 1.9, 3.2, 8.3), ncol = 1),
		matrix(c(0, 1), ncol = 1))) {
		index <- linear_permutation(x)
		expect_derangement(index, nrow(x))
		candidates <- permutations(seq_len(nrow(x)))
		candidates <- candidates[apply(candidates, 1, function(p) all(p != seq_len(nrow(x)))), , drop = FALSE]
		optimum <- min(apply(candidates, 1, function(p) permutation_cost(x, p)))
		expect_equal(permutation_cost(x, index), optimum)
	}
})

test_that("invalid solver results are rejected", {
	x <- matrix(1:3, ncol = 1)
	for (fit in list(list(status = 1L),
		list(status = 0L, solution = rep(0.5, 9)),
		list(status = 0L, solution = as.vector(diag(3))),
		list(status = 0L, solution = rep(0, 9)),
		list(status = 0L, solution = rep(NA_real_, 9)))) {
		local_mocked_bindings(Rsymphony_solve_LP = function(...) fit, .package = "Rsymphony")
		expect_error(linear_permutation(x), "Permutation LP did not return")
	}
})

test_that("set_lp indexes multiple L columns in fold order with one profile column", {
	x <- data.frame(d = rep(0, 8), l = 1:8, l2 = (1:8)^2, m = 0, y = 0)
	vars <- ria.test_vars(D = "d", C = character(), L = c("l", "l2"), M = "m", Y = "y")
	identity_shift <- function(data, trt) data[[trt]]
	cd <- ria.test_data(x, vars, rep(1, 8), identity_shift, identity_shift)
	sets <- list(c(7L, 1L, 5L, 3L), c(8L, 6L, 2L, 4L))
	local_mocked_bindings(
		make_folds = function(...) lapply(sets, function(i) list(validation_set = i)),
		linear_permutation = function(data) {
			expect_identical(dim(data), c(4L, 1L))
			c(2L, 3L, 4L, 1L)
		})
	expected <- x[c("l", "l2")]
	for (i in sets) expected[i, ] <- x[i[c(2, 3, 4, 1)], c("l", "l2")]
	expect_equal(set_lp(cd, 2L), expected)
})
