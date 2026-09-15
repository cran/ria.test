ria.test_data <- S7::new_class("ria.test_data",
	properties = list(
		data = S7::new_property(S7::class_data.frame),
		vars = S7::new_property(S7::new_class("ria.test_vars")),
		weights = S7::new_property(S7::class_numeric),
		d0 = S7::new_property(S7::class_function, default = NULL),
		d1 = S7::new_property(S7::class_function, default = NULL),
		data_0 = S7::new_property(S7::class_data.frame),
		data_1 = S7::new_property(S7::class_data.frame),
		data_0lp = S7::new_property(S7::class_data.frame),
		data_1lp = S7::new_property(S7::class_data.frame)
	),
	constructor = function(data, vars, weights, d0, d1) {
		if (!no_L(vars)) {
			l_ohe <- one_hot_encode(data, vars@L)
			vars@L <- names(l_ohe)
			data <- data[, !(names(data) %in% vars@L)]
			data <- cbind(data, l_ohe)
		}
		S7::new_object(
			S7::S7_object(),
			data = data,
			vars = vars,
			weights = normalize(weights),
			d0 = d0,
			d1 = d1,
			data_0 = shift_data(data, vars@D, vars@observed, d0),
			data_1 = shift_data(data, vars@D, vars@observed, d1),
			data_0lp = data.frame(),
			data_1lp = data.frame()
		)
	},
	validator = function(self) {
		all_vars <- c(self@vars@D, self@vars@C, self@vars@L, self@vars@M, self@vars@observed, self@vars@Y)
		all_vars <- as.vector(na.omit(all_vars))

		if (!all(all_vars %in% names(self@data))) {
			"self@data must contain all variables in self@vars"
		}
	}
)

training <- S7::new_generic("training", "x")
validation <- S7::new_generic("validation", "x")

S7::method(training, ria.test_data) <- function(x, fold_obj, fold) {
	list(
		data = x@data[fold_obj[[fold]]$training_set, , drop = FALSE],
		data_0 = x@data_0[fold_obj[[fold]]$training_set, , drop = FALSE],
		data_1 = x@data_1[fold_obj[[fold]]$training_set, , drop = FALSE],
		data_0lp = x@data_0lp[fold_obj[[fold]]$training_set, , drop = FALSE],
		data_1lp = x@data_1lp[fold_obj[[fold]]$training_set, , drop = FALSE]
	)
}

S7::method(validation, ria.test_data) <- function(x, fold_obj, fold) {
	list(
		data = x@data[fold_obj[[fold]]$validation_set, , drop = FALSE],
		data_0 = x@data_0[fold_obj[[fold]]$validation_set, , drop = FALSE],
		data_1 = x@data_1[fold_obj[[fold]]$validation_set, , drop = FALSE],
		data_0lp = x@data_0lp[fold_obj[[fold]]$validation_set, , drop = FALSE],
		data_1lp = x@data_1lp[fold_obj[[fold]]$validation_set, , drop = FALSE]
	)
}
