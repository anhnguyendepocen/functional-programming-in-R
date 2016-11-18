
(x <- rnorm(10))
(categories <- sample(c("A", "B", "C"), size = 10, replace = TRUE))
tapply(x, categories, mean)

(categories2 <- sample(c("X", "Y"), size = 10, replace = TRUE))
tapply(x, list(categories, categories2), mean)
