
# Filter, Map, and Reduce

The last chapter covered some pieces of functional programming that can be hard to wrap your head around, but this chapter will be much simpler. We will just look at three general methods that are used in functional programming instead of loops, and instead of explicitly writing recursive functions. They are really three different patterns for computing on sequences, and they come in different flavours in different functions, but just these three lets you do almost anything you would otherwise do with loops.

Note the *almost* above. These three functions do not replace *everything* you can do with loops. You can replace `for`-loops, where you already know how much you are looping over, but they cannot substitute `while`- and `repeat`-loops. Still, by far the most loops you write in R are `for`-loops, and in general, you can use these functions to replace those.

The functions, or patterns, are `Filter`, `Map`, and `Reduce`. The first takes a sequence and a predicate, a function that returns a boolean value, and it returns a sequence where all elements where the predicate was true are included, and the rest are removed. The second, `Map`, evaluates a function on each item in a sequence and returns a sequence with the results of evaluating the function. It is similar to the `sapply` function we briefly saw in the previous chapter. The last, `Reduce`, takes a sequence and a function and evaluates the function repeatedly to reduce the sequence to a single value. This pattern is also called "fold" in some programming languages.

 


## The general sequence object in R is a list

Sequences come in two flavours in R, vectors and lists. Vectors can only contain basic types and all elements in a vector must have the same type. Lists can contain a sequence of any type and the elements in a list can have different types. Lists are thus more general than vectors and are often the building blocks of data structures such as the "next lists" and the trees we have used earlier in the book.

It, therefore, comes as no surprise that general functions for working on sequences would work on lists. The three functions, `Filter`, `Map`, and `Reduce` are also happy to take vectors, but they are treated just as if you explicitly converted them to lists first. The `Reduce` function returns a value, so not a sequence, of a type that depends on its input, while `Filter` and `Map` both return sequences in the form of a list.

From a programming perspective, it is just as easy to work with lists as it is to work with vectors, but some functions do expect vectors -- plotting functions and functions for manipulating data frames for example -- so sometimes you will have to translate a list from `Filter` or `Map` into a vector. You can do this with the function `unlist`. This function will convert a list into a vector when this is possible, that is when all elements are of the same basic type, and otherwise will just give you the list back. I will use `unlist` in many examples in this chapter just because it makes the output nicer to look at, but in most programs, I do not bother doing so until I really need a vector. A list is just as good for storing sequences.

It is just that 

```{r}
list(1, 2, 3, 4)
```

gives us much longer output listings to put in the book than

```{r}
1:4
```

If you follow along in front of your compute you can try to see the results with and without `unlist` to get a feeling for the differences.

You rarely need to convert sequences the other way, from vectors to lists. Functions that work on lists usually also work on vectors, but if you want to you should use the `as.list` function and not the `list` function. The former gives you a list with one element per element in the vector

```{r}
as.list(1:4)
```

whereas the latter gives you a list with a single element that contains the vector

```{r}
list(1:4)
```

## Filtering sequences

The `Filter` function is the simplest of the three main functions we cover in this chapter. It simply selects a subset of a sequence based on a predicate. A predicate is a function that returns a single boolean value, and `Filter` will return a list of elements where the predicate returned `TRUE` and discard the elements where the predicate returned `FALSE`.

```{r}
is_even <- function(x) x %% 2 == 0
unlist(Filter(is_even, 1:10))
```

The function is often used together with closures so the predicate can depend on local variables

```{r}
larger_than <- function(x) function(y) y > x
unlist(Filter(larger_than(5), 1:10))
```

and of course works with the `curry` functions we wrote earlier

```{r, echo=FALSE}
curry2 <- function(f) function(x) function(y) f(x, y)
```
```{r}
unlist(Filter(curry2(`<`)(5), 1:10))
unlist(Filter(curry2(`>=`)(5), 1:10))
```

