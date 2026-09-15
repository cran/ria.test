add_lp <- function(cd, control) {
	lp <- set_lp(cd, control$lprime_folds)
	cd@data_0lp <- cd@data_0
	cd@data_1lp <- cd@data_1
	cd@data_0lp[, cd@vars@L] <- lp
	cd@data_1lp[, cd@vars@L] <- lp
	cd
}

linear_permutation <- function(data) {
	n <- nrow(data)
	if (is.null(n) || n < 2L) {
		stop("A permutation fold must contain at least two observations.")
	}
	data <- as.matrix(data)
	if (!is.numeric(data) || any(!is.finite(data))) {
		stop("Permutation profiles must contain only finite numeric values.")
	}

	# Integer codes preserve exact equality, even for very close doubles and
	# regardless of data.table's numeric rounding setting.
	if (ncol(data) == 0L) {
		groups <- list(seq_len(n))
	} else {
		profiles <- data.table::as.data.table(lapply(as.data.frame(data),
			function(x) match(x, unique(x))))
		groups <- split(seq_len(n), data.table::frankv(profiles, ties.method = "dense"))
	}
	if (all(lengths(groups) >= 2L)) {
		# Within-profile cycles have no fixed points and attain the lower bound
		# of zero cost. This also handles max(dist(data)) == 0 without division.
		# Tied optima and RNG consumption differ from the LP solver.
		index <- integer(n)
		for (group in groups) {
			ordering <- group[sample.int(length(group))]
			index[ordering] <- c(ordering[-1L], ordering[1L])
		}
		return(index)
	}

	# Solve the whole fold: keeping duplicate groups separate can prevent
	# an optimal (or even feasible) assignment for the singleton profiles.
	linear_permutation_lp(data)
}

linear_permutation_lp <- function(data) {
	distances <- dist(data)
	max_distance <- max(distances)
	if (!is.finite(max_distance)) stop("Permutation distances must be finite.")
	if (max_distance > 0) distances <- distances / max_distance
	costs  <- as.vector(t(as.matrix(distances)))
	n <- nrow(data)
	rows <- c(as.numeric(gl(n, n, n^2)), as.numeric(gl(n, n, n^2)) + n)
	cols <- c(1:(n^2), unlist(lapply(0:(n - 2), function(j) j + seq(1, n^2, n))), (0:(n - 1)*(n + 1) + 1))
	constraints <- Matrix::sparseMatrix(i = rows, j = cols, x = 1)
	b <- Matrix::Matrix(Matrix::sparseVector(i = 1:(2*n - 1), x = 1, length = 2*n), ncol = 1)
	fit <- Rsymphony::Rsymphony_solve_LP(costs, constraints, dir = rep("==", nrow(b)), rhs = b)
	if (length(fit$status) != 1L || is.na(fit$status) || fit$status != 0L) {
		stop("Permutation LP did not return an optimal solution.")
	}
	# The assignment LP has integral vertices. Reject a failed or fractional
	# result rather than silently turning it into a different assignment.
	x <- fit$solution
	if (length(x) != n^2 || any(!is.finite(x)) ||
			any(pmin(abs(x), abs(x - 1)) > 1e-6)) {
		stop("Permutation LP did not return a valid permutation.")
	}
	selected <- which(x > 0.5)
	rows <- (selected - 1L) %% n + 1L
	cols <- (selected - 1L) %/% n + 1L
	if (length(selected) != n || anyDuplicated(rows) ||
			anyDuplicated(cols) || any(rows == cols)) {
		stop("Permutation LP did not return a valid permutation.")
	}
	index <- integer(n)
	index[rows] <- as.integer(cols)
	index
}

set_lp <- function(cd, folds) {
	folds <- make_folds(cd@data, folds, cd@vars@id)

	DC <- one_hot_encode(cd@data, c(cd@vars@D, cd@vars@C))
	L <- cd@data[, cd@vars@L, drop = FALSE]

	permute <- function(i) {
		lp <- data.frame(matrix(NA, nrow = nrow(DC), ncol = ncol(L)))
		names(lp) <- names(L)
		index <- linear_permutation(DC[i, , drop = FALSE])
		lp[i, ] <- L[i[index], , drop = FALSE]
		lp
	}

	permuted <- vector("list", length(folds))
	i <- 1
	cli::cli_progress_step("Permuting L-prime variables... {i}/{length(folds)} tasks")
	for (i in seq_along(folds)) {
		permuted[[i]] <- permute(folds[[i]]$validation_set) |>
			as.list()
		cli::cli_progress_update()
	}

	cli::cli_progress_done()
	revert_list(permuted) |>
		lapply(\(x) Reduce(data.table::fcoalesce, x)) |>
		data.frame()
}

# https://stackoverflow.com/questions/15263146/revert-list-structure
revert_list <- function(ls) { # @Josh O'Brien
	# get sub-elements in same order
	x <- lapply(ls, `[`, names(ls[[1]]))
	# stack and reslice
	apply(do.call(rbind, x), 2, as.list)
}
