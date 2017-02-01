
# Higher-order Functions

The term *higher-order functions* refers to functions that either take functions as arguments or return functions. The functions we used to create closures in the previous chapter are thus higher-order functions. Higher-order functions are frequently used in R instead of looping control structures, and we will cover how you can do this in general in the next chapter. I will just give you a quick example here before moving on to more interesting things we can do with functions working on functions.

The function `sapply` (it stands for simplifying apply) lets you call a function for all elements in a list or vector. You should mainly use this for interactive in R because it is a little unsafe. It tries to guess at which type of output you want, based on what the input and the function you give it does, and there are safer alternatives, `vapply` and `lapply`, where the output is always a predefined type or always a list, respectively.

In any case, if you want to evaluate a function for all elements in a vector you can write code like this:

```{r}
sapply(1:4, sqrt)
```

This evaluates `sqrt` on all the element in the vector `1:4` and gives you the result. It is analogue to the vectorised expression

```r
sqrt(1:4)
```

and the vectorised version is probably always preferable if your expressions can be vectorised. The vector expression is easier to read and usually much faster if it involves calling built-in functions.

You can use `sapply` to evaluate a function on all elements in a sequence when the function you want to call is not vectorised, however, and in fact, the `Vectorize` function we saw in the first chapter is implemented using `sapply`'s cousin, `lapply`.

We could implement our own version like this:

```{r}
myapply <- function(x, f) {
  result <- x
  for (i in seq_along(x)) result[i] <- f(x[i])
  result
}

myapply(1:4, sqrt)
```

Here I create a result vector of the right length just by copying `x`. The assignments into this vector might create copies. The first is guaranteed to because we are changing a vector, which R avoids by making a copy. Later assignments might do it again to convert the type of the results. Still, it is reasonably simple to see how it works and if the input and output have the same type it is running in linear time (in the number of function calls to `f` which of course can have any run-time complexity).

Using a function like `sapply` or `myapply`, or any of their cousins, lets us replace a loop, where all kinds of nastiness can happen with assignments to local variables that we do not necessarily want, with a single function call. We just need to wrap the body of the loop in another function we can give to the apply function.

Closures can be particularly useful in combination with apply functions if we need to pass some information along to the function. Let us, for example, consider a situation where we want to scale the element in a vector. We wrote such a function in the first chapter:

```{r}
rescale <- function(x) {
  m <- mean(x)
  s <- sd(x)
  (x - m) / s
}
rescale(1:4)
```

This was written using vector expressions, which is the right thing to do, but let us see what we can do with an apply function. Obviously we still need to compute `m` and `s` and then a function for computing `(x - m) / s`.

```{r}
rescale <- function(x) {
  m <- mean(x)
  s <- sd(x)
  f <- function(y) (y - m) / s
  myapply(x, f)
}
rescale(1:4)
```

There is really no need to give the function a name and then pass it along, we can also just write

```{r}
rescale <- function(x) {
  m <- mean(x)
  s <- sd(x)
  myapply(x, function(y) (y - m) / s)
}
rescale(1:4)
```

The function we pass to `myapply` knows the environment in which it was created, so it knows `m` and `s` and can use these variables when it is being called from `myapply`.

## Currying

It is not unusual to have a function of two arguments where you want to bind one of them and return a function that takes, as a parameter, the second argument. For example, if we want to use the function

```{r}
f <- function(x, y) x + y
```

we might want to use it to add 2 to each element in a sequence using `myapply`. Once again I stress that this example is just to show you a general technique and you should never do these things when you can solve a problem with vector expressions, but let us for a second pretend that we don't have vector expressions. Then we would need to create a function for one of the parameters, say `y` and then when called evaluate `f(2,y)`.

We could write it like this, obviously:

```{r}
g <- function(y) f(2, y)
myapply(1:4, g)
```

which would suffice if we only ever needed to add 2 to all elements in a sequence. If we wanted a more general solution, we would want a function to create the function we need, a closure that remembers `x` and can be called with `y`. Such a function is only slightly more complicated to write, we simply need a function that returns a function like this:

