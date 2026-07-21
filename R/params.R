total_effect_parameters <- list(
	c(j = "data_1", k = "data_1", l = "data_1"),
	c(j = "data_0", k = "data_0", l = "data_0")
)

ria_parameters <- list(
	c(i = "data_1zp", j = "data_1", k = "data_0", l = "data_0"),
	c(i = "data_0zp", j = "data_0", k = "data_0", l = "data_0"),
	c(i = "data_1zp", j = "data_1", k = "data_1", l = "data_1")
)

estimation_parameters <- list(
	natural = total_effect_parameters,
	randomized = ria_parameters
)
