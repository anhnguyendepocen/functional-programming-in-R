rcurry2 <- function(f) function(y) function(x) f(x, y)
curry2 <- function(f) function(x) function(y) f(x, y)

library(purrr)

## Filter
keep(1:5, rcurry2(`>`)(3))
discard(1:5, rcurry2(`>`)(3))

keep(as.list(1:5), rcurry2(`>`)(3))


every(1:5, rcurry2(`>`)(0))
every(1:5, rcurry2(`>`)(3))
some(1:5, rcurry2(`>`)(3))
some(1:5, rcurry2(`>`)(6))

keep(1:5, ~ .x > 3)
discard(1:5, ~ .x > 3)

keep(as.list(1:5), ~ .x > 3)

## Map

map(1:5, ~ .x + 2)
map_dbl(1:5, ~ .x + 2)

map2(1:5, 6:10, ~ 2 * .x + .y)
map2_dbl(1:5, 6:10, ~ 2 * .x + .y)

pmap(list(1:5, 6:10, 11:15), function(x, y, z) x + y + z)
pmap_dbl(list(1:5, 6:10, 11:15), function(x, y, z) x + y + z)

unlist(map_if(1:5, ~ .x %% 2 == 1, ~ 2*.x))

map_chr(map(keep(trees, ~ size_of_tree(.x) > 1), "left"),
        print_tree)

## Reduce

reduce(1:5, `+`)
reduce_right(1:5, `*`)

## Others

(x <- rnorm(10))
(categories <- sample(c("A", "B", "C"), size = 10, replace = TRUE))
split(x, categories)
