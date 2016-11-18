
compose <- function(g, f) function(...) g(f(...))
umap <- compose(unlist, Map)

curry2 <- function(f) function(x) function(y) f(x, y)
umap(curry2(`+`)(2), 1:4)

library(pryr)
umap <- unlist %.% Map
umap(curry2(`+`)(2), 1:4)

rmse <- sqrt %.% mean %.% function(x, y) (x - y)**2
rmse(1:4, 2:5)

`%;%` <- function(f, g) function(...) g(f(...))
rmse <- (function(x, y) (x - y)**2) %;% mean %;% sqrt
rmse(1:4, 2:5)
