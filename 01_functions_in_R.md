
# Functions in R

In this chapter we cover how to write functions in R. If you already know much of what is covered, feel free to skip ahead. We will discuss the way parameters are passed to functions as "promises", a way of passing parameters known as lazy evaluation. If you are not familiar with that but know how to write functions, you can jump forward to that section. We will also cover how to write infix operators and replacement functions, so if you do not know what those are, and how to write them, you can skip ahead to those sections. If you are new to R functions, continue reading.

## Writing functions in R

You create an R function using the `function` keyword. For example, we can write a function that squares numbers like this:

```{r}
square <- function(x) x**2
```

and use it like this

```{r}
square(1:5)
```

The function we have written takes one argument, `x`, and returns the result `x**2`. The return value of a function is always the last expression evaluated in it. If you write a function with a single expression, you can write it as above, but for more complex functions you will typically need several statements in it. If you do, you can put the body of the function in curly brackets.

The following function does this by having three statements, one for computing the mean of its input, one for getting the standard deviation, and a final expression that returns the input scaled to be centred on the mean and having one standard deviation.

```{r}
rescale <- function(x) {
    m <- mean(x)
    s <- sd(x)
    (x - m) / s
}
```

The first two statements are just there to define some variables we can use in the final expression. This is typical for writing short functions.

Assignments are really also expressions. They return an object, the value that is being assigned, they just do so quietly. This is why, if you put an assignment in parenthesis you will still get the value you assign printed. The parenthesis makes R remove the invisibility of the expression result so you see the actual value.

```{r}
(x <- 1:5)
```

```{r, echo=FALSE}
rm(x)
```

We usually use assignments for their side-effect, assigning a name to a value so you might not think of them as expressions, but everything you do in R is actually an expression. That includes control structures like `if` statements and `for` loops. They return values. They are actually functions, and they return the last expression evaluated in them, just like all other functions. Even parenthesis and sub-scripting are functions.

If you want to return a value from a function before its last expression, you can use the `return` function. It might look like a keyword but it *is* a function, and you need to include the parenthesis when you use it. Many languages will let you return a value by writing

```r
  return expression
```

Not R. In R you need to write

```r
  return(expression)
```

Return is usually used to exit a function early and isn't used that much in most R code. It is easier to return a value by just making it the last expression in a function than it is to explicitly use `return`. But you can use it to return early like this:

```{r}
rescale <- function(x, only_translate) {
    m <- mean(x)
    translated <- x - m
    if (only_translate) return(translated)
    s <- sd(x)
    translated / s
}
rescale(1:4, TRUE)
rescale(1:4, FALSE)
```

This function has two arguments, `x` and `only_translate`. Your functions can have any number of parameters. When a function takes many arguments, however, it becomes harder to remember in which order you have to put them. To get around that problem, R allows you to provide the arguments to a function using their names. So the two function calls above can also be written as

```{r, results="hide"}
rescale(x = 1:4, only_translate = TRUE)
rescale(x = 1:4, only_translate = FALSE)
```

### Named parameters and default parameters

If you use named arguments, the order doesn't matter, so this is also equivalent to these function calls:

```{r, results="hide"}
rescale(only_translate = TRUE, x = 1:4)
rescale(only_translate = FALSE, x = 1:4)
```


You can mix positional and named arguments. The positional arguments have to come in the same order as used in the function definition and the named arguments can come in any order. All the four function calls below are equivalent:

```{r, results="hide"}
rescale(1:4, only_translate = TRUE)
rescale(only_translate = TRUE, 1:4)
rescale(x = 1:4, TRUE)
rescale(TRUE, x = 1:4)
```

When you provide a named argument to a function, you don't need to use the full parameter name. Any unique prefix will do. So we could also have used the two function calls below:

```{r, results="hide"}
rescale(1:4, o = TRUE)
rescale(o = TRUE, 1:4)
```

This is convenient for interactive work with R because it saves some typing, but I do not recommend it when you are writing programs. It can easily get confusing and if the author of the function adds a new argument to the function with the same prefix as the one you use it will break your code. If the function author provides a default value for that parameter, your code will *not* break, if you use the full argument name.

