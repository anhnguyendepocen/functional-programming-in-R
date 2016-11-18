Reduce(`+`, 1:5)
Reduce(`+`, 1:5, accumulate = TRUE)
Reduce(`+`, 1:5, right = TRUE, accumulate = TRUE)

Reduce(`*`, 1:5)
Reduce(`*`, 1:5, accumulate = TRUE)
Reduce(`*`, 1:5, right = TRUE, accumulate = TRUE)

Reduce(`+`, 1:5, init = 10, accumulate = TRUE)

samples <- replicate(3, sample(1:10, replace = TRUE), simplify = FALSE)
str(samples)
Reduce(intersect, samples)
