#' ria.test control parameters
#'
#' @param crossfit_folds [\code{numeric(1)}]\cr The number of crossfit folds.
#' @param mlr3superlearner_folds [\code{numeric(1)}]\cr The number of `mlr3superlearner` folds.
#' @param zprime_folds [\code{numeric(1)}]\cr The number of folds to split that data into for calculating Z'.
#'	With larger sample sizes, a larger number will increase speed.
#' @param epochs [\code{numeric(1)}]\cr The number of epochs to train the neural network.
#' @param learning_rate [\code{numeric(1)}]\cr The learning rate for the neural network.
#' @param batch_size [\code{numeric(1)}]\cr The batch size for mini-batch gradient descent.
#' @param device [\code{character(1)}]\cr Object representing the device on which a \code{torch_tensor} is or will be allocated.
#' @param torch_seed [\code{integer(1)}]\cr Optional seed for Torch's random-number
#'   generator. This controls neural-network initialization and dropout but does
#'   not affect R's random-number generator. Use \code{set.seed()} separately to
#'   control R-level randomness.
#'
#' @return A list of control parameters
#' @export
#'
#' @examples
#' if (torch::torch_is_installed()) ria.test.control(crossfit_folds = 5)
ria.test.control <- function(
	crossfit_folds = 10L,
	mlr3superlearner_folds = 10L,
	zprime_folds = 1L,
	epochs = 100L,
	learning_rate = 0.01,
	batch_size = 64,
	device = c("cpu", "cuda", "mps"),
	torch_seed = NULL
) {
	checkmate::assert_number(crossfit_folds)
	checkmate::assert_number(mlr3superlearner_folds)
	checkmate::assert_number(zprime_folds)
	checkmate::assert_number(epochs)
	checkmate::assert_number(learning_rate)
	checkmate::assert_number(batch_size)
	checkmate::assert_character(match.arg(device), len = 1)
	checkmate::assert_integerish(
		torch_seed,
		len = 1L,
		lower = 0,
		upper = .Machine$integer.max,
		null.ok = TRUE
	)
	if (!is.null(torch_seed)) torch_seed <- as.integer(torch_seed)
	list(
		crossfit_folds = crossfit_folds,
		mlr3superlearner_folds = mlr3superlearner_folds,
		zprime_folds = zprime_folds,
		epochs = epochs,
		learning_rate = learning_rate,
		batch_size = as.numeric(batch_size),
		device = match.arg(device),
		torch_seed = torch_seed
	)
}
