
# Scope and Closures

A *scope* is something functions or expressions are associated with that tells them what values variables refer to. It is used to figure out which environment expressions are evaluated in. The same variable name can be used many places in a program, but the scope of an expression tells R exactly which variable of a given name is referred to in the expression.

A *closure* is a function with an associated scope. All functions in R have at least two different environments where they can find out what value a given variable is referring to. There is the *local* environment of the function, where function parameters and local variables can be looked up, and the *global* environment where global variables can be found. So by this definition of closure all functions in R are closures. We typically reserve the term for functions that have more than these two environments, though; functions defined inside other functions that can refer to both the local and global environment and also the environment of the enclosing function and are used outside of the enclosing function. There is nothing special about closures. They are just functions. We use them to remember environments that existed at the time they were created. If this sounds confusing right now, I hope it becomes clearer after you have read the section on scopes later in the chapter.

## Scopes and environments

There are really two conceptual mappings going on when looking up a variable in an R expression. Expressions that contain variables know the variable name, not the value that the variable points to. When an expression is evaluated, the expression needs that value, so R needs to figure out what the value is. Since a variable name is not necessarily unique, it first needs to determine which of the potentially many variables with the same name is being referred to, and then to figure out what the value that variable is pointing to.

In the code below we have two variables named `x`. One is a global variable that refers to a vector. The other is a function argument. Inside the function, we have an expression that refers to `x`. When we evaluate the function, the expression needs to figure out that the variable `x` is the function argument rather than the global variable before it can get to the value that the variable is referring to.

```r
x <- 1:100
f <- function(x) sqrt(sum(x))
f(x**2)
```

When we call the function we also have an expression that refers to a variable named `x` but this is a different `x` than the variable inside the function. This `x` is the global variable, so when we evaluate the function call expression R needs to figure out that `x` refers to the global variable and then look up the value that *this* variable is referring to.

We can make this clearer by changing the names, so the variables become unique. We call the global variable `gx` and the parameter variable `px`.

```r
gx <- 1:100
f <- function(px) sqrt(sum(px))
f(gx**2)
```

Because of lazy evaluation both the expression `gx**2` and the expression `sqrt(sum(px))` is actually evaluated inside function `f`. The expression being evaluated is `sqrt(sum(gx**2))`. The reason we can write the original version and let R figure out which `x` we are referring to when we have two different `x`s is that the scopes of the two `x`s are different. To evaluate the expression R needs to figure out what `gx` is pointing to, the vector `1:100`.

At the risk of causing some confusion with terms used in R, I will call the mapping from variable names to values the *environment* of an expression and the mapping from variable names to actual variables the *scope* of the expression. The risk of confusion is because if you evaluate an expression in R using the `eval` function you can provide an environment to evaluate the expression in, but this environment works both as the scope and environment. It can define mappings from variables to values, so it is an environment, but it also changes the scope the expression is evaluated in. If a variable in the expression exists in the environment, then the expression will refer to that variable and not the variable in the scope it would otherwise refer to.

We will not be doing a lot of manipulations and evaluations of expressions in this book. It is the topic of another book in the series, *Meta-programming in R*. I will just give you a short example of what I mean here.

When you write an expression such `x + y` you have an expression where variables `x` and `y` are defined in a scope. If you evaluate the expression, you get the value of the expression using the values that the variables in the scope are referring to.

```{r}
x <- 2 ; y <- 2
x + y
```

You can also create an expression that doesn't have a scope associated. It can have variables, but these are just variable names. As long as we do not evaluate the expression, they do not even have to exist in any scope. We can create such an expression using the `quote` function.

```{r}
quote(x + y)
```

We can use the `eval` function to evaluate such an expression. To evaluate the expression we, of course, need both a scope, to figure out which variables the variable names refer to, and an environment that tells us which values these variables are pointing to. By default, `eval` will use the scope where you call `eval`.

If we write

```{r}
eval(x + y)
```

there is nothing special going on. Lazy-evaluation aside, the expression `x + y` already has a scope, here the global scope, and the expression will be evaluated there.

If we instead write

```{r}
eval(quote(x + y))
```

the quoted expression is put in a scope, so the variable names in the expression that were just names before now refers to variables in the scope, and the expression is then evaluated in that scope.

The result is the same in this example because the scope that is used is the same (global) scope.