Using `curry2` with a binary operator like here can look a little confusing, though. We have the left-hand-side of the operator immediately to the right of the operator, so the casual reader would expect `curry2(`\<`)(5)` to pick numbers less than five while in fact it does the opposite since `curry2(`\<`)(5)` translates to `function(y) 5 < y`. We can easily fix this by reversing the order of arguments in the curry function:

```{r}
rcurry2 <- function(f) function(y) function(x) f(x, y)
unlist(Filter(rcurry2(`>=`)(5), 1:10))
unlist(Filter(rcurry2(`<`)(5), 1:10))
```

Here we have used a vector as input to `Filter`, but any list will do and we do not need to limit it to sequences of the same type.

```{r}
s <- list(a = 1:10, b = list(1,2,3,4,5,6), 
          c = y ~ x1 + x2 + x3, d = vector("numeric"))
Filter(function(x) length(x) > 5, s)
```

When printed, the result isn't pretty, but we can't solve that with `unlist` in this case. Using `unlist` we *would* get a vector, but not remotely one reflecting the structure of the result, the vector `a` and list `b` would be flattened into a single vector.


## Mapping over sequences

The `Map` function evaluates a function for each element in a list and returns a list with the results.

```{r}
unlist(Map(is_even, 1:5))
```

As with `Filter`, `Map` is usually combined with closures

```{r}
add <- function(x) function(y) x + y
unlist(Map(add(2), 1:5))
unlist(Map(add(3), 1:5))
```

and can be applied on lists of different types

```{r}
s <- list(a = 1:10, b = list(1,2,3,4,5,6), 
          c = y ~ x1 + x2 + x3, d = vector("numeric"))
unlist(Map(length, s))
```

`Map` can be applied to more than one sequences if the function you provide it takes a number of parameters that matches the number of sequences:

```{r}
unlist(Map(`+`, 1:5, 1:5))
```

In this example we use the function ```+```, which takes two arguments, and we give the `Map` function two sequences, so the result is the component-wise addition.

You can pass along named parameters to a `Map` call, either directly as a named parameter


```{r}
x <- 1:10
y <- c(NA, x)
s <- list(x = x, y = y)
unlist(Map(mean, s))
unlist(Map(mean, s, na.rm = TRUE))
```

or as a list provided to the `MoreArgs` parameter.

```{r}
unlist(Map(mean, s, MoreArgs = list(na.rm = TRUE)))
```

For a single value, the two approaches work the same, but their semantics is slightly different, which comes into play when providing arguments that are sequences. Providing a named argument directly to `Map` works just as providing an unnamed argument (except that you can pick a specific variable by name instead of by position), so `Map` assumes that you want to apply your function to every element of the argument. The reason this works with a single argument is that, as R generally does, the shorter sequence is repeated as many times as needed. With a single argument that is exactly what we want, but it isn’t necessarily with a sequence.

If we want that behaviour we can just use the named argument to `Map` but if we want the function to be called with the entire sequence each time it is called we must put the sequence as an argument to the `MoreArgs` parameter.

As an example we can consider our trusted friend the `scale` function and make a version where a vector, `x`, is scaled by the mean and standard deviation of another vector, `y`.

```{r}
scale <- function(x, y) (x - mean(y))/sd(y)
```