```{r}
h <- function(x) function(y) f(x, y)
myapply(1:4, h(2))
```

The function `f` and the function `h` eventually do the same thing, the only difference is in how we provide parameters to them. Function `f` needs both parameters at once while function `h` takes one parameter at a time.

```{r}
f(2, 2)
h(2)(2)
```

A function such as `h`, one that takes a sequence of parameters not in a single function call but through a sequence of function calls, each taking a single parameter and returning a new function, is known as a *curried* function. What we did to transform `f` into `h` is called *currying* `f`. The names refer to the logician Haskell Curry, from whom we also get the name of the functional programming language Haskell.

The transformation we did from `f` to `h` was manual, but we can write functions that transform functions: functions that take a function as input and return another function. We can thus write a general function for currying a function. Another high-level function. A function for currying functions of two parameters can be written like this:

```{r}
curry2 <- function(f)
  function(x) function(y) f(x, y)
```

The argument `f` is the function we want to curry and the return value is the function

```r
function(x) function(y) f(x, y)
```

that needs to be called first with parameter `x` and then with parameter `y` and then it will return the value `f(x, y)`. The name of the variables do not matter here, they are just names and need not have anything to do with the names of the variables that `f` actually takes.

Using this function we can automatically create `h` from `f`:

```{r}
h <- curry2(f)
f(2, 3)
h(2)(3)
```

Since ```+``` is just a function in R we can also simply use *it* instead of writing the function `f` first

```{r}
h <- curry2(`+`)
h(2)(3)
```

and thus write the code that adds 2 to all elements in a sequence like this:

```{r}
myapply(1:4, curry2(`+`)(2))
```

Whether you find this clever or too terse to be easily understood is a matter of taste. It is clearly not as elegant as vector expressions, but once you are familiar with what currying does it is not difficult to parse either.

The function we wrote for currying only works on functions that take exactly two arguments. We explicitly created a function that returns a function that returns the final value, so the curried version has to work on functions with two arguments. But functions are data that we can examine in R so we can create a general version that can handle functions of any number of arguments. We simply need to know the number of arguments the function takes and then create a sequence of functions for taking each parameter.

The full implementation is shown below, and I will explain it in detail after the function listing.

```{r}
curry <- function(f) {
  n <- length(formals(f))
  if (n == 1) return(f) # no currying needed

  arguments <- vector("list", length = n)
  last <- function(x) {
    arguments[n] <<- x
    do.call(f, arguments)
  }
  make_i <- function(i, continuation) {
    force(i) ; force(continuation)
    function(x) {
      arguments[i] <<- x
      continuation
    }
  }

  continuation <- last
  for (i in seq(n-1, 1)) {
    continuation <- make_i(i, continuation)
  }
  continuation
}
```

First we get the number of arguments that function `f` takes.

```r
  n <- length(formals(f))
```

We can get these arguments using the `formals` function. It returns what is called a pair-list, which is essentially a linked list similar to the one we saw in *[Pure Functional Programming]*, and is used internally in R but not in actual R programming. You can treat it as a list, and it behaves the same way except for some runtime performance differences. We just need to know the length of the list.

We just return if `f` only takes a single argument. Then it is already as curried as it can get. Otherwise we create a table in which we will store variables when the chain of functions are called.

```r
  arguments <- vector("list", length = n)
```

We need to collect the arguments that are passed to the individual functions we create. We cannot simply use parameter arguments `x` and `y` as we did in `curry2` because we do not know how many arguments we would need before we have examined the input function, `f`. In any case, we would need to create names dynamically to make sure they don't clash. Just saving the arguments in a list is simpler, and since it is a list, we can put any kind of values that are passed as arguments in it.