To see the difference we need to provide `eval` with an environment in which to evaluate the expression.

You can create an environment using the `new.env` function and put a variable in it by assigning to a name in it using `$`.

```{r}
env <- new.env()
env$x <- 4
```

We can also use a shortcut and create the environment and assign a value to a variable inside it using the function `lst2env`. This would look like this

```{r}
env <- list2env(list(x = 4))
```

If we evaluate the unquoted expression in this environment, we get the same result as before. In that expression `x` and `y` already have a scope and that is what is being used.

```{r}
eval(x + y, env)
```

However, if we use the quoted expression then `env` overrides the scope we are using. When `quote(x + y)` is evaluated `eval` figures out that `x` should be found in the scope defined by `env`, and looks up the value in the corresponding environment, while `y`, which is not defined in `env`, should be found in the enclosing scope and found in that environment.

```{r}
eval(quote(x + y), env)
```

```{r, echo=FALSE}
rm(x) ; rm(y) ; rm(env)
```

The function `eval` changes both scope and environment at the same time, but conceptually scope and environment are two different things. What `eval` considers an environment is what I describe as both scope and environment. The reason that scope and environment are conflated in `eval` is that the two things are inherently linked in R. R has an explicit representation of environments but only an implicit representation of scopes; scopes are defined by the algorithm R uses to figure out which actual variable a variable name is referring to.



## Environment chains, scope, and function calls

When you call a function in R, you first create an environment for that function. That environment is where its parameters will be stored and any local variables the function assigns to will go there as well. That environment is linked to another environment. If the function is defined inside another function it will be the environment in that function instantiation; if the function is called directly from the outermost level, it will be linked to the global environment. Depending on how the function is defined there might be many such linked environment and it is this chain of environments that determines the scope used to find a variable and get its value.

We need another example to see this in action. 

```r
f <- function(x) 2 * x
x <- 4
f(2)
```

I will use the following notation to explain how the scopes and environments work: `"v` refers to a variable name. I will write environments as mappings from variable names to values like this `["v -> value]`. Environments are chained so I will write `["v -> value1] -> ["w -> value2]` to mean that I have a chain of environments where the first environment maps variable name `"v` to `value1` and the next in the chain maps variable `"w` to `value2`.

When I have need for more complex chain graphs I will use a graphical notation as shown in +@fig:environment-chain-graph.

