# enable usage of <S7_object>@name in package code
#' @rawNamespace if (getRversion() < "4.3.0") importFrom("S7", "@")
#' @importFrom stats na.omit weighted.mean var qnorm dist model.matrix predict setNames
NULL

ria.test_vars <- S7::new_class("ria.test_vars",
  properties = list(
    D = S7::class_character,
    Y = S7::class_character,
    M = S7::class_character,
    L = S7::class_character,
    C = S7::class_character,
    observed = S7::new_property(class = S7::class_character, default = NA_character_),
    id = S7::new_property(class = S7::class_character, default = NA_character_)
  ),
  validator = function(self) {
     if (length(self@Y) != 1) {
      "self@outcome must be length 1"
    } else if (length(self@observed) != 1) {
      "self@observed must be length 1"
    } else if (length(self@id) != 1) {
    	"self@id must be length 1"
    }
  }
)
