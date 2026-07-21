#' Estimate randomized interventional analogues and their falsification test
#'
#' Estimate the total effect, its randomized interventional analogue (RIA),
#' their difference, and the randomized interventional indirect and direct effects.
#' \eqn{TE - TE^R} is the test statistic for the composite null
#' \eqn{NIE = NIE^R} and \eqn{NDE = NDE^R}.
#'
#' @param data [\code{data.frame}]\cr
#'  A \code{data.frame} in wide format containing all necessary variables
#'  for the estimation problem.
#' @param trt [\code{character}]\cr
#'  A vector containing the column names of treatment variables.
#' @param outcome [\code{character(1)}]\cr
#'  The column name of the outcome variable.
#' @param mediators [\code{character}]\cr
#'	A vector containing the column names of the mediator variables.
#' @param pre [\code{character}]\cr
#'  A vector containing the column names of pre-treatment confounders to be
#'  controlled for.
#' @param post [\code{character}]\cr
#'  A vector containing the column names of post-treatment confounders.
#' @param obs [\code{character(1)}]\cr
#'  An optional column name (with values coded as 0 or 1) for whether or not the \code{outcome} is observed.
#'  Must be provided if there is missingness in the outcome! Default is \code{NULL}.
#' @param id [\code{character(1)}]\cr
#'  An optional column name containing cluster level identifiers.
#' @param d0 [\code{closure}]\cr
#'  A two argument function that specifies how treatment variables should be shifted.
#'  See examples for how to specify shift functions for continuous, binary, and categorical exposures.
#' @param d1 [\code{closure}]\cr
#'  A two argument function that specifies how treatment variables should be shifted.
#'  See examples for how to specify shift functions for continuous, binary, and categorical exposures.
#' @param weights [\code{numeric}]\cr
#'  A optional vector of survey weights.
#' @param learners [\code{character}]\cr
#'  A vector of \code{mlr3superlearner} algorithms
#'  for estimation of the outcome regressions. Default is \code{"glm"}, a main effects GLM.
#' @param nn_module [\code{function}]\cr A function that returns a neural network module.
#' @param control [\code{ria.test.control}]\cr
#'  Control parameters for the estimation procedure. Use \code{ria.test.control()} to set these values.
#'
#' @return A \code{ria.test} object containing \eqn{TE}, \eqn{TE^R},
#'   \eqn{TE - TE^R}, \eqn{NIE^R}, and \eqn{NDE^R}, along with the matched call.
#'
#' @importFrom checkmate assert_data_frame assert_function assert_numeric
#'
#' @export
#'
#' @example inst/examples/examples.R
ria.test <- function(data,
										trt,
										outcome,
										mediators,
										pre,
										post,
										obs = NULL,
										id = NULL,
										d0 = NULL,
										d1 = NULL,
										weights = rep(1, nrow(data)),
										learners = "glm",
										nn_module = sequential_module(),
										control = ria.test.control()) {

	# Perform initial checks
	assert_data_frame(data[, c(trt, outcome, mediators, pre, post, obs, id)])
	assert_not_missing(data, trt, pre, mediators, post, obs)
	assert_function(d0, nargs = 2, null.ok = TRUE)
	assert_function(d1, nargs = 2, null.ok = TRUE)
	assert_function(nn_module)
	assert_binary_0_1(data, outcome)
	assert_binary_0_1(data, obs)
	checkmate::assert_character(post, min.len = 1L, any.missing = FALSE)
	assert_numeric(weights, len = nrow(data), finite = TRUE, any.missing = FALSE)

	weights <- normalize(weights)

	params <- estimation_parameters

	# Create ria.test data object
	cd <- ria.test_data(
		data = data,
		vars = ria.test_vars(
			A = trt,
			Y = outcome,
			M = mediators,
			Z = post,
			W = pre,
			C = obs %??% NA_character_,
			id = id %??% NA_character_
		),
		weights = weights,
		d0 = d0,
		d1 = d1
	)

	# Create the independent post-treatment-confounder draw used by RIAs.
	if (length(params$randomized) > 0) {
		cd <- add_zp(cd, control)
	}

	# Create folds for cross fitting
	folds <- make_folds(cd@data, control$crossfit_folds, cd@vars@id, cd@vars@Y)

	# Estimate \theta nuisance parameters
	thetas <- estimate_theta(cd, folds, params, learners, control)

	# Initialize Torch only after all R-randomized steps are complete.
	control$device <- torch::torch_device(control$device)
	if (!is.null(control$torch_seed)) {
		torch::torch_manual_seed(control$torch_seed)
	}

	# Estimate density ratios, alpha natural
	alpha_ns <- estimate_phi_n_alpha(cd, folds, params, nn_module, control)
	eif_ns <- calc_eifs(cd, alpha_ns, thetas, eif_n)

	# Estimate density ratios, alpha randomized
	alpha_rs <- estimate_phi_r_alpha(cd, folds, params, nn_module, control)
	eif_rs <- calc_eifs(cd, alpha_rs, thetas, eif_r)

	# Estimates ---------------------------------------------------------------

	out <- list(
		estimates = calculate_estimates(eif_ns, eif_rs),
		call = match.call()
	)

	class(out) <- "ria.test"
	out
}
