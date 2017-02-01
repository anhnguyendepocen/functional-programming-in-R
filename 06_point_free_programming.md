
# Point-free Programming

In this last chapter we will not so much discuss actual programming but a programming style called *point free programming* (not *pointless* programming), that is characterised by constructing functions through a composition of other functions and not by actually writing new functions.

A lot of computing can be expressed as the steps that data flow through and how data is transformed along the way. We write functions to handle all the most basic steps, the atoms of a program and then construct functions for more complex operations by combining more fundamental transformations, building program molecules from the program atoms.

The term *point free* refers to the intermediate states data can be in when computing a sequence of transformations. The *points* it refers to are the states the data is in after each transformation, and *point free* means that we do not focus on these points in any way. They are simply not mentioned anywhere in code written using point free programming.

This might all sound a bit abstract but if you are used to writing pipelines in shell scripts it should soon become very familiar because point free programming is exactly what you do when you write a pipeline. There, data flow through a number of programs, tied together, so the output of one program becomes the input for the next in the pipeline, and you never refer to the intermediate data, only the steps of transformations the data go through as it is processed by the pipeline.

## Function composition

The simplest way to construct new functions from basic ones is through function composition. In mathematics, if we have a function, $f$, mapping from domain $A$ to domain $B$, which we can write as $f: A \\to B$, and another function $g$, $g: A \\to C$, we can create a new function $h: A \\to C$ by composing the two: $h(x) = g(f(x))$.

We can do exactly the same thing in R and define `h` in terms of functions `f` and `g` like this:

```r
h <- function(x) g(f(x))
```

or even more verbose

```r
h <- function(x) {
  y <- f(x)
  g(y)
}
```

Either way, there is a lot of extra fluff in writing a new function explicitly just to combine two other functions. In mathematical notation, we don’t write the combination of two functions that way. We write the function composition as $h = g \\circ f$. Composing functions to define new functions, rather than defining functions that just explicitly call others, is what we call point-free programming, and it is easily done in R.

We can write a function composition function, a higher-order function that takes two functions as arguments and returns their composition.

```{r}
compose <- function(g, f) function(...) g(f(...))
```

We can then use this function to handle a common case when we are using `Map` and frequently want to `unlist` the result: 

```{r, echo=FALSE}
curry2 <- function(f) function(x) function(y) f(x, y)
```
```{r}
umap <- compose(unlist, Map)
umap(curry2(`+`)(2), 1:4)
```

To get something similar to the mathematical notation we want it to be an infix operator, but the package `pryr` has already defined it for us so we can write the same code as this:

```{r}
library(pryr)
umap <- unlist %.% Map
umap(curry2(`+`)(2), 1:4)
```

We are not limited to only composing two functions, and since function composition is associative we don’t need to worry about the order in which they are composed, and so we don’t need to use parentheses around compositions. We can combine three or more functions as well, and we can combine functions with anonymous functions if we need some extra functionality that isn’t already implemented as a named function. For example, we could define a function for computing the root mean square error like this:

```{r}
rmse <- sqrt %.% mean %.% function(x, y) (x - y)**2
rmse(1:4, 2:5)
```

We need a new function for computing the squared distance between `x` and `y`, so we add an anonymous function for that, but then we can just use `mean` and `sqrt` to get the rest of the functionality.

In the mathematical notation for function composition you always write the functions you compose in the same order as you would write them if you explicitly called them, so $h \\circ g \\circ f$ would be evaluated on a value $x$ as $h(g(f(x)))$. This is great if you are used to reading from right to left, but if you are used to reading left to right it is a bit backwards.

Of course, nothing prevents us from writing a function composition operator that reverses the order of the functions. To avoid confusion with the mathematical notation for function composition, we would use a different operator so we could define $;$ such that $f;g = g \\circ f$ and in R use that for function composition:

```{r}
`%;%` <- function(f, g) function(...) g(f(...))
rmse <- (function(x, y) (x - y)**2) %;% mean %;% sqrt
rmse(1:4, 2:5)
```

Here I need parentheses around the anonymous function to prevent R from considering the composition as part of the function body, but otherwise, the functionality is the same as before, we can just read the composition from left to right.