Now we need to create the actual function we should return. We do this in steps. The final function we create should call `f` with all the arguments. It takes the last argument as input, so we need to store that in `arguments` -- and since this means modifying a list outside of the scope of the actual function, we need the ``\<\<-`` assignment operator for that. To call `f` with a list of its arguments we need to use the function `do.call`. It lets us specify the arguments to the function in a list instead of giving them directly as comma-separated arguments.

```r
  last <- function(x) {
    arguments[n] <<- x
    do.call(f, arguments)
  }
```

Each of the other functions needs to store an argument as well so they will need to know the corresponding index, and then they should return the next function in the curried chain. We can create such functions like this:

```r
  make_i <- function(i, continuation) {
    force(i) ; force(continuation)
    function(x) {
      arguments[i] <<- x
      continuation
    }
  }
```

The parameter `i` is just the index, which we use to assign a value to an argument, and the parameter `continuation` is the functions that still remains to be called before the final result can be returned from function `last`. It is the continuation of the curried function. We need to evaluate both parameters inside `make_i` before we return the function. Otherwise, we run into the lazy-evaluation problem where, when eventually call the function, values of variables might have changed since we created the function. We do this by calling `force` on the arguments.

We now simply need to bind it all together. We do this in reverse order, so we always have the continuation we need when we create the next function. The first continuation is the `last` function. It is the last function that should be called, and it will return the desired result of the entire curried chain. Each call to `make_i` will return a new continuation that we provide to the next function in the chain (in reverse order).

```r
  continuation <- last
  for (i in seq(n-1, 1)) {
    continuation <- make_i(i, continuation)
  }
```

The final continuation we create is the curried function, so that is what we return at the end of `curry`.

Now we can use this `curry` function to translate any function into a curried version:

```{r}
f <- function(x, y, z) x + 2*y + 3*z
f(1, 2, 3)
curry(f)(1)(2)(3)
```

It is not *quite* the same semantics as calling `f` directly; we are evaluating each expression when we assign it to the `arguments` table, so lazy-evaluation isn't in play here. To write a function that can deal with the lazy evaluation of the parameters requires a lot of mucking about with environments and expressions that is beyond the scope of this book, but that I cover in the *Meta-programming in R* book later. Aside from that, though, we have written a general function for translating normal functions into their curried form.

It is *much* harder to make a transformation in the other direction automatically. If we get a function, we cannot see how many times we would need to call it to get a value, if that is even independent of the parameters we give it, so there is no way to figure out how many parameters we should get for the uncurried version of a curried function.

The `curry` function isn't completely general. We cannot deal with default arguments -- all arguments must be provided in the curried version -- and we cannot create a function where some arguments are fixed, and others are not. The curried version always needs to take the arguments in the exact order the original function takes them.


## A parameter binding function

We already have all the tools we need to write a function that binds a set of parameters for a function and return another function where we can give the remaining parameters and get a value.

```{r}
bind_parameters <- function(f, ...) {
  remembered <- list(...)
  function(...) {
    new <- list(...)
    do.call(f, c(remembered, new))
  }
}

f <- function(x, y, z, w = 4) x + 2*y + 3*z + 4*w

f(1, 2, 3, 4)
g <- bind_parameters(f, y = 2)
g(x = 1, z = 3)

h <- bind_parameters(f, y = 1, w = 1)
f(2, 1, 3, 1)
h(x = 2, z = 3)
```

We get the parameters from the first function call and saves them in a list, and then we return a closure that can take the remaining parameters, turn them into a list, combine the remembered and the new parameters and call function `f` using `do.call`.

All the building blocks we have seen before, we are just combining them to translate one function into another.

Using `list` here to remember the parameters from `...` means that we are evaluating the parameters. We are explicitly turning off lazy-evaluation in this function. It is possible to keep the lazy evaluation semantics as well, but it requires more work. We would need to use the `eval(substitute(alist(...)))` trick to get the unevaluated parameters into a list -- we saw this trick in the first chapter -- but that would give us raw expressions in the lists, and we would need to be careful to evaluate these in the right environment chain to make it work. I leave this as an exercise to the reader, or you can look at the `partial` function from the `pryr` package to see how it is done.

