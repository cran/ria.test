calculate_estimates <- function(eif_natural, eif_ria) {
	te <- eif_natural[["111"]] - eif_natural[["000"]]
	te_r <- eif_ria[["1111"]] - eif_ria[["0000"]]
	nie_r <- eif_ria[["1111"]] - eif_ria[["1100"]]
	nde_r <- eif_ria[["1100"]] - eif_ria[["0000"]]

	list(
		TE = te,
		"TE^R" = te_r,
		"TE - TE^R" = te - te_r,
		"NIE^R" = nie_r,
		"NDE^R" = nde_r
	)
}