## Pipelines

The `magrittr` package already implements a “left-to-right” function composition as the operator `%>%`. The `magrittr` package aims at making pipelines of data analysis simpler. It allows you to chain together various data transformations and analyses in ways very similar to how you chain together command-line tools in shell pipelines. The various operations are function calls, and these functions are chained together with the `%>%` operator, moving the output of one function to the input of the next.

For example, to take the vector `1:4`, get the `mean` of it, and then take the `sqrt`, you can write a pipeline like this:

```{r}
library(magrittr)
1:4 %>% mean %>% sqrt
```

The default is that the output from the previous step in the pipeline is passed as the first argument to the next function in the pipeline. To write your own functions to fit into this pattern, you just need to make the data that come through a pipeline is the first argument for your function. Because `magrittr` pipelines are now frequently used in R, this is the pattern that most functions follow, and it is used in popular packages like `dplyr` and `tidyr`. The `purrr` package is also designed to work well with `magrittr` pipelines. All its functions take the data they operate on as their first parameter, so stringing together several transformations using `%>%` is straightforward. 

Not all functions follow the pattern, mostly older functions do not, but you can use the variable “`.`” to refer to the data being passed along the pipeline when you need it to go at a different position than the first.

```r
data.frame(x = 1:4, y = 2:5) %>% plot(y ~ x, data = .)
```

If the input is a data frame, you can access its columns using the column names as you would with any other data frame, the argument is still “`.`” and you just need to use that parameter to refer to the data.

```r
data.frame(x = 1:4, y = 2:5) %>% plot(.$x, .$y)
```

The “`.`” parameter can be used several times in a function call in the pipeline and can be used together with function calls in a pipeline, e.g.:

```{r}
rnorm(4) %>% data.frame(x = ., y = cos(.))
```

There is one caveat, though, if “`.`” *only* appears in function calls, it will *also* be given to the function as a first parameter. This means that code such as the example below will create a data frame with three variables, the first being a column named “`.`”.

```{r}
rnorm(4) %>% data.frame(x = sin(.), y = cos(.))
```


While the package is mainly intended for writing such data processing pipelines, it can also be used for defining new functions by composing other functions, this time with the functions written in left-to-right order. You write such functions just as you would write data processing pipelines, but let the first step in the pipeline be “`.`”, so this is a data pipeline

```{r}
mean_sqrt <- 1:4 %>% mean %>% sqrt
mean_sqrt
```

while this is a function

```{r}
mean_sqrt <- . %>% mean %>% sqrt
mean_sqrt(1:4)
```

which of course is a function that you can use in a pipeline

```{r}
1:4 %>% mean_sqrt
```

You can only use this approach to define functions taking a single argument as input. If you need more than one argument, you will need to define your function explicitly. The whole pipeline pattern works by assuming that it is a single piece of data that is passed along between function calls, but nothing prevents you from having complex data, such as data frames, and emulate having more than one argument in this way.

Take for example the root mean square error function we wrote above:

```r
rmse <- (function(x, y) (x - y)**2) %;% mean %;% sqrt
```

This function takes two arguments so we cannot create it using “`.`”. We can instead change it to take a single argument, for example, a data frame, and get the two values from there.

```{r}
rmse <- . %>% { (.$x - .$y)**2 } %>% mean %>% sqrt
data.frame(x = 1:4, y = 2:5) %>% rmse
```

Here we also used another feature of `magrittr`, a less verbose syntax for writing anonymous functions. By writing the expression `{(.$x - .$y)**2}` in curly braces we are making a function, in which we can refer to the argument as "`.`".

Being able to write anonymous functions by just putting expressions in braces is very convenient when the data needs to be massaged just a little to fit the output of one function to the expected input of the next.

Anonymous functions are also the way to prevent the “`.`” parameter getting implicitly passed as the first argument to a function when it is otherwise only used in function calls. If the expression is wrapped in curly braces, then the function call is not modified in any way and so “`.`” is not implicitly added as a first parameter.

```{r}
rnorm(4) %>% { data.frame(x = sin(.), y = cos(.)) }
```

