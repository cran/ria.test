#' @importFrom cli cli_div cli_rule cli_end cli_h3
#' @importFrom purrr iwalk
#' @export
print.ria.test <- function(x, ...) {
	cat("\n")
	d <- cli_div(theme = list(rule = list("line-type" = "double")))
	cli_rule(left = "Results {.fn ria.test}")
	cli_end(d)
	iwalk(x$estimates, print_estimate)
	invisible(x)
}

print_estimate <- function(x, name) {
	title <- c(
		TE = "Total Effect (TE)",
		NIE = "Natural Indirect Effect (NIE)",
		NDE = "Natural Direct Effect (NDE)",
		"TE^R" = "Randomized Interventional Total Effect (TE^R)",
		"NIE^R" = "Randomized Interventional Indirect Effect (NIE^R)",
		"NDE^R" = "Randomized Interventional Direct Effect (NDE^R)",
		"TE - TE^R" = "Falsification Contrast (TE - TE^R)"
	)[[name]]
	cli_h3("{.emph {title}}")

	est <- round(x@x, digits = 6)
	se <- round(x@std_error, digits = 6)
	ci <- round(x@conf_int, digits = 6)

	cat(sprintf("Estimate: %.6f\n", est))
	cat(sprintf("Std. Error: %.6f\n", se))
	cat(sprintf("95%% CI: [%.6f, %.6f]\n", ci[1], ci[2]))
	if (identical(name, "TE - TE^R")) {
		p_value <- 2 * stats::pnorm(-abs(x@x / x@std_error))
		cat(sprintf("P-value: %s\n", format.pval(p_value, digits = 4)))
	}
}
