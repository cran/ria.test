gendata <- function(n = 1e3) {
	C <- rbinom(n, 1, 0.25)
	d <- rbinom(n, 1, 0.5)
	l <- rbinom(n, 1, plogis(0.25*C + 0.75*d))
	m <- rbinom(n, 1, plogis(0.125*C + 0.5*d - 0.25*l))
	y <- rbinom(n, 1, plogis(-1 + 0.25*C + 0.75*d + 0.25*l + 0.25*m))
	data.frame(
		C = C,
		d = d,
		l = l,
		m = m,
		y = y
	)
}