Now default parameters are provided when the function is defined. We could have given `rescale` a default parameter for `only_translate` like this:

```{r}
rescale <- function(x, only_translate = FALSE) {
    m <- mean(x)
    translated <- x - m
    if (only_translate) return(translated)
    s <- sd(x)
    translated / s
}
```

Then, if we call the function we only need to provide `x` if we are happy with the default value for `only_translate`.

```{r, result="hide"}
rescale(1:4)
```

R makes heavy use of default parameters. Many commonly used functions, such as plotting functions and model fitting functions, have lots of arguments. These arguments let you control in great detail what the functions do, making them very flexible, and because they have default values you usually only have to worry about a few of them.

### The "gobble up everything else" parameter: "`...`"

There is a special parameter all functions can take called `...`. This parameter is typically used to pass parameters on to functions *called within* a function. To give an example, we can use it to deal with missing values, `NA`, in the `rescale` function.

We can write (where I'm building from the shorter version):

```{r}
rescale <- function(x, ...) {
    m <- mean(x, ...)
    s <- sd(x, ...)
    (x - m) / s
}
```

If we give this function a vector `x` that contains missing values it will return `NA`.

```{r}
x <- c(NA, 1:3)
rescale(x)
```

It would also have done that before because that is how the functions `mean` and `sd` work. But both of these functions take an additional parameter, `na.rm`, that will make them remove all `NA` values before they do their computations. Our `rescale` function can do the same now:

```{r}
rescale(x, na.rm = TRUE)
```

The first value in the output is still `NA`. Rescaling an `NA` value can't be anything else. But the rest are rescaled values where that `NA` was ignored when computing the mean and standard deviation.

The "`...`" parameter allows a function to take any named parameter at all. If you write a function without it, it will only take the parameters, but if you add this parameter, it will accept any named parameter at all.

```{r}
f <- function(x) x
g <- function(x, ...) x
f(1:4, foo = "bar")
g(1:4, foo = "bar")
```

If you then call another function with "`...`" as a parameter then all the parameters the first function doesn't know about will be passed on to the second function.

```{r}
f <- function(...) list(...)
g <- function(x, y, ...) f(...)
g(x = 1, y = 2, z = 3, w = 4)
```

In the example above, function `f` creates a list of named elements from "`...`" and as you can see it gets the parameters that `g` doesn't explicitly takes.

Using "`...`" is not particularly safe. It is often very hard to figure out what it actually does in a particular piece of code. What is passed on to other functions depend on what the first function explicitly takes as arguments, and when you call a second function using it you pass on all the parameters in it. If the function doesn't know how to deal with them, you get an error.

```{r}
f <- function(w) w
g <- function(x, y, ...) f(...)
g(x = 1, y = 2, z = 3, w = 4)
```

In the `rescale` function it would have been much better to add the `rm.na` parameter explicitly.

That being said, "`...`" is frequently used in R. Particularly because many functions take very many parameters with default values, and adding these parameters to all functions calling them would be tedious and error-prone. It is also the best way to add parameters when specialising generic functions, which is a topic for another book in this series: *Object Oriented Programming in R*.

To explicitly get hold of the parameters passed along in "`...`" you can use this invocation: `eval(substitute(alist(...)))`.

```{r}
parameters <- function(...) eval(substitute(alist(...)))
parameters(a = 4, b = a**2)
```

The `alist` function creates a list of names for each parameter and values for the expressions given.

```{r}
alist(a = 4, b = a**2)
```

You cannot use the `list` function for this unless you want all the expression evaluated. If you try to use `list` you can get errors like this:

```{r}
list(a = 4, b = a**2)
```

Because R uses so-called lazy evaluation for function parameters, something we return to shortly, it will be perfectly fine to define a function with default parameters that are expressions that can only right-hand. Inside a function that knows the parameters `a` and `b` you can evaluate expressions that use these parameters, even when they are not defined outside the function. So the parameters given to `alist` above is something you can use as default parameters when defining a function. But you cannot create the list using `list` because it will try to evaluate the expressions.

The reason you also need to substitute and evaluate is that `alist` will give you exactly the parameters you provide it. If you tried to use `alist` on "`...`" you would just get "`...`" back.

```{r}
parameters <- function(...) alist(...)
parameters(a = 4, b = x**2)
```

By substituting we translate "`...`" into the actual parameters given and by evaluating we get the list `alist` would give us in this context: the list of parameters and their associated expressions.

### Functions don't have names

The last thing I want to stress when we talk about defining functions is that functions do not have names. Variables have names, and variables can refer to functions, but these are two separate things.

In many languages, such as Java, Python, or C++, you define a function and at the same time, you give it an argument. When possible at all, you need a special syntax to define a function without a name.

Not so in R. In R, functions do not have names, and when you define them, you are not giving them a name. We have given names to all the functions we have used above by assigning them to variables right where we defined them. We didn't have to. It is the “`function(...) ...`” syntax that defines a function. We are defining a function whether we assign it to a variable or not.

We can define a function and call it immediately like this:

```{r}
(function(x) x**2)(2)
```

We would never do this, of course. Anywhere we would want to define an anonymous function and immediately call it we could instead just put the body of the function. Functions we want to reuse we *have* to give a name so we can get to them again.

The syntax for defining functions, however, doesn't force us to give them names. When you start to write higher-order functions, that is functions that take other functions as input or return functions, this is convenient.

Such higher-order functions are an important part of functional programming, and we will see much of them later in the book.

## Lazy evaluation

Expressions used in a function call are not evaluated before they are passed to the function. Most common languages have so-called pass-by-value semantics, which means that all expressions given to parameters of a function are evaluated before the function is called. In R, the semantic is "call-by-promise", also known as "lazy evaluation".

When you call a function and give it expressions as its arguments, these are not evaluated at that point. What the function gets is not the result of evaluating them but the actual expressions, called "promises" (they are promises of an evaluation to a value you can get when you need it). Thus the term "call-by-promise". These expressions are only evaluated when they are actually needed, thus the term "lazy evaluation".

This has several consequences for how functions work. First of all, an expression that isn't used in a function isn't evaluated.

```{r}
f <- function(a, b) a
f(2, stop("error if evaluated"))
f(stop("error if evaluated"), 2)
```

If you have a parameter that can only be meaningfully evaluated in certain contexts, it is safe enough to have it as a parameter as long as you only refer to it when those necessary conditions are met.

It is also very useful for default values of parameters. These are evaluated inside the scope of the function, so you can write default values that depend on other parameters:

```{r}
f <- function(a, b = a) a + b
f(a = 2)
```

This does *not* mean that all the expressions are evaluated inside the scope of the function, though. We discuss scopes in a later chapter but for now, you can think of two scopes: the global scope where global variables live, and the function scope that has parameters and local variables as well.

If you call a function like this

```r
f(a = 2, b = a)
```

you will get an error if you expect `b` to be the same as `a` inside the function. If you are lucky, and there isn't any global variable called `a` you will get a runtime error. If you are unlucky and there *is* a global variable called `a`, that is what `b` will be set to, and if you expect it to be set to 2 here your code will just give you an incorrect answer.

Using other parameters work for default values because these are evaluated inside the function. The expressions you give to function calls are evaluated in the scope outside the function.

This also means that you cannot change what an expression evaluates to just by changing a local variable.

```{r}
a <- 4
f <- function(x) {
    a <- 2
    x
}
f(1 + a)
```

```{r, echo=FALSE}
rm(a)
```

In this example, the expression `1 + a` is evaluated inside `f`, but the `a` in the expression is the `a` outside of `f` and not the `a` local variable inside `f`.

This is of course what you want. If expressions really *were* evaluated inside the scope of the function, then you would have no idea what they evaluated to if you called a function with an expression. It would depend on any local variables the function might use.

Because expressions are evaluated in the calling scope and not the scope of the function, you mostly won't notice the difference between call-by-value or call-by-promise. There are certain cases where the difference can bite you, though, if you are not careful.

As an example we can consider this function:

```{r}
f <- function(a) function(b) a + b
```

This might look a bit odd if you are not used to it, but it is a function that returns another function. We will see many examples of this kind of functions in later chapters.

When we call `f` with a parameter `a` we get a function back that will add `a` to its argument.

```{r}
f(2)(2)
```

We can create a list of functions from this `f`:

```{r}
ff <- vector("list", 4)
for (i in 1:4) {
  ff[[i]] <- f(i)
}
ff
```

Here, `ff` contains four functions and the idea is that the first of these adds 1 to its argument, the second add 2, and so on.

If we call the functions in `ff`, however, weird stuff happens.

```{r}
ff[[1]](1)
```

When we get the element `ff[[1]]` we get the first function we created in the loop. If we substitute into `f` the value we gave in the call, this is 

```r
function(b) i + b
```

The parameter `a` from `f` has been set to the parameter we gave it, `i`, but `i` has not been evaluated at this point!

When we call the function, the expression is evaluated, in the global scope, but there `i` now has the value 4 because that is the last value it was assigned in the loop. The value of `i` was 1 when we called it to create the function but it is 5 when the expression is actually evaluated.

This also means that we can chance the value of `i` before we evaluate one of the functions, and this changes it from the value we intended when we created the function.

```{r}
i <- 1
ff[[2]](1)
```

This laziness is only in effect the first time we call the function. If we change `i` again and call the function, we get the same value as the first time the function was evaluated.

```{r}
i <- 2
ff[[2]](1)
```

We can see this in effect by looping over the functions and evaluating them.

```{r}
results <- vector("numeric", 4)
for (i in 1:4) {
  results[i] <- ff[[i]](1)
}
results
```

We have already evaluated the first two functions so they are stuck at the values they got at the time of the first evaluation. The other two get the intended functionality but only because we are setting the variable `i` in the loop where we evaluate the functions. If we had used a different loop variable, we wouldn't have been so lucky.

This problem is caused by having a function with an unevaluated expression that depends on variables in the outer scope. Functions that return functions are not uncommon, though, if you want to exploit the benefits of having a functional language. It is also a consequence of allowing variables to change values, something most functional programming languages do not allow for such reasons. You cannot entirely avoid it, though, by avoiding `for`-loops. If you call functions that loop for you, you do not necessarily have control over how they do that, and you can end up in the same situation.

The way to avoid the problem is to force and evaluation of the parameter. If you evaluate it once, it will remember the value, and the problem is gone.

You can do that by just writing the parameter as a single statement. That will evaluate it. It is better to use the function `force` though, to make it explicit that this is what you are doing. It really just gives you the expression back, so it works exactly as if you just wrote the parameter, but the code makes clear why you are doing it.

If you do this, the problem is gone.

```{r}
f <- function(a) {
  force(a)
  function(b) a + b
}

ff <- vector("list", 4)
for (i in 1:4) {
  ff[[i]] <- f(i)
}

ff[[1]](1)
i <- 1
ff[[2]](1)
```


Getting back to parameters that are given expressions as arguments we can take a look at what they actually are represented as. We can use the function `parameters` we wrote above.

If we give a function an actual value, that is what the function gets.

```{r}
parameters <- function(...) eval(substitute(alist(...)))

p <- parameters(x = 2)
class(p$x)
```

The `class` function here tells us the type of the parameter. For the number 2, this is "`numeric`".

If we give it a name we are giving it an expression, even if the name refers to a single value.

```{r}
a <- 2
p <- parameters(x = a)
class(p$x)
```

The type is a "`name`". If we try to evaluate it, it will evaluate to the value of that parameter.

```{r}
eval(p$x)
```

It knows that the variable is in the global scope, so if we change it the expression will reflect this if we evaluate it.

```{r}
a <- 4
eval(p$x)
```

```{r, echo=FALSE}
rm(a)
```

If we call the function with an expression the type will be "`call`".

```{r}
p <- parameters(x = 2 * y)
class(p$x)
```

This is because all expressions are function calls. In this case, it is the function `*` that is being called.

We can only evaluate it if the variables the expression refers to are in the scope of the expression. So evaluating this expression will give us an error because `y` is not defined.

```{r}
eval(p$x)
```

The parameter `y` has to be in the calling scope, just as we saw earlier. Expressions are evaluated in the calling scope, not inside the function, so we cannot define `y` inside the `parameters` function and get an expression we can evaluate.

```{r}
parameters2 <- function(...) {
  y <- 2
  eval(substitute(alist(...)))
}
p2 <- parameters(x = 2 * y)
eval(p2$x)
```

We can set the variable and then evaluate it, though.

```{r}
y <- 2
eval(p$x)
```

Alternatively, we can explicitly set the variable in an environment given to the `eval` function.

```{r}
eval(p$x, list(y = 4))
```

```{r, echo=FALSE}
rm(y)
```

Actually, manipulating expressions and the scope they are evaluated in is a very powerful tool, but beyond what we will cover in this book. It is the topic for a later book in the series: *Meta-programming in R*.

## Vectorised functions

Expressions in R are vectorised. When you write an expression, it is implicitly working on vectors of values, not single values. Even simple expressions that only involves numbers really are vector operations. They are just vectors of length 1.

For longer vectors, expressions work component-wise. So if you have vectors `x` and `y` you can subtract the first from the second component wise just by writing `x - y`.

```{r}
x <- 1:5
y <- 6:10
x - y
```

If the vectors are not of the same length, the shorter vector is just repeated as many times as is necessary. This is why you can, for example, multiply a number to a vector.

```{r}
2 * x
```

Here `2` is a vector of length 1 and `x` a vector of length 5, and `2` is just repeated five times. You will get a warning if the length of the longer vector is not divisible by the length of the shorter vector, and you generally want to avoid this. The semantic is the same, though: R just keep repeating the shorter vector as many times as needed.

```{r}
x <- 1:6
y <- 1:3
x - y
```

Depending on how a function is written it can also be used in vectorised expressions. R is happy to use the result of a function call in a vector expression as long as this result is a vector. This is not quite the same as the function operating component-wise on vectors. Such functions we can call *vectorised* functions.

Most mathematical functions such as `sqrt`, `log`, `cos` and `sin` are vectorised and you can use them in expressions.

```{r}
log(1:3) - sqrt(1:3)
```

Functions you write yourself will also be vectorised if their body consist only of vectorised expressions.

```{r}
f <- function(a, b) log(a) - sqrt(b)
f(1:3, 1:3)
```

The very first function we wrote in this book, `square`, was also a vectorised function. The function `scale` was also, although the functions it used, `mean` and `sd` are not; they take vector input but return a summary of the entire vector and do not operate on the vector component-wise.

A function that uses control structures usually will not be vectorised. We can write a comparison function that returns -1 if the first argument is smaller than the second and 1 if the second is larger than the first, and zero otherwise like this:

```{r}
compare <- function(x, y) {
    if (x < y) {
        -1
    } else if (y < x) {
        1
    } else {
        0
    }
}
```

This function will work fine on single values but not on vectors. The problem is that the `if`-expression only looks at the first element in the logical vector `x < y`. (Yes, `x < y` is a vector because `<` is a vectorised function).

To handle `if`-expressions we can get around this problem by using the `ifelse` function. This is a vectorized function that behaves just as an `if-else`-expression.

```{r}
compare <- function(x, y) {
    ifelse(x < y, -1, ifelse(y < x, 1, 0))
}
compare(1:6, 1:3)
```

The situation is not always so simple that we can replace `if`-statements with `ifelse`. In most cases, we can, but when we cannot we can instead use the function `Vectorize`. This function takes a function that can operate on single values and translate it into a function that can work component-wise on vectors.

As an example, we can take the `compare` function from before and vectorize it.

```{r}
compare <- function(x, y) {
    if (x < y) {
        -1
    } else if (y < x) {
        1
    } else {
        0
    }
}
compare <- Vectorize(compare)
compare(1:6, 1:3)
```

By default, `Vectorize` will vectorise on all parameters of a function. As an example, imagine that we want a `scale` function that doesn't scale all variables in a vector by the same vector's mean and standard deviation but use the mean and standard deviation of another vector.

```{r}
scale_with <- function(x, y) {
    (x - mean(y)) / sd(y)
}
```

This function is already vectorised on its first parameter since it just consists of a vectorised expression, but if we use `Vectorize` on it, we break it.

```{r}
scale_with(1:6, 1:3)
scale_with <- Vectorize(scale_with)
scale_with(1:6, 1:3)
```

The function we create with `Vectorize` is vectorized for both `x` and `y`, which means that it operates on these component-wise. When scaling, the function only sees one component of `y`, not the whole vector. The result is a vector of missing values, `NA` because the standard deviation of a single value is not defined.

We can fix this by explicitly telling `Vectorize` which parameters should be vectorised. In this example only parameter `x`.

```{r}
scale_with <- function(x, y) {
    (x - mean(y)) / sd(y)
}
scale_with <- Vectorize(scale_with, vectorize.args="x")
scale_with(1:6, 1:3)
```

Simple functions are usually already vectorised, or can easily be made vectorised using `ifelse`, but for functions more complex the `Vectorize` function is needed.

As an example we can consider a tree data structure and a function for computing the node depth of a named node---the node depth defined as the distance from the root. For simplicity we consider only binary trees. We can implement trees using lists:

```{r}
make_node <- function(name, left = NULL, right = NULL) 
  list(name = name, left = left, right = right)

tree <- make_node("root", 
                  make_node("C", make_node("A"), 
                                 make_node("B")),
                  make_node("D"))
```

To compute the node depth we can traverse the tree recursively:

```{r}
node_depth <- function(tree, name, depth = 0) {
    if (is.null(tree))     return(NA)
    if (tree$name == name) return(depth)

    left <- node_depth(tree$left, name, depth + 1)
    if (!is.na(left)) return(left)
    right <- node_depth(tree$right, name, depth + 1)
    return(right)
}
```

This is not an unreasonably complex function, but it is a function that is harder to vectorise than the `scale_with` function. As it is, it works well for single names

```{r}
node_depth(tree, "D")
node_depth(tree, "A")
```

but you will get an error if you call it on a sequence of names

```r
node_depth(tree, c("A", "B", "C", "D"))
```

It is not hard to imagine that a vectorised version could be useful, however. For example to get the depth of a sequence of names.

```{r}
node_depth <- Vectorize(node_depth, vectorize.args = "name", 
                        USE.NAMES = FALSE)
node_depth(tree, c("A", "B", "C", "D"))
```

Here the `USE.NAMES = FALSE` is needed to get a simple vector out. If we did not include it, the vector would have names based on the input variables. See the documentation for `Vectorize` for details.


## Infix operators

Infix operators in R are also functions. You can over-write them with other functions (but you really shouldn't since you could mess up a lot of code), and you can also make your own infix operators.

User defined infix operators are functions with special names. A function with a name that starts and ends with `%` will be considered an infix operator by R. There is no special syntax for creating a function to be used as an infix operator, except that it should take two arguments. There is a special syntax for assigning, variables, though, including variables with names starting and ending with `%`.

To work with special variables you need to quote them with back-ticks. You cannot write `+(2, 2)` even though `+` is a function. R will not understand this as a function call when it sees it written like this. But you can take `+` and quote it, `` `+` ``, and then it is just a variable name like all other variable names.

```{r}
`+`(2, 2)
```

The same goes for all other infix operators in R and even control structures.

```{r}
`if`(2 > 3, "true", "false")
```

The R parser recognises control structure keywords and various operators, e.g. the arithmetic operators, and therefore these get to have a special syntax. But they are all really just functions. Even parentheses are a special syntax for the function `` `(` `` and the subscript operators are as well, `` `[` `` and `` `[[` `` respectively. If you quote them, you get a variable name that you can use just like any other function name.

Just like all these operators have a special syntax, variables starting and ending with `%` get a special syntax. R expects them to be infix operators and will treat an expression like this:

```r
exp1 %op% exp2
```

as the function call

```r
`%op%`(exp1, exp2)
```

Knowing that you can translate an operator name into a function name just by quoting it also tells you how to define new infix operators. If you assign a function to a variable name, you can refer to it by that name. If that name is a quoted special name, it gets to use the special syntax for that name.

So, to define an operator `%x%` that does multiplication we can write

```{r}
`%x%` <- `*`
3 %x% 2
```

Here we used quotes twice, first to get a variable name we could assign to for `%x%` and once to get the function that the multiplication operator, `*`, points to.

Just because all control structures and operators in R are functions that you can overwrite, you shouldn't go doing that without extreme caution. You should *never* change the functions the control structures point to, and you should not change the other operators unless you are defining operators on new types where it is relatively safe to do so (and I will tell you how to in the *Object Oriented Programming in R* in this series). Defining entirely new infix operators, however, can be quite useful if they simplify expressions you write often.

As an example let us do something else with the `%x%` operator---after all, there is no point in having two different operators for multiplication. We can make it replicate the left-hand side a number of times given by the right-hand side:

```{r}
`%x%` <- function(expr, num) replicate(num, expr)
3 %x% 5
cat("This is ", "very " %x% 3, "much fun")
```

We are using the `replicate` function to achieve this. It does the same thing. It repeatedly evaluates an expression a fixed number of times. Using `%x%` infix might give more readable code, depending on your taste.

In the interest of honesty, I must mention, though, that we haven't just given `replicate` a new name here, switching of arguments aside. The `%x%` operator works slightly differently. In `%x%` the `expr` parameter is evaluated when we call `replicate`. So if we call `%x%` with a function that samples random numbers we will get the same result repeated `num` times; we will not sample `num` times.

```{r}
rnorm(1) %x% 4
```

Lazy evaluation only takes you so far.

To actually get the same behaviour as `replicate` we need a little more trickery:

```{r}
`%x%` <- function(expr, num) {
  m <- match.call()
  replicate(num, eval.parent(m$expr))
}
rnorm(1) %x% 4
```

Here the `match.call` function just gets us a representation of the current function call from which we can extract the expression without evaluating it. We then use `replicate` to evaluate it a number of times in the calling function's scope.

If you don't quite get this, don't worry. We cover scopes in a later chapter.

## Replacement functions

Another class of functions with special names is the so-called *replacement functions*. Data in R is immutable. You can change what data parameters point to, but you cannot change the actual data. Even when it looks like you are modifying data you are, at least conceptually, creating a copy, modifying that, and making a variable point to the new copy.

We can see this in a simple example with vectors. If we create two vectors that point to the same initial vector, and then modify one of them, the other remains unchanged.

```{r}
x <- y <- 1:5
x
y
x[1] <- 6
x
y
```

R is smart about it. It won't make a copy of values if it doesn't have to. Semantically it is best to think of any modification as creating a copy, but for performance reasons R will only make a copy when it is necessary. At least for built-in data like vectors. Typically, this happens when you have two variables referring to the same data and you "modify" one of them.

We can use the `address` function to get the memory address of an object. This will change when a copy is made but will remain the same when it isn't. And we can use the `mem_change` function from the `pryr` package to see how much memory is allocated for an expression. Using these two functions, we can dig a little deeper into this copying mechanism.

We can start by creating a long-ish vector and modifying it.

```r
library(pryr)
```
```{r}
rm(x) ; rm(y)
mem_change(x <- 1:10000000)
address(x)
mem_change(x[1] <- 6)
address(x)
```

When we assign to the first element in this vector, we see that the entire vector is being copied. This might look odd since I just told you that R would only copy a vector if it had to, and here we are just modifying an element in it, and no other variable refers to it.

The reason we get a copy here is that the expression we used to create the vector, `1:10000000`, creates an integer vector. The value `6` we assign to the first element is a floating point, called "numeric" in R. If we want an actual integer we have to write "L" after the number.

```{r}
class(6)
class(6L)
```

When we assign a numeric to an integer vector, R has to convert the entire vector into numeric, and that is why we get a copy.

```{r}
z <- 1:5
class(z)
z[1] <- 6
class(z)
```
```{r, echo=FALSE}
rm(z)
```

If we assign another numeric to it, after it has been converted, we no longer get a copy.

```{r}
mem_change(x[3] <- 8)
address(x)
```

All expression evaluations modify the memory a little, up or down, but the change is much smaller than the entire vector so we can see that the vector isn't being copied, and the address remains the same.

If we assign `x` to another variable, we do not get a copy. We just have the two names refer to the same value.

```{r}
mem_change(y <- x)
address(x)
address(y)
```

If we change `x` again, though, we need a copy to make the other vector point to the original, unmodified data.

```{r}
mem_change(x[3] <- 8)
address(x)
address(y)
```

But after that copy, we can again assign to `x` without making additional copies.

```{r}
mem_change(x[4] <- 9)
address(x)
```
```{r, echo=FALSE}
rm(x) ; rm(y)
```

When you assign to a variable in R, you are calling the assignment function, `` `<-` ``. When you assign to an element in a vector or list you are using the `` `[<-` `` function. But there is a whole class of such functions you can use to make the appearance of modifying an object, without actually doing it of course. These are called replacement functions and have names that ends in `<-`. An example is the `` `names<-` `` function. If you have a vector `x` you can give its elements names using this syntax:

```{r}
x <- 1:4
x
names(x) <- letters[1:4]
x
names(x)
```

There are two different functions in play here. The last expression, which gives us `x`'s names, is the `names` function. The function we use to *assign* the names to `x` is the `` `names<-` `` function.

Any function you define whose name ends with `<-` becomes a replacement function, and the syntax for it is that it evaluates whatever is on the right-hand side of the assignment operator and assigns the result to the variable that it takes as its argument.

So this syntax

```{r}
names(x) <- letters[1:4]
```

is translated into

```{r}
x <- `names<-`(x, letters[1:4])
```

No values are harmed in the evaluation of this, but the variable is set to the new value.

We can write our own replacement functions using this syntax. There are just two requirements. The function name has to end with `<-` ---so we need to quote the name when we assign to it---and the argument for the value that goes to the right-hand side of the assignment has to be named `value`. The last requirement is there so replacement functions can take more than two arguments.

The `` `attr<-` `` function is an example of this. Attributes are key-value maps that can be associated with objects. You can get the attributes associated with an object using the `attributes` function and set all attributes with the `` `attributes<-` `` function, but you can assign individual attributes using `` `attr<-` ``. It takes three arguments, the object to modify, a `which` parameter that is the name of the attribute to set, and the `value` argument that goes to the right-hand side of the assignment. The `which` argument is passed to the function on the left-hand side together with the object to modify.

```{r}
x <- 1:4
attributes(x)
attributes(x) <- list(foo = "bar")
attributes(x)
attr(x, "baz") <- "qux"
attributes(x)
```

We can write a replacement function to make the tree construction we had earlier in the chapter slightly more readable. Earlier we constructed the tree like this:

```{r}
tree <- make_node("root", 
                  make_node("C", make_node("A"), 
                                 make_node("B")),
                  make_node("D"))
```

but we can make functions for setting the children of an object like this:

```{r}
`left<-` <- function(node, value) {
    node$left = value
    node
}
`right<-` <- function(node, value) {
    node$right = value
    node
}
```

and then construct the tree like this:

```{r}
A <- make_node("A")
B <- make_node("B")
C <- make_node("C")
D <- make_node("D")
root <- make_node("root")
left(C) <- A
right(C) <- B
left(root) <- C
right(root) <- D
tree <- root
```

To see the result, we can write a function for printing a tree. To keep the function simple, I assume that either both children are `NULL` or both are trees. It is simple to extend it to deal with trees that do not satisfy that, it just makes the function a bit longer.

```{r}
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
print_tree(tree)
```

This function shows the tree in what is known as the Newick format and doesn't show the names of inner nodes, but you can see the structure of the tree.

The order in which we build the tree using `children` is important. When we set the children for `root`, we refer to the variable `C`. If we set the children for `C` *after* we set the children for `root` we get the *old* version of `C`, no the new modified version.

```{r}
A <- make_node("A")
B <- make_node("B")
C <- make_node("C")
D <- make_node("D")
root <- make_node("root")
left(root) <- C
right(root) <- D
left(C) <- A
right(C) <- B
tree <- root
print_tree(tree)
```

Replacement functions only look like they are modifying data. They are not. They only reassign values to variables.