![Environment chain graph](figures/environment-chain-graph){#fig:environment-chain-graph}

If we assume that there are no variables in the global environment when we start the program, we have the global environment `[]`.^[The global environment is actually a little more complex than the empty one we use here. It is nested inside environments where imported packages live. But for the purpose of this chapter, we do not need to worry about that.] After we evaluate the first expression, the definition of function `f`, we have changed the global environment, so it now maps `"f` to that function.

```
["f -> function(x) 2 * x]
```

The next expression assigns a value to the variable `x` so after that the global environment is this:

```
["f -> function(x) 2 * x, "x -> 4]
```

In the third expression, we call function `f` and a lot is going on here. First R needs to figure out what the variable name `"f` is referring to. It searches in the chain of environments---in this case a chain of only one environment---and finds it in the global environment. So at this point, the scope of the variable `f` is the global environment. It can get the value from that environment, and it gets the function `function(x) 2 * x`.

When we call the function R creates a new environment to execute the function instance in. This environment is first empty, but it is linked to the global scope.

```
[] -> ["f -> function(x) 2 * x, "x -> 4]
```

Before any of the code in the function starts executing, though, the function parameters are put into this environment, so when we start executing the code in function `f` the environment chain looks like this:

```
["x -> 2] -> ["f -> function(x) 2 * x, "x -> 4]
```

Inside the function, we need to evaluate the expression `2 * x`. To find out how to, we first need to figure out what the variable name `"x` refers to. Here R starts searching in the chain of environments and find it in the first environment. So the scope of `"x`  is the local environment; it is not the variable in the global environment that also has variable `x` defined. The result of the function call is therefore 4 rather than 8 as it would have been if `"x` was referring to the global variable `x`.

After the function returns, R removes the first environment from the chain, and future code will be evaluated in the environment chain

```
["f -> function(x) 2 * x, "x -> 4]
```

This is simple enough, but what happens if we next call the function like this?

```
f(3 * x)
```

The first steps are the same as before. R looks for `"f`, finds that it is a function, instantiate it, and creates an environment for it execute in.

```
[] -> ["f -> function(x) 2 * x, "x -> 4]
```

As before, it then puts the function parameter into this environment, but now it gets a little more complicated. Remember that R doesn't evaluate the expression used for function arguments before it calls the function. When we called `f` with the value `1` it actually did pass the value along. If we had written `f(x)` it would as well, but here we call `f` with an expression and that expression is not evaluated before it is used inside the function call.

Such an expression is passed to the function in a type called "call" and such a type has its own associated environment chain. This environment chain starts in the environment where the function is *called*, not the environment inside the function. So the call object has an environment chain that starts at the global environment. So the chain (now a graph) of environments is as shown in +@fig:environment-chain-graph-lazy-evaluation.

![Environment chain graph](figures/environment-chain-graph-lazy-evaluation){#fig:environment-chain-graph-lazy-evaluation}


When we evaluate the expression inside the function, `2 * x`, R goes searching for `"x` and finds it in the first environment. It sees that it is referring to a call so to get a value it needs to evaluate this call. Because the call has its own environment chain it will use this chain to evaluate the expression. So evaluating the *call* `2 * x` it uses this chain:

```
["f -> function(x) 2 * x, "x -> 4]
```

Here it finds that the variable name `"x` is mapped to 4, so it evaluates `3 * 4` and we get the value 12 back. This is then inserted into the environment for the function call so future evaluations will refer to the value and not the call expression.

```
["x -> 12] -> ["f -> function(x) 2 * x, "x -> 4]
```

It is now in this environment we search for `"x` and find 12 that we use to evaluate `2 * x` and get 24.

We have two different variables `x` in play here. The both use the variable name `"x` but they are associated with different environment chains and are therefore in different scopes.

We can now go back to the `eval` example and see what is really going on.

```r
x <- 2 ; y <- 2
env <- new.env() 
env$x <- 4
eval(x + y, env)
```

The first two assignments just puts values in the global environment. After these the global environment looks like this:

```
["x -> 2, "y -> 2]
```

Then we create a new environment. By default, that environment will be linked to the current environment chain, so we are actually creating this environment chain

```
[] -> ["x -> 2, "y -> 2]
```

and we are inserting that into the global environment by assigning it to the name `env`. So we have a new global environment that knows about `env` but `env` also knows about the global environment because it has a chain to it.

```
                            .---.
["x -> 2, "y -> 2, "env -> []]<-'
```

Into the new environment we assign the value 4 to variable `x` so we now have

```
                              .--------.
["x -> 2, "y -> 2, "env -> ["x -> 4]]<-'
```

When we then call `eval`, we create yet another environment, the one for the function instantiation, and gives it the expression `x + y` together with the environment `env`. The parameter that `eval` uses to refer to the expression is called `expr`, so that is put into its environment together with `env`. (There actually is another parameter, but we ignore this in this example). So when `eval` is ready to evaluate the expression we give it, the environment chain looks like in +@fig:eval-chain-graph-1. In the figure the global environment is shown with double-strokes and the environment inside the `eval` function is shown on the left.

![Environment chain graph in eval(x + y, env).](figures/eval-chain-graph-1){#fig:eval-chain-graph-1}

The `eval` function doesn't evaluate the expression inside its own environment, however, but inside the environment pointed to by its `env` parameter. So the expression is evaluated in the environment to the right in +@fig:eval-chain-graph-1.

It doesn't matter, though, whether it evaluated the expression in its own environment or in `env` because the expression is a call, with its own environment chain, consisting in this case just of the global environment, and that is the environment the call object will be evaluated in. In this environment, it finds both variable names `"x` and `"y`, and find them to refer to value 2 and 2, so that determines the result.

For the `eval` call with the quoted expression

```r
eval(quote(x + y), env)
```

the situation is different. Here `eval` gets a quoted expression, not a call, so this expression does not carry its own environment along with it. The environment chain graph is shown in +@fig:eval-chain-graph-2. The `eval` function does the same thing, it evaluates the expression in the environment pointed to by `env`, which is the rightmost environment in the figure. So when R needs to look up variable names `"x` and `"y` it finds `"x` in the first environment and `"y` in the global environment. The `"x` in the global environment is overshadowed by the `"x` in the first environment so is not the variable in the scope of the evaluation. Thus the values used in evaluating the expression are 4 and 2.

![Environment chain graph in eval(quote(x + y), env).](figures/eval-chain-graph-2){#fig:eval-chain-graph-2}

Scopes are not static. They always depend on the environment chain expressions are evaluated in and what these environments look like at the time the expressions are evaluated. Consider the program below.

```{r}
y <- 2
f <- function(x) {
    result <- x + y
    y <- 3
    return(result)
}
f(2)
```

After evaluating the two first expressions, the assignment to `y` and `f`, we have a global environment that looks like this:

```
["y -> 2, "f -> function(x) ...]
```

When we start evaluating the body of function `f`, after the parameter has been added to its environment, the current environment chain looks like this:

```
["x -> 2] -> ["y -> 2, "f -> function(x) ...]
```

When we evaluate the `x + y` expression, R will search for these parameter names and find `"x` in the local environment and `"y` in the global environment, so the scope of `"x` is local and the scope of `"y` is global. The result is therefore 4 which is put in the local variable `result`. So now the environment chain is

```
["x -> 2, "result -> 4] -> ["y -> 2, "f -> function(x) ...]
```

We then assign the value 3 to a local variable and get the environment chain

```
["x -> 2, "result -> 4, "y -> 3] -> 
    ["y -> 2, "f -> function(x) ...]
```

Now both `x` and `y` have local scope. It doesn't matter for the result, though. We have already evaluated the expression `x + y` to get the result so what we return is 4, not 6.

Situations like this don't just happen when we assign to a local variable later in a function. If we conditionally assign to a local variable, this is also in effect. In the function below, when we evaluate `x + y` the scope of these parameters depend on whether we assigned to them before we evaluated the expressions. So these variables can have local or global scope depending on which parameters we called the function with.

```{r}
f <- function(condx, x, dondy, y) {
    if (condx) x <- 2
    if (condy) y <- 2
    x + y
}
```

So to briefly summarise how scopes and environments work in R: whenever you evaluate an expression, there is an associated chain of environments. The scope of the variables in the expression, which variables the actual variable names refer to, depends on where in this chain the variables can be found. While data is immutable in R, environments are not; whenever you assign to a variable with the ``\<-`` operator you are modifying the top environment in the environment chain. This can not only change the value a variable refers to but also its scope. If we assign to a variable inside a function, we are only changing the environment inside that function. Other functions that might be referring to a global variable with the same name will still be referring to the global variable, not the new local variable because the environment that will be created when these functions will not be chained to the local environment where a new variable has been put.

The rules for how variables are mapped to values are always the same. It involves a search in the chain of environments that are active at the time the expression is evaluated. The only difficulty is knowing which environments are in the chain at any given time.

Here the rules are not that complex either. We can explicitly create an environment and put it at the top of the chain of environments using the `eval` function, we can create a "call" environment when we pass expressions as arguments to a function---where the environment will be the same environment chain as where we call the function---or we can create a new environment by running code inside a function.


## Scopes, lazy-evaluation, and default parameters

Knowing the rules for how variables are mapped into values also helps us understand why we can use function parameters in expressions use for default parameters when defining a function, but we cannot use them when we call a function.

If we define a function with a default parameter set to an expression that refers to another parameter

```{r}
f <- function(x, y = 2 * x) x + y
```

we can call it like this

```{r}
f(x = 2)
```

but not necessarily like this

```r
f(x = 2, y = 2 * x)
```

In both cases the function body will execute in an environment chain where the parameters have been put, and in both cases `y` will refer to a call object.

```
["x -> 2, "y -> call(2 * x)] -> <global environment>
```

The difference between the two calls is which environment the call object is associated with. The difference is illustrated in +@fig:default-parameters-environment-chain. The call object defined as the default parameter will be evaluated in an environment chain starting with the local function environment. The call object passed along in the function call, however, will be evaluated in the global environment because that is where we call the function from.

![Environment chain graph in f(x = 2, y = 2 \* x) and f(x = 2).](figures/default-parameters-environment-chain){#fig:default-parameters-environment-chain}

In the second function call, `x` will, therefore, be referring to a variable in the global environment when we evaluate the expression for `y`. If `x` is not defined there, we get an error. If `x` *is* defined there, but we meant `y` to be referring to the parameter `x` and not the global variable `x`, we have a potentially hard to debug error.

It is not an error that pops up often. I have never seen it in the wild. When people call a function, they expect the expressions in the function call to be referring to variables in the environment where the function is called, not some local variables inside the function body, and that is what they get by this semantics.

## Nested functions and scopes

Whenever you instantiate a function, you create a new environment in which to execute its body. That environment is chained to the global environment in all the functions we have considered so far in this chapter, but for functions defined inside the body of other functions, the environment will instead be chained to the environment created by the outer function.

Let us first see a simple example of this. Consider the program below:

```{r}
f <- function(x) {
    g <- function(y) x + y
    g(x)
}
f(2)
```

Ignoring that there can be other variables in the global environment, the environment chain just before we call `g` inside `f` looks like this:

```
["x -> 2, "g -> function(y) x + 1] -> 
    ["f -> function(x) ...]
```

Here `x` is referring to the value 2 and not a call since we passed a constant value along to `f` when we called the function.

When we call `g` we now get a new environment, as we do for all function calls and where function parameters are put before we evaluate anything else, but this environment is linked not to the global environment but the environment inside the function call to `f` where `g` was defined. So when we evaluate the expression `x + y` we have the following chain of environments

```
["y -> 2] ->
    ["x -> 2, "g -> function(y) x + 1] -> 
        ["f -> function(x) ...]
```

and it is in this chain we find the variables `x` and `y` to get their values.

Here is a slightly more complex example:

```{r}
f <- function(x) {
    g <- function(y) x + y
    g
}
h <- f(2)
h(2)
```

Just before we return from the function call to `f` the environment chain looks like before

```
["x -> 2, "g -> function(y) x + 1] -> 
    ["f -> function(x) ...]
```

and after we return it looks like this:

```
["f -> function(x) ..., "h -> function(y) ...]
```

We have defined two functions and assigned them to variables `f` and `h`. What happens when we then call `h`? It turns out that the environment chain, after we have put parameter variables into the new function call environment, will look like this:

```
["y -> 2] ->
    ["x -> 2, "g -> function(y) x + 1] -> 
        ["f -> function(x) ...]
```

The environment from the function call to `f` is back in play. When we call the function `h` we instantiate a function, `g`, that was defined inside a call to `f`, and this function remembers that environment. When we call this function, it will chain its local environment to the environment in which it was defined, which is a local environment inside `f`.

Functions, when called, will always chain their local environment to the environment in which they were defined. There are not actually two rules for how the environments are chained together; it is just that functions defined in the global environment will be chained to that environment and functions defined in other environments will be chained to those.

All functions have an associated environment they will chain their local environments to. I just haven't shown that in the environment chains so far. From now on I will. Think of functions as similar to call objects. Call objects are actually function calls, so they behave in much the same way; functions you just have to explicitly call where call objects are evaluated when you need their value.

Just for fun, let us call `f` twice and create two functions referring to the inner function `g`.

```{r}
h1 <- f(1)
h2 <- f(2)
```

The environment chain graph after we have defined these two functions is shown in +@fig:function-environments-environment-chain. Here functions are shown in grey, and each function points to the environment its instances will be chained to. There are three functions, `f`, `h1`, and `h2`. Even though both `h1` and `h2` were constructed from the function `g` inside `f` they were constructed in different calls to `f`, so they are different functions with different environments.

![Environment chain graph after defining h1 and h2.](figures/function-environments-environment-chain){#fig:function-environments-environment-chain}

If we call `h1` we will create an environment chain that first has its local environment, then the environment created when `h1` was defined, the environment that remembers that variable `x` refers to 1, and then the global environment. If we instead call `h2` we will have the chain from the local environment to the instance of `f` where `x` was 2 and then the global environment.

This environment chain graph is determined by where the functions are defined not where they are called. If we define a global function `g` that takes a function as an argument and calls that function with the value 1, we can see what happens.

```{r}
gg <- function(ff) ff(1)
gg(h1)
gg(h2)
```

The global environment will know `f`, `gg`, `h1`, and `h2`. When we call `gg` we get a local environment where `ff` now refers either `h1` and `h2` depending on which call we consider. Inside the call to `gg` the environment chain looks like this

```
["ff -> <a h function>] -> <global environment>
```

where `<a h function>` refers to the functions that either `h1` or `h2`.

When `gg` then calls the (local) function `ff` we create another local environment in which to execute the function. This environment is chained to the environment the function remembers, not the local environment for `gg`. We call `gg(h1)` we need to evaluate the expression `x + y` and we will do that in an environment chain that looks like this:

```
["y -> 1] ->
    ["x -> 1, "g -> <function(y) ...>] ->
        <global environment>
```

The local environment for `gg` is nowhere in this chain. When we call `h1` through `gg` the function `h1` doesn't know anything about `gg`. It knows the environment in which it was created, the instance of `f`, and because this environment is chained to the global environment it knows about that as well. It doesn't know where it is being called from, only where it was defined.

This rule for finding variable's values, based on the environment where functions are defined, is called *lexical scoping* and is the most common standard for scopes. They are called that because you can, in principle, figure out what variables in an expression are defined where. You first check if the variables are set in the local environment, so either local variables or function parameters. If not, then you look at the enclosing code and check if the variable is in the environment. The enclosing code can be the global environment or a function. If is a function and the variables are not defined there you work your way further out in the code where the function is defined. If the mapping from variables to values depended on where a function was *called* rather than where it was defined, something called *dynamic scope*, you couldn't figure out what variables variable names were referring to just from reading the code where the function is defined.

Figuring out the variable name to variable mapping in R is not quite so easy that you can just figure it out from the code. The problem is that which variables are defined depends on the code executed in function calls, so it is only known at runtime. We saw an example of this earlier. That is why I told you the whole complicated story rather than just the simple rule of thumb; sometimes the rule just isn't true. If you are careful and never do conditional assignments to variables without first giving them a default value, though, the rule of thumb applies.


## Closures

Functions like `h1` and `h2` that remembers the environment of another function invocation are what we call closures. The term derives from *enclosing scope* and refers to the property these functions have, of remembering the enclosing environment in which they were created.

With the definition I gave at the beginning of the chapter, that closures are functions that carry a scope with them, in practise functions that have an environment chain, all functions in R are closures. But we will restrict the term to mean functions that remember an environment from a previous function instantiation that is no longer active. Because functions in R remember the environment in which they were created, the only thing that is required for a function to be a closure is that we return it from a function call.

The function `f` in the previous example creates closures. It creates an environment in which `x` is known and returns a function that adds that `x` to its input. With more sensible names, the creation of `h1` and `h2` can be written like this, making it clearer what the functions are really doing.

```{r}
make_adder <- function(x) {
    add_y <- function(y) x + y
    add_y
}
add1 <- make_adder(1)
add2 <- make_adder(2)
```

In themselves, closures are not that useful. Making a function that takes one argument and returns another function that takes a second argument just so we can call the second function to do some operation, is just a very complex way of doing the operation; writing a function that takes two arguments is much simpler. The usefulness of closures is in combination with higher-order functions. Higher-order functions are functions that either take other functions as arguments or return functions. A function that creates a closure is thus a higher-order function, and where closures are used is with higher-order functions that take functions as input. We return to such functions in the chapter [Higher-order Functions] where we will see many uses for closures.

## Reaching outside your inner-most scope

When we assign to a variable using the ```<-``` operator we modify the environment at the top of the current environment chain. We modify the local environment. So what does this code do?

```{r}
make_counter <- function() {
    x <- 0
    count <- function() {
        x <- x + 1
        x
    }
}
counter <- make_counter()
```

The intent behind the function is to create a function, a closure, that returns an increasing number each time we call it. It is of course not a pure function, but it is something we could find useful. In the depth-first-numbering algorithm, we wrote in the previous chapter we had to pass along in recursive calls the current number, but if we had such a counter we could just use *it* to get the next number each time we needed it.

It doesn't work, though.

```{r}
counter()
counter()
counter()
```

We can unwrap the function and see what is really going on. When we create the counter, we call the `make_counter` function, which creates an environment where `x` is set to zero and then the `count` function, which it returns.

When we call the `counter` function it knows `x` because it is a closure, so it can evaluate `x + 1` which it then assigns to `x`. This is where the problem is. The `x` used in evaluating `x + 1` is found by searching up the environment chain but the `x` the function assigns to is put in the `counter` function's environment. Then the function returns and that environment is gone. The next time `counter` is called it is a new function instance, so it is a new environment that is created. The variable `x` from the `make_counter` function is never updated.

When you use ``\<-`` you create a new local variable if it didn't exist before. Even if the variable name is found deeper in the environment chain, it doesn't matter. The assignment always is to the local environment.

To assign to a variable deeper in the environment chain you need to use the operator ``\<\<-`` instead. This operator will search through the environment chain, the same way as R does to figure out what expressions should evaluate to, and update the environment where it finds the variable (or add it to the global environment if it doesn't find it anywhere in the environment chain).

If we change the assignment operator in the example, we can see what happens.

```{r}
make_counter <- function() {
    x <- 0
    count <- function() {
        x <<- x + 1
        x
    }
}
counter <- make_counter()
counter()
counter()
counter()
```

This time around, when we do the assignment we find that there is an `x` in the enclosing environment, the `x` that was initialised when we called `make_counter`, so the assignment is to that environment instead of to the local environment. Each time we call `counter` we create a new function instance environment but all the instances are linked to the same enclosing environment so each time we call the function we are updating the same environment.

We can use this counter function together with the ``\<\<-`` operator to make a much simpler version of the `depth_first_numbers` function where we do not need to pass data along in the recursive calls. We can create a table and a counter function in the outermost scope and simply use the counter and assign, with ``\<\<-`` to the table.

```{r}
depth_first_numbers <- function(tree) {
  table <- c()
  counter <- make_counter()

  traverse_tree <- function(node) {
    if (is.null(node$left) && is.null(node$right)) {
      dfn <- counter()
      node$range <- c(dfn, dfn)
      table[node$name] <<- dfn
      node
    
    } else {
      left <- traverse_tree(node$left)
      right <- traverse_tree(node$right)
      new_node <- make_node(node$name, left, right)
      new_node$range <- c(left$range[1], right$range[2])
      new_node
    }
  }

  new_tree <- traverse_tree(tree)
  list(tree = new_tree, table = table)
}
```
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

tree <- make_node("root", 
                  make_node("C", make_node("A"), 
                                 make_node("B")),
                  make_node("D"))
```
```{r}
result <- depth_first_numbers(tree)
print_tree(result$tree)
result$table
```

We still need to create a new tree here if we want to annotate all nodes with their depth-first-number ranges, we still cannot modify data, but we can use the variables in the outer scope inside the recursive function.

## Lexical scope and dynamic scope

The last thing I want to mention in this chapter is how R supports dynamic scope in addition to lexical scope. It is not something we will use further in this book, but a discussion of R's scope rules would be incomplete without it.

I will return to the `eval` example we had before.

```{r}
x <- 2; y <- 2
eval(quote(x + y))
```

Here we create a quoted expression, `x + y`, so `x` and `y` do not refer to any variables, they are just variable names, and then we evaluate that expression. In doing so, `eval` manages to find the variables to do so in the global environment. There is nothing surprising here; all functions can find the variables in the global environment.

But consider this example where we remove the global variables for `x` and `y` and call `eval` inside a function that has them as local variables:

```{r}
rm(x); rm(y)
f <- function() {
    x <- 2; y <- 2
    eval(quote(x + y))
}
f()
```

You might not be surprised that `eval` manages to do this, after all, it is what you would expect it to do, but it doesn't follow the rules I have told you about how functions know their environment chain. The `eval` function is not defined inside the `f` function so it shouldn't know about these parameters. Somehow, though, it manages to get them anyway.

This is because R supports dynamic scope as well as lexical scope. Remember, dynamic scope is where we find variables based on which functions are on the call-stack, not which functions are lexically enclosing the place where we define them.

The `eval` function manages to get the calling scope, instead of the enclosing scope, using the function `parent.frame`. Using this function, you can get to the environment of functions on the call stack.

These call-stack environments are not chained. They behave just as I have described earlier. So you cannot do this

```r
g <- function(y) {
  y
  eval(quote(x + y))
}
f <- function(x) {
  g(2)
}
f(2)
```

but you can do this:

```{r}
f <- function(x) {
  x <- x
  g <- function(y) {
    y
    eval(quote(x + y))
  }
  g(2)
}
f(2)
```

To test if you have understood the environment and scope rules in R, I suggest you take a piece of paper and write down the environment chain graph for this example and work out why the first does not work but the second does.