Such partial binding functions aren't used that often in R. It is just as easy to write closures to bind parameters and those are usually easier to read, so use partial bindings with caution. 

## Continuation-passing style

The trick we used to create `curry` involved creating a chain of functions where each function returns the next function that should be called, the *continuation*. This idea of having the remainder of a computation as a function you can eventually call can be used in many other problems.

Consider the simple task of adding all elements in a list. We can write a function for doing this in the following three ways:

```{r}
my_sum_direct <- function(lst) {
  if (is_empty(lst)) 0
  else first(lst) + my_sum_direct(rest(lst))
}
my_sum_acc <- function(lst, acc = 0) {
  if (is_empty(lst)) acc
  else my_sum_acc(rest(lst), first(lst) + acc)
}
my_sum_cont <- function(lst, cont = identity) {
  if (is_empty(lst)) cont(0)
  else my_sum_cont(rest(lst), 
                   function(acc) cont(first(lst) + acc))
}
```

The first function handles the computation in an obvious way by adding the current element to the result of the recursive call. The second function uses an accumulator to make a tail-recursive version, where the accumulator carries a partial sum along with the recursion. The third version also gives us a tail-recursive function but in this case via a continuation function. This function works as the accumulator in the second function, it just wraps the computation inside a function that is passed along in the recursive call.

Here, the continuation captures the partial sum moving down the recursion — the same job as the accumulator has in the second function — but expressed as an as-yet not evaluated function. This function will eventually be called by the sum of values for the rest of the recursion, so the job at this place in the recursion is simply to take the value it will eventually be provided, add the current value, and then call the continuation it was passed earlier to complete the computation.

For something as simple as a adding the numbers in a list, continuation passing is of course overkill. If you need tail-recursion, the accumulator version is simpler and faster, and in any case, you are just replacing recursion going down the vector with function calls in the continuation moving up again (but see later for a solution to this problem). Still, seeing the three approaches to recursion — direct, accumulator and continuation-passing — in a trivial example makes it easier to see how they work and how they differ.

A common use of continuations is to translate non-tail-recursive functions into tail-recursive. As an example, we return to the function from *[Pure Functional Programming]* that we used to compute the size of a tree. In that solution we needed to handle internal nodes by first calling recursively on the left subtree and then the right subtree, to get the sizes of these, and then combine them and adding one for the internal node. Because we needed the results from two recursive calls, we couldn't directly make the function tail-recursive. Using continuations we can.

```{r, echo=FALSE}
make_node <- function(name, left = NULL, right = NULL)
  list(name = name, left = left, right = right)

tree <- make_node("root",
                  make_node("C", make_node("A"),
                                 make_node("B")),
                  make_node("D"))
```

The trick is to pass a continuation along that is used to wrap one of the recursions while we can handle the other recursion in a tail-recursive call. The solution looks like this:

```{r}
size_of_tree <- function(node, continuation = identity) {
  if (is.null(node$left) && is.null(node$right)) {
    continuation(1)
  } else {
    new_continuation <- function(left_result) {
      continuation(left_result + size_of_tree(node$right) + 1)
    }
    size_of_tree(node$left, new_continuation)
  }
}

size_of_tree(tree)
```

The function takes a continuation along in its call, and this function is responsible for computing "the rest of what needs to be done". If the node we are looking at is a leaf, we call it with 1, because a leaf has size one, and then it will do whatever computation is needed to compute the size of the tree we have seen earlier and wrapped in the `continuation` parameter.

The default continuation is the identity function

```r
function(x) x
```

so if we just call the function with a leaf we will get 1 as the value. But we modify the continuation when we see an internal node to wrap some of the computation we cannot do yet because we do not have the full information for what we need to compute.

For internal nodes we do this:

```r
    new_continuation <- function(left_result) {
      continuation(left_result + size_of_tree(node$right) + 1)
    }
    size_of_tree(node$left, new_continuation)
```