If we just provide `Map` with two arguments for `scale` it will evaluate all pairs independently (and we will get a lot of `NA` values because we are calling the `sd` function on a single value.

```{r}
unlist(Map(scale, 1:10, 1:5))
```

The same happens if we name parameter `y`

```{r}
unlist(Map(scale, 1:10, y = 1:5))
```

but if we use `MoreArgs` the entire vector `y` is provided to `scale` in each call.

```{r}
unlist(Map(scale, 1:10, MoreArgs = list(y = 1:5)))
```

Just as `Filter`, `Map` is not restricted to work on vectors, so we can map over arbitrary types as long as our function can handle the different types.

```{r}
s <- list(a = 1:10, b = list(1,2,3,4,5,6), 
          c = y ~ x1 + x2 + x3, d = vector("numeric"))
unlist(Map(length, s))
```


## Reducing sequences

While `Filter` and `Map` produces lists, the `Reduce` function transforms a list into a value. Of course, that value can also be a list, lists are also values, but `Reduce` doesn’t simply process each element in its input list independently. Instead, it summarises the list by applying a function iteratively to pairs. You provide it a function, `f` of two elements, and it will first call `f` on the first two elements in the list. Then it will take the result of this and call `f` with this and the next element, and continue doing that through the list.

So calling `Reduce(f, 1:5)` will be equivalent to calling

```r
f(f(f(f(1, 2), 3), 4), 5)
```

It is just more readable to write `Reduce(f, 1:5)`.

We can see it in action using `` `+` `` as the function:

```{r}
Reduce(`+`, 1:5)
 ```

You can also get the accumulative results back by using the parameter `accumulate`. This will return a list of all the calls to `f` and include the first value in the list, so `Reduce(f, 1:5)` will return the list

```r
c(1, f(1, 2), f(f(1 ,2), 3), f(f(f(1, 2), 3), 4), 
   f(f(f(f(1, 2), 3), 4), 5))
```

So for addition we get:

```{r}
Reduce(`+`, 1:5, accumulate = TRUE)
```

By default `Reduce` does its computations from left to right, but by setting the option `right` to `TRUE` you instead get the results from right to left.

```{r}
Reduce(`+`, 1:5, right = TRUE, accumulate = TRUE)
```

For an associative operation like `` `+` ``, this will, of course, be the same result if we do not ask for the accumulative function calls.

In many functional programming languages, which all have this function although it is sometimes called `fold` or `accumulate`, you need to provide an initial value for the computation. This is then used in the first call to `f`, so the folding instead starts with `f(init, x[1])` if `init` refers to the initial value and `x` is the sequence.

You can also get that behaviour in `R` by explicitly giving `Reduce` an initial value through parameter `init`:

```{r}
Reduce(`+`, 1:5, init = 10, accumulate = TRUE)
```

You just don’t need to specify this initial value that often. In languages that require it, it is used to get the right starting points when accumulating results. For addition, we would use zero as an initial value if we want `Reduce` to compute a sum because adding zero to the first value in the sequence would just get us the first element. For multiplication, we would instead have to use one as the initial value since that is how the first function application will just give us the initial value.

In R we don’t need to provide these initial values if we are happy with just having the first function call be on the first two elements in the list, so multiplication works just as well as addition without providing `init`:

```{r}
Reduce(`*`, 1:5)
Reduce(`*`, 1:5, accumulate = TRUE)
Reduce(`*`, 1:5, right = TRUE, accumulate = TRUE)
```

You wouldn’t normally use `Reduce` for summarising values as their sum or product, there are already functions in R for this (`sum` and `prod`, respectively), and these are much faster as they are low-level functions implemented in C while `Reduce` has to be high level to handle arbitrary functions. For more complex data where we do not already have a function to summarise a list, `Reduce` is often the way to go.

Here is an example taken from Hadley Wickham’s *Advanced R* book:

```{r}
samples <- replicate(3, sample(1:10, replace = TRUE), 
                                     simplify = FALSE)
str(samples)
Reduce(intersect, samples)
```

We have a list of three vectors each with ten samples of the numbers from one to ten, and we want to get the intersection of these three lists. That means taking the intersection of the first two and then taking the intersection of that result and the third list. Perfect for `Reduce`. We just combine it with the `intersection` function.


## Bringing the functions together

The three functions are often used together, where `Filter` first gets rid of elements that should not be processed, then `Map` processes the list, and finally `Reduce` combines all the results. 

```{r, echo=FALSE}
make_node <- function(name, left = NULL, right = NULL) 
  list(name = name, left = left, right = right)

print_tree <- function(tree) {
  build_string <- function(node) {
    if (is.null(node$left) && is.null(node$right)) {
        node$name
    } else {
        left <- build_string(node$left)
        right <- build_string(node$right)
        paste0("(", left, ",", right, ")")
    }
  }
  build_string(tree)
}

size_of_tree <- function(node) {
  if (is.null(node$left) && is.null(node$right)) {
    size <- 1
  } else {
    left_size <- size_of_tree(node$left)
    right_size <- size_of_tree(node$right)
    size <- left_size + right_size + 1
  }
  size
}
```

In this section, we will see a few examples of how we can use these functions together. We start with processing trees. Remember that we can construct trees using the `make_node` function we wrote earlier, and we can, of course, create a list of trees.

```{r}
A <- make_node("A")
C <- make_node("C", make_node("A"), 
                    make_node("B"))
E <- make_node("E", make_node("C", make_node("A"), make_node("B")),
                    make_node("D"))

trees <- list(A = A, C = C, E = E)
```

Printing a tree gives us the list representation of it, if we `unlist` a tree we get the same representation, just flattened, so the structure is shown in the names of the resulting vector, but we wrote a `print_tree` function that gives us a string representation in Newick format.

```{r}
trees[[2]]
unlist(trees[[2]])
print_tree(trees[[2]])
```

We can use `Map` to translate a list of trees into their Newick format and flatten this list to just get a vector of characters.

```{r}
Map(print_tree, trees)
unlist(Map(print_tree, trees))
```

We can combine this with `Filter` to only get the trees that are not single leaves, here we can use the `size_of_tree` function we wrote earlier

```{r}
unlist(Map(print_tree, 
                   Filter(function(tree) size_of_tree(tree) > 1, trees)))
```

or we can get the size of all trees and compute their sum by combining `Map` with `Reduce`

```{r}
unlist(Map(size_of_tree, trees))
Reduce(`+`, Map(size_of_tree, trees), 0)
```

We can also search for the node depth of a specific node and for example get the depth of “B” in all the trees:

```{r, echo=FALSE}
node_depth <- function(tree, name, depth = 0) {
  if (is.null(tree))     return(NA)
  if (tree$name == name) return(depth)
  
  left <- node_depth(tree$left, name, depth + 1)
  if (!is.na(left)) return(left)
  right <- node_depth(tree$right, name, depth + 1)
  return(right)
}
```

```{r}
node_depth_B <- function(tree) node_depth(tree, "B")
unlist(Map(node_depth_B, trees))
```

The names we get in the result are just confusing, they refer to the names we gave the trees when we constructed the list, and we can get rid of them by using the parameter `use.names` in `unlist`. In general, if you don’t need the names of a vector you should always do this, it speeds up computations when R doesn’t have to drag names along with the data you are working on.

```{r}
unlist(Map(node_depth_B, trees), use.names = FALSE)
```

For trees that do not have a “B” node we get `NA` when we search for the node depth, and we can easily remove those using `Filter`

```{r}
Filter(function(x) !is.na(x), 
       unlist(Map(node_depth_B, trees), use.names = FALSE))
```

or we can explicitly check if a tree has node “B” before we `Map` over the trees

```{r}
has_B <- function(node) {
  if (node$name == "B") return(TRUE)
  if (is.null(node$left) && is.null(node$right)) return(FALSE)
  has_B(node$left) || has_B(node$right)
}
unlist(Map(node_depth_B, Filter(has_B, trees)), use.names = FALSE)
```

The solution with filtering after mapping is probably preferable since we do not have to remember to match the `has_B` with `node_depth_B` if we replace them with general functions that handle arbitrary node names, but either solution will work.

## The apply family of functions

The `Map` function is a general solution for mapping over elements in a list, but R has a whole family of `Map`-like functions that operate on different types of input. These are all named “something”-apply, and we have already seen `sapply` in the previous chapter. The `Map` function is actually just a wrapper around one of these, the function `mapply`, and since we have already seen `Map` in use I will not also discuss `mapply`, but I will give you a brief overview of the other functions in the apply family.

### `sapply`, `vapply`, and `lapply`

The functions `sapply`, `vapply`, and `lapply` all operate on sequences. The difference is that `sapply` tries to *simplify* its output, `vapply` takes a value as an argument and will coerce its output to have the type of this value, and give an error if it cannot, and `lapply` maps over lists.

Using `sapply` is convenient for interactive sessions since it essentially works like `Map` combined with `unlist` when the result of a map can be converted into a vector. Unlike `unlist` it will not flatten a list, though, so if the result of a map is more complex than a vector, `sapply` will still give you a list as its result. Because of this, `sapply` can be dangerous to use in a program. You don’t necessarily know which type the output will have so you have to program defensively and check if you get a vector or a list.

```{r}
sapply(trees, size_of_tree)
sapply(trees, identity)
```

Using `vapply` you get the same simplification as using `sapply` if the result can be transformed into a vector, but you have to tell the function what type the output should have. You do this by giving it an example of the desired output. If `vapply` cannot translate the result into that type, you get an error instead of a type of a different type, making the function safer to use in your programming. After all, getting errors is better than unexpected results due to type-confusion.

```{r}
vapply(trees, size_of_tree, 1)
```

The `lapply` is the function most similar to `Map`. It takes a list as input and returns a list. The main difference between `lapply` and `Map` is that `lapply` always operate on a *single* list, while `Map` can take multiple lists (which explains the name of `mapply`, the function that `Map` is a wrapper for).

```{r}
lapply(trees, size_of_tree)
```

### The `apply` function

The `apply` function works on matrices and higher-dimensional arrays instead of sequences. It takes three parameters, plus any additional parameters that should just be passed along to the function called. The first parameter is the array to map over, the second which dimension(s) we should marginalise along, and the third the function we should apply. 

We can see it in action by creating a matrix to apply over

```{r}
(m <- matrix(1:6, nrow=2, byrow=TRUE))
```

To see what is actually happening we will create a function that collects the data that it gets so we can see exactly what it is called with

```{r}
collaps_input <- function(x) paste(x, collapse = ":")
```

If we marginalise on rows it will be called on each of the two rows and the function will be called with the entire row vectors

```{r}
apply(m, 1, collaps_input)
```

If we marginalise on columns it will be called on each of the three columns and produce tree strings:

```{r}
apply(m, 2, collaps_input)
```

If we marginalise on both rows and columns it will be called on each single element instead:

```{r}
apply(m, c(1, 2), collaps_input)
```

### The `tapply` function

The `tapply` function works on so-called ragged tables, tables where the rows can have different lengths. You cannot directly make an array with different sizes of dimensions in rows, but you can use a flat vector combined with factors that indicate which virtual dimensions you are using. The `tapply` function groups the vector according to a factor and then calls its function with each group.

```{r}
(x <- rnorm(10))
(categories <- sample(c("A", "B", "C"), size = 10, replace = TRUE))
tapply(x, categories, mean)
```

You can use more than one factor if you wrap the factors in a list:

```{r}
(categories2 <- sample(c("X", "Y"), size = 10, replace = TRUE))
tapply(x, list(categories, categories2), mean)
```
## Functional programming in `purrr `

The `Filter`, `Map`, and `Reduce` functions are the building blocks of many functional algorithms, in addition to recursive functions. However, many common operations require various combinations of the three functions, and combinations with `unlist`, so writing functions using *only* these three/four functions means building functions from the most basic building blocks. This is not efficient, so you want to have a toolbox of more specific functions for common operations.

The package [`purrr`](https://github.com/hadley/purrr) implements a number of such functions for more efficient functional programming, in addition to its own versions of `Filter`, `Map`, and `Reduce`. A complete coverage of the `purrr` package is beyond the scope of this book but I will give a quick overview of the functions available in the package and urge you to explore the package more if you are serious in using functional programming in R.

```{r}
library(purrr)
```

The functions in `purrr` all take the sequence they operate on as their first argument — similar to the apply family of functions but different from the `Filter`, `Map`, and `Reduce` functions.

### `Filter`-like functions

The `purrr` analogue of `Filter` is called `keep` and works exactly like `Filter`. It takes a predicate and returns a list of the elements in a sequence where the predicate returns `TRUE`. The function `discard` works similarly but returns the elements where the predicate returns `FALSE`.

```{r}
keep(1:5, rcurry2(`>`)(3))
discard(1:5, rcurry2(`>`)(3))
```

If you give these functions a vector you get a vector back, of the same type, and if you give them a list you will get a list back

```{r}
keep(as.list(1:5), rcurry2(`>`)(3))
```

Two convenience functions that you could implement by checking the length of the list returned by `Filter`, are `every` and `some`, that checks if all elements in the sequence satisfy the predicate or if some elements satisfy the predicate.

```{r}
every(1:5, rcurry2(`>`)(0))
every(1:5, rcurry2(`>`)(3))
some(1:5, rcurry2(`>`)(3))
some(1:5, rcurry2(`>`)(6))
```

In the examples here I have used the `rcurry2` function we defined earlier, but with `purrr` it is very easy to write anonymous functions in a less verbose way than the typical R functions. You can use the “formula notation” and define an anonymous function by writing `~` followed by the body of the function, where the function argument is referred to by the variable `.x`.

```{r}
keep(1:5, ~ .x > 3)
discard(1:5, ~ .x > 3)
```

This short-hand for anonymous functions is only available within functions from `purrr`, though. Just because you have imported the `purrr` package, you will not get the functionality in other functions.

### `Map`-like functions

The `Map` functionality comes in different flavours in `purrr`, depending on the type of output you want and the number of input sequences you need to map over.

The `map` function always returns a list while functions `map_lgl`, `map_int`, `map_dbl`, and `map_chr` return vectors of logical values, integer values, numeric (double) values, and characters, respectively.

```{r}
map(1:5, ~ .x + 2)
map_dbl(1:5, ~ .x + 2)
```

The `map` family of functions all take a single sequence as input, but there are corresponding functions for two sequences, the `map2`, family and for an arbitrary number of sequences, the `pmap` family.

For the `map2` functions you can create anonymous functions that refer to the two input values they will be called with by using variables `.x` and `.y`.

```{r}
map2(1:5, 6:10, ~ 2 * .x + .y)
map2_dbl(1:5, 6:10, ~ 2 * .x + .y)
```

For arbitrary numbers of sequences, you must use the `pmap` family and wrap the sequences in a list that is given as the first parameter. If you use anonymous functions you will need to define them using the general R syntax; there are no shortcuts for specifying anonymous functions with three or more parameters.

```{r}
pmap(list(1:5, 6:10, 11:15), 
     function(x, y, z) x + y + z)
pmap_dbl(list(1:5, 6:10, 11:15),
         function(x, y, z) x + y + z)
```

The function `map_if` provides a variation of `map` that only applies the function it is mapping if a predicate is `TRUE`. If the predicate returns `FALSE` for an element, that element is kept unchanged.

For example, we can use it to multiply only numbers that are not even by two like this:

```{r}
unlist(map_if(1:5, ~ .x %% 2 == 1, ~ 2*.x))
```

A particularly nice feature of `purrr`’s map functions is that you can provide them with a string instead of a function and this is used, when you are working with sequences of elements that have names, like data frames and lists, to extract named components. So if we map over the trees from earlier we can, for example, use `map` to extract the left child of all the trees

```{r}
map_chr(map(keep(trees, ~ size_of_tree(.x) > 1), "left"),
        print_tree)
```

Here we combine three different functions: we use `keep` so we only look at trees that actually *have* a left child. Then we use `map` with `"left"` to extract the left child, and finally, we use `map_chr` to translate the trees into Newick format for printing.

### `Reduce`-like functions

The `Reduce` function is implemented in two different functions, `reduce` and `reduce_right`. 

```{r}
reduce(1:5, `+`)
reduce_right(1:5, `*`)
```