We create a continuation that, if we give it the size of the left subtree, can compute the size of the full tree by calling recursively on the right subtree and then adding the size of the left subtree. That wraps up the computations we need to do with the right subtree, so we only need to call recursively on the left subtree and that we can do with a tail-recursive call.

Because it is tail-recursive, we can replace the recursive calls with a loop. This time around we need to remember to `force` the evaluation of the continuation when we create the new continuation because when we loop we are modifying local parameters. Otherwise, it looks like you would expect from the general pattern for translating tail-recursive functions into looping functions.

```{r}
size_of_tree <- function(node) {
  continuation <- identity # function(x) x
  repeat {
    if (is.null(node$left) && is.null(node$right)) {
      return(continuation(1))
    }
    new_continuation <- function(continuation) {
      force(continuation)
      function(left_result) {
        continuation(left_result + size_of_tree(node$right) + 1)
      }
    }
    # simulated recursive call
    node <- node$left
    continuation <- new_continuation(continuation)
  }
}

size_of_tree(tree)
```

There is a catch, though. We avoid deep recursions to the left, but the continuation we create is going to call functions just as deep as we would earlier do the recursion. Each time we would usually call recursively, we are wrapping a function inside another, and when these need to be evaluated, we still have a deep number of function calls.

There is a trick to get around this. It won't give us the performance boost of using a loop instead of recursions, it will actually be slightly slower, but it will let us write functions with more than one recursion without having too deep recursive calls.

## Thunks and trampolines

There are two pieces to the solution of too deep recursions. The first is something called a "thunk". It is simply a function that takes no arguments and returns a value. It is used to wrap up a little bit of computation that you can evaluate later. We can turn a function, with its arguments, into a thunk like this:

```{r}
make_thunk <- function(f, ...) { 
  force(f)
  params <- list(...)
  function() do.call(f, params)
}
```

We force the function parameter, `f`, just in case -- we don't want it to change if it refers to an expression that might change after we have defined the thunk. Then we remember the parameters to the function -- this evaluates the parameters, so no lazy evaluation here (it is much harder to keep track of the thunk if we need to keep the evaluation lazy), and then we return a function with no arguments that simply evaluates `f` on the remembered parameters.

Now we can turn any function into a thunk:

```{r}
f <- function(x, y) x + y
thunk <- make_thunk(f, 2, 2)
thunk()
```

If you are wondering why such functions are called "thunks", here is what the Hackers Dictionary has to say:

> > >  Historical note: There are a couple of onomatopoeic myths circulating about the origin of this term. The most common is that it is the sound made by data hitting the stack; another holds that the sound is that of the data hitting an accumulator. Yet another holds that it is the sound of the expression being unfrozen at argument-evaluation time. In fact, according to the inventors, it was coined after they realized (in the wee hours after hours of discussion) that the type of an argument in Algol-60 could be figured out in advance with a little compile-time thought, simplifying the evaluation machinery. In other words, it had "already been thought of"; thus it was christened a thunk, which is "the past tense of \`think' at two in the morning". -- [The Hackers Dictionary](http://www.hacker-dictionary.com/terms/thunk).

We are going to wrap recursive calls into thunks where each thunk takes one step in a recursion. Each thunk evaluates one step and returns a new thunk that will evaluate the next step, and so on until a thunk eventually returns a value. The term for such evaluations is a "trampoline", and the imagery is that each thunk bounce on the trampoline, evaluates one step, and lands on the trampoline again as the next thunk.

A trampoline is just a function that keeps evaluating thunks until it gets a value, and the implementation looks like this:

```{r}
trampoline <- function(thunk) {
  while (is.function(thunk)) thunk <- thunk()
  thunk
}
```

To see how thunks and trampolines can be combined to avoid recursion we will first consider the simpler case of calculating the factorial of a number instead of the size of a tree.

We wrote the recursive factorial function in *[Pure Functional Programming]* and the non-tail-recursive version looked like this:

```r
factorial <- function(n) {
  if (n == 1) 1
  else n * factorial(n - 1)
}
```

and the tail-recursive version, using an accumulator, looked like this:

```{r}
factorial <- function(n, acc = 1) {
  if (n == 1) acc
  else factorial(n - 1, acc * n)
}
```

To get the thunk-trampoline version, we are first going to rewrite this using continuation passing. This is mostly just turning the accumulator in the tail-recursive version into a continuation for computing the final result:

```{r cp_factorial, cache=TRUE}
cp_factorial <- function(n, continuation = identity) {
  if (n == 1) {
    continuation(1)
  } else {
    new_continuation <- function(result) {
      continuation(result * n)
    }
    cp_factorial(n - 1, new_continuation)
  } 
}

factorial(10)
cp_factorial(10)
```

This function does the same as the accumulator version, and because there is no tail-recursion optimisation it will call `cp_factorial` all the way down from `n` to `1` and then it will evaluate continuation functions just as many times. We can get it to work for n maybe up to a thousand or so, but after that, we hit the recursion stack limit. Before we reach that limit, the number will be too large to represent as floating point numbers in R anyway, but that is not the point; the point is that the number of recursive calls can get too large for us to handle.

So instead of calling recursively we want each "recursive" call to create a thunk instead. This will create a thunk that does the next step and returns a thunk for the step after that, but it will not call the next step, so no recursion. We need such thunks both for the recursions and the continuations. The implementation is simple, we just replace the recursions with calls to `make_thunk`:

```{r}
thunk_factorial <- function(n, continuation = identity) {
  if (n == 1) {
    continuation(1)
  } else {
    new_continuation <- function(result) {
      make_thunk(continuation, n * result)
    }
    make_thunk(thunk_factorial, n - 1, new_continuation)
  }
}
```

Calling this function with 1 directly gives us a value:

```{r}
thunk_factorial(1)
```

Calling it with 2 creates a thunk. We need to call this thunk to move down the recursion to the base case, this will give us a thunk for the continuation there, and we need to evaluate that thunk to get the value:

```{r}
thunk_factorial(2)()()
```

For each additional step in the recursion we thus get two more thunks, one for going down the recursion and the next for evaluating the thunk, but eventually, we will have evaluated all the thunks and will get a value.

```{r thunk_factorial_explicit, cache=TRUE}
thunk_factorial(3)()()()()
thunk_factorial(4)()()()()()()
thunk_factorial(5)()()()()()()()()
```

Of course, we don't want to call all these thunks explicitly, that is what the trampoline is for.

```{r trampoline_thunk, cache=TRUE}
trampoline(thunk_factorial(100))
```

We can write another higher-order function for translating such a thunk-enized function into one that uses the trampoline to do the calculation like this:

```{r trampoline_thunk_function, cache=TRUE}
make_trampoline <- function(f) function(...) trampoline(f(...))
factorial <- make_trampoline(thunk_factorial)
factorial(100)
```

For computing the size of a tree we just do exactly the same thing. It doesn't matter that the continuation we use here does something more complex -- it calls the depth-first traversal on the right subtree instead of just computing an expression directly -- because it is just a continuation and we just need to wrap it up as a thunk:

```{r}
thunk_size <- function(node, continuation = identity) {
  if (is.null(node$left) && is.null(node$right)) {
    continuation(1)
  } else {
    new_continuation <- function(left_result) 
      make_thunk(continuation, 
                 left_result + thunk_size(node$right) + 1)
    make_thunk(thunk_size, node$left, new_continuation)
  }
}

size_of_tree <- make_trampoline(thunk_size)
size_of_tree(tree)
```

The way we make the trampoline version is *exactly* the same as what we did for the factorial function. We make a continuation passing version of the recursion, then we translate the direct recursive calls into thunks, and we make our continuations return thunks. Using the trampoline, we never run into problems with hitting the call stack limit; we never call recursively we just create thunks on the fly whenever we would otherwise need to call a function.

Isn't this just mind-boggling clever?


