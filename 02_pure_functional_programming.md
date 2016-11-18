
# Pure Functional Programming

A "pure" function is a function that behaves like a mathematical function: it maps values from one space to another, the same value always maps to the same result, and there is no such thing as "side effects" in a mathematical function.

The level to which programming languages go to ensure that functions are pure varies and R does precious little. Because values are immutable you have some guarantee about which side-effects functions can have, but not much. Functions can modify variables outside their scope, for example, modify global variables. They can print or plot and alter the state of the R process this way. They can also sample random numbers and use them for their computations, making the result of a function non-deterministic, for all intents and purposes, so the same value does not always map to the same result.

Pure functions are desirable because they are easier to reason about. If a function does not have any side-effects, you can treat it as a black box that just maps between values. If it has side-effects, you will also need to know how it modifies other parts of the program and that means you have to understand, at least at some level, what the body of the function is doing. If all you need to know about a function is how it maps from input parameters to results, you can change their implementation at any point without breaking any code that relies on the functions.

Non-deterministic functions, functions whose result is not always the same on the same input, are not necessarily hard to reason about. They are just harder to test and debug if their results depend on random numbers.

Since pure functions are easier to reason about, and to test, you will want to write as much of your programs using pure functions. You cannot necessarily write *all* your programs in pure functions. Sometimes you need randomness to implement Monte Carlo methods, or sometimes you need functions to produce output. But if you write most of your program using pure functions, and know where the impure functions are, you are writing better and more robust programs.


## Writing pure functions

There is not much work involved in guaranteeing that a function you write is pure. You should avoid sampling random numbers and stay away from modifying variables outside the scope of the function.

It is trivial to avoid sampling random numbers. Don't call any function that does it, either directly or through other functions. If a function only calls deterministic functions and doesn't introduce any randomness itself, then the function will be deterministic.

It is only slightly less trivial to guarantee that you are not modifying something outside of the scope of a function. You need a special function, `<<-`, to modify variables outside of a function's local scope (we return to this operator in the next chapter), so avoid using that. Then all assignments will be to local variables, and you cannot modify variables in other scopes. If you avoid this operator, then the only risk you have of modifying functions outside of your scope is through lazy-evaluation. Remember the example from the previous chapter where we created a list of functions. The functions contained unevaluated expressions whose values depended on a variable we were changing before we evaluated the expressions.

Strictly speaking, we would still have a pure function if we returned functions with such an unevaluated expression, that depended on local variables. Even the functions we would be returning would be pure. They would be referring to local variables in the first function, variables that cannot be changed without the `<<-` operator once the first function returns. They just wouldn't necessarily be the functions you intended to return.

While such a function would be pure by the strict definition, they do have the problem that the functions we return depend on the state of local variables inside the first function. From a programming perspective, it doesn't much help us that the functions are pure if they are hard to reason about, and in this case, we would need to know how changing the state in the first function affects the functionality of the others.

A solution to avoid problems with functions depending on variables outside their own scope, that is variables that are not either arguments or local variables, is to simply never change what a variable points to.

Programming languages that guarantee that functions are pure enforce this. There simply isn't any way to modify the value of a variable. You can define constants, but there is no such thing as variables. Since R does have variables, you will have to avoid assigning to the same variable more than once if you want to guarantee that your functions are pure in this way.

It is very easy to accidentally reuse a variable name in a long function, even if you never intended to change the value of a variable. Keeping your functions short and simple alleviates this somewhat, but there is no way to guarantee that it doesn't happen. The only control structure that actually forces you to change variables is `for`-loops. You simply cannot write a `for`-loop without having a variable to loop over.

Now `for`-loops have a bad reputation in R, and many will tell you to avoid them because they are slow. This is not true. They are slow compared to loops in more low-level languages, but this has nothing to do with them being loops. Because R is a very dynamic language where everything you do involves calling functions, and functions that can be changed at any point if someone redefines a variable, R code is just generally slow. When you call built-in functions like `sum` or `mean` they are fast because they are implemented in C. By using vectorized expressions and built-in functions you do not pay the penalty of the dynamism. If you write a loop yourself in R, then you do. You pay the same price, however, if you use some of the other constructions that people recommend instead of loops; constructions we will return to in the *[Filter, Map, and Reduce]* chapter.

The real reason you should use such other constructions is that they make the intent behind your code clearer than a loop will do, at least once you get familiar with functional programming, and because you avoid the looping variable that can cause problems. The reason people often find that their loops are inefficient is that it is very easy to write loops that "modify" data, forcing R to make copies. This problem doesn't go away just because we avoid loops and is something we return to later towards the end of this chapter.


## Recursion as loops

The way functional programming languages avoid loops is by using recursion instead. Anything you can write as a loop you can also write using recursive function calls and most of this chapter will be focusing on getting used to thinking in terms of recursive functions.

Thinking of problems as recursive is not just a programming trick for avoiding loops. It is generally a method of breaking problems into simpler sub-problems that are easier to solve. When you have to address a problem, you can first consider whether there are base cases that are trivial to solve. If we want to search for an element in a sequence, it is trivial to determine if it is there if the sequence is empty. Then it obviously isn't there. Now, if the sequence isn't empty we have a harder problem, but we can break it into two smaller problems. Is the element we are searching for the first element in the sequence? If so, the element is there. If the first element is not equal to the element we are searching for, then it is only in the sequence if it is the remainder of the sequence.

We can write a linear search function based on this breakdown of the problem. We will first check for the base case and return `FALSE` if we are searching in an empty sequence. Otherwise, we check the first element, if we find it, we return `TRUE`, and if it wasn't the first element we call the function recursively on the rest of the sequence.

```{r, echo=FALSE}
is_empty <- function(x) length(x) == 0
first <- function(x) x[1]
rest <- function(x) {
    if (length(x) == 1) NULL
    else x[2:length(x)]
}
```
```{r}
lin_search <- function(element, sequence) {
    if (is_empty(sequence))              FALSE
    else if (first(sequence) == element) TRUE
    else lin_search(element, rest(sequence))
}

x <- 1:5
lin_search(0, x)
lin_search(1, x)
lin_search(5, x)
lin_search(6, x)
```

I have hidden away the test for emptiness, the extraction of the first element and the remainder of the sequence in three functions, `is_empty`, `first`, and `rest`. For a vector they can be implemented like this:

```{r}
is_empty <- function(x) length(x) == 0
first <- function(x) x[1]
rest <- function(x) {
    if (length(x) == 1) NULL else x[2:length(x)]
}
```

A vector is empty if it has length zero. The first element is of course just the first element. The `rest` function is a little more involved. The indexing `2:length(x)` will give us the vector `2 1` if `x` has length 1, so I handle that case explicitly.

Now this search algorithm works, but you should never write code like the `rest` function I just wrote. The way we extract the rest of a vector by slicing will make R copy that sub-vector. The first time we call `rest`, we get the entire vector minus the first element, the second time we get the entire vector minus the first two, and so on. This adds up to about half the length of the vector squared. So while the search algorithm should be linear time, the way we extract the rest of a vector makes it run in quadratic time.

In practice, this doesn't matter. There is a limit in R on how deep we can go in recursive calls and we will reach that limit long before performance becomes an issue. We return to these issues at the end of the chapter, but for now let we will just, for aesthetic reasons, avoid a quadratic running time algorithm if we can make a linear time algorithm.

Languages that are built for using recursion instead of loops usually represent sequences in a different way; a way where you can get the rest of a sequence in constant time. We can implement a version of such sequences by representing the elements in the sequence by a structure that has a `next` variable that points to the remainder of the sequence. Let us call that kind of structure a *next list*. This is an example of a *linked list*, but there are different variants of linked lists and this one just has a "next-pointer" to the rest of the sequence, so I prefer to call it a *next list*. We can translate a single element into such a sequence using this function:

```{r}
next_list <- function(element, rest = NULL)
    list(element = element, rest = rest)
```

and construct a sequence by nested calls of the function, similarly to how we constructed a tree in the previous chapter

```{r}
x <- next_list(1, 
               next_list(2, 
                         next_list(3, 
                                   next_list(4))))

```

For this structure we can define the functions we need for the search algorithm like this:

```{r}
nl_is_empty <- function(nl) is.null(nl)
nl_first <- function(nl) nl$element
nl_rest <- function(nl) nl$rest
```

and the actual search algorithm like this:

```{r}
nl_lin_search <- function(element, sequence) {
    if (nl_is_empty(sequence))              FALSE
    else if (nl_first(sequence) == element) TRUE
    else nl_lin_search(element, nl_rest(sequence))
}
```

This works fine, and in linear time, but constructing lists is a bit cumbersome. We should write a function for translating a vector into a next list. To construct such function, we can again think recursively. If we have a vector of length zero, the base case, then the next list should be `NULL`. Otherwise, we want to make a next list where the first element is the first element of the vector, and the rest of the list is the next list of the remainder of the vector.

```{r}
vector_to_next_list <- function(x) {
    if (is_empty(x)) NULL
    else next_list(first(x), vector_to_next_list(rest(x)))
}
```

This works, but of course, we have just moved the performance problem from the search algorithm to the `vector_to_next_list` function. This function still needs to get the rest of a vector, and it does it by copying. The translation from vectors to next lists takes quadratic time. We need a way to get the rest of a vector without copying.

One solution is to keep track of an index into the vector. If that index is interpreted as the index where the vector really starts, we can get the rest of the vector just by increasing the index. We could use these helper functions

```{r}
i_is_empty <- function(x, i) i > length(x)
i_first <- function(x, i) x[i]
```

and write the conversion like this:

```{r}
i_vector_to_next_list <- function(x, i = 1) {
    if (i_is_empty(x, i)) NULL
    else next_list(i_first(x, i), i_vector_to_next_list(x, i + 1))
}
```

Of course, with the same trick we could just have implemented the search algorithm using an index.

```{r}
i_lin_search <- function(element, sequence, i = 1) {
    if (i_is_empty(sequence, i))              FALSE
    else if (i_first(sequence, i) == element) TRUE
    else i_lin_search(element, sequence, i + 1)
}
```

Using the index implementation, we can't really write a `rest` function. Writing a function that returns a pair of a vector and an index is harder to work with than just incrementing the index itself.

When you write recursive functions on a sequence, the key abstractions you need will be checking if the sequence is empty, getting the first element, and getting the rest of the sequence. Using functions for these three operations doesn't help us unless these functions would let us work on different data types for sequences. It is possible to make such abstractions, but it is the topic for the *Object oriented programming in R* book of this series, and we will not consider it more in this book. Here will just implement the abstractions directly in our recursive functions from now on. If we do this, the linear search algorithm simply becomes.

```{r}
lin_search <- function(element, sequence, i = 1) {
    if (i > length(sequence)) FALSE
    else if (sequence[i] == element) TRUE
    else lin_search(element, sequence, i + 1)
}
```
```{r, echo=FALSE}
assert(lin_search(0, 1:5) == FALSE)
assert(lin_search(1, 1:5) == TRUE)
```


## The structure of a recursive function

Recursive functions all follow the same pattern: figure out the base cases, that are easy to solve, and understand how you can break down the problem into smaller pieces that you can solve recursively. It is the same approach that is called "divide and conquer" in algorithm design theory. Reducing a problem to smaller problems is the hard part. There are two things to be careful about: Are the smaller problems *really* smaller? How do you combine solutions from the smaller problems to solve the larger problem?

In the linear search we have worked on so far, we know that the recursive call is looking at a smaller problem because each call is looking at a shorter sequence. It doesn't matter if we implement the function using lists or use an index into a vector, we know that when we call recursively, we are looking at a shorter sequence. For functions working on sequences, this is generally the case, and if you know that each time you call recursively you are moving closer to a base case you know that the function will eventually finish its computation.

The recursion doesn't always have to be on everything except the first element in a sequence. For a binary search, for example, we can search in logarithmic time in a sorted sequence by reducing the problem to half the size in each recursive call. The algorithm works like this: if you have an empty sequence you can't find the element you are searching for, so you return `FALSE`. If the sequence is not empty, you check if the middle element is the element you are searching for, in which case you return `TRUE`. If it isn't, check if it is smaller than the element you are looking for, in which case you call recursively on the last half of the sequence, and if not, you call recursively on the first half of the sequence.

This sounds simple enough but first attempts at implementing this often end up calling recursively on the same sequence again and again, never getting closer to finishing. This happens if we are not careful when we pick the first or last half.

This implementation will not work. If you search for 0 or 5, you will get an infinite recursion.

```{r}
binary_search <- function(element, x, 
                          first = 1, last = length(x)) {

    if (last < first) return(FALSE) # empty sequence
  
    middle <- (last - first) %/% 2 + first
    if (element == x[middle]) {
        TRUE
    } else if (element < x[middle]) {
        binary_search(element, x, first, middle)
    } else {
        binary_search(element, x, middle, last)
    }
}
```

This is because you get a `middle` index that equals `first`, so you call recursively on the same problem you were trying to solve, not a simpler one.

You can solve it by never including `middle` in the range you try to solve recursively -- after all, you only call the recursion if you know that `middle` is not the element you are searching for.

```{r}
binary_search <- function(element, x, 
                          first = 1, last = length(x)) {

    if (last < first) return(FALSE) # empty sequence
  
    middle <- (last - first) %/% 2 + first
    if (element == x[middle]) {
        TRUE
    } else if (element < x[middle]) {
        binary_search(element, x, first, middle - 1)
    } else {
        binary_search(element, x, middle + 1, last)
    }
}
```
```{r, echo=FALSE}
assert(binary_search(0, 1:5) == FALSE)
assert(binary_search(1, 1:5) == TRUE)
assert(binary_search(2, 1:5) == TRUE)
assert(binary_search(3, 1:5) == TRUE)
assert(binary_search(4, 1:5) == TRUE)
assert(binary_search(5, 1:5) == TRUE)
assert(binary_search(6, 1:5) == FALSE)
```

It is crucial that you make sure that all recursive calls actually are working on a smaller problem. For sequences, that typically means making sure that you call recursively on shorter sequences.

For trees, a data structure that is fundamentally recursive -- a tree is either a leaf or an inner node containing a number of children that are themselves also trees -- we call recursively on sub-trees, thus making sure that we are looking at smaller problems in each recursive call.

The `node_depth` function we wrote in the first chapter is an example of this.

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

The base cases deal with an empty tree -- an empty tree doesn't contain the node we are looking for, so we trivially return `NA`. If the tree isn't empty, we either have found the node we are looking for, in which case we can return the result. If not, we call recursively on the left tree. We return the result if we found the node we were looking for. Otherwise, we return the result of a recursive call on the right tree (whether we found it or not, if the node wasn't in the tree at all the final result will be `NA`).

The functions we have written so far do not combine the results of the sub-problems we solve recursively. The functions are all search functions, and the result they return is either directly found or the result one of the recursive functions return. It is not always that simple, and often you need to do something with the result from the recursive call(s) to solve the larger problem.

A simple example is computing the factorial. The factorial of a number $n$, $n!$ is equal to $n\\times (n-1)!$ with a basis case $1!=1$. It is very simple to write a recursive function to return the factorial, but we cannot just return the result of a recursive call. We need to multiply the result we get from the recursive call with $n$.

```{r}
factorial <- function(n) {
    if (n == 1) 1
    else n * factorial(n - 1)
}
```

Here I am assuming that $n$ is an integer and $n\>0$. If it is not, the recursion doesn't move us closer to the basis case and we will (in principle) keep going forever. So here is another case where we need to be careful to make sure that when we call recursively, we are actually making progress on solving the problem. In this function, I am only guaranteeing this for positive integers.

In most algorithms, we will need to do something to the results of recursive calls to complete the function we are writing. As another example, besides `factorial`, we can consider a function for removing duplicates in a sequence. Duplicates are elements that are equal to the next element in the sequence. It is similar to the `unique` function built into R except that this function only removes repeated elements that are right next to each other.

To write it we follow the recipe for writing recursive functions. What is the base case? An empty sequence doesn't have duplicates, so the result is just an empty sequence. The same is the case for a sequence with only one element. Such a sequence does not have duplicated elements, so the result is just the same sequence. If we always know that the input to our function has at least one element, we don't have to worry about the first base case, but if the function might be called on empty sequences we need to take care of both. For sequences with more than one element, we need to check if the first element equals the next. If it does, we should just return the rest of the sequence, thus removing a duplicated element. If it does not, we should return the first element together with the rest of the sequence where duplicates have been removed.

A solution using next lists could look like this:

```{r}
nl_rm_duplicates <- function(x) {
    if (is.null(x)) return(NULL)
    else if (is.null(x$rest)) return(x)

    rest <- nl_rm_duplicates(x$rest)
    if (x$element == rest$element) rest
    else next_list(x$element, rest)
}

(x <- next_list(1, next_list(1, next_list(2, next_list(2)))))
nl_rm_duplicates(x)
```

To get a solution to the general problem, we have to combine the smaller solution we get from the recursive call with information in the larger problem. If the first element is equal to the first element we get back from the recursive call we have a duplicate and should just return the result of the recursive call, if not we need to combine the first element with the next list from the recursive call.

We can also implement this function for vectors. To avoid copying vectors each time we remove a duplicate we can split that function into two parts. First, we find the indices of all duplicates and then we remove these from the vector in a single operation.

```{r, echo=FALSE}
find_duplicates <- which %.% duplicated
```
```{r}
vector_rm_duplicates <- function(x) {
    dup <- find_duplicates(x)
    x[-dup]
}
vector_rm_duplicates(c(1, 1, 2, 2))
```

R already has a built-in function for finding duplicates, called `duplicated`, and we could implement `find_duplicates` using it (it returns a boolean vector, but we can use the function `which` to get the indices of the `TRUE` values). It is a good exercise to implement it ourselves, though.

```{r, echo=FALSE}
builtin_find_duplicates <- which %.% duplicated
```
```{r}
find_duplicates <- function(x, i = 1) {
    if (i >= length(x)) return(c())

    rest <- find_duplicates(x, i + 1)
    if (x[i] == x[i + 1]) c(i, rest)
    else rest
}
```
```{r, echo=FALSE}
x <- c(1,1,2,3,4,4)
assert(all(builtin_find_duplicates(x)-1 == find_duplicates(x)))
```

The structure is very similar to the list version, but here we return the result of the recursive call together with the current index if it is a duplicate and just the result of the recursive call otherwise.

This solution isn't perfect. Each time we create an index vector by combining it with the recursive result we are making a copy so the running time will be quadratic in the length of the result (but linear in the length of the input). We can turn it into a linear time algorithm in the output as well by making a next-list instead of a vector of the indices, and then translate that into a vector in the remove duplicates function before we index into the vector `x` to remove the duplicates. I will leave that as an exercise.

As another example of a recursive function where we need to combine results from recursive calls we can consider computing the size of a tree. The base case is when the tree is a leaf. There it has size 1. Otherwise, the size of a tree is the sum of the size of its sub-trees plus one.

```{r}
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

Here, again, I assume that either both or none of the sub-trees in a binary tree are `NULL`. I also use a slightly different approach to the function by setting the result in a local variable that I return at the end.

```{r, echo=FALSE}
make_node <- function(name, left = NULL, right = NULL) 
  list(name = name, left = left, right = right)
```
```{r}
tree <- make_node("root", 
                  make_node("C", make_node("A"), 
                                 make_node("B")),
                  make_node("D"))

size_of_tree(tree)
```

If I wanted to remember the size of sub-trees so I didn't have to recompute them, I could attempt something like this:

```{r}
set_size_of_subtrees <- function(node) {
  if (is.null(node$left) && is.null(node$right)) {
    node$size <- 1
  } else {
    left_size <- set_size_of_subtrees(node$left)
    right_size <- set_size_of_subtrees(node$right)
    node$size <- left_size + right_size + 1
  }
  node$size
}
```

but remember that data in R cannot be changed. If I run this function on a tree, it would create nodes that knew the size of a sub-tree, but these nodes would be copies and not the nodes in the tree I call the function on.

```{r}
set_size_of_subtrees(tree)
tree$size
```

To actually remember the sizes I would have to construct a whole new tree where the nodes knew their size. So I would need this function:

```{r}
set_size_of_subtrees <- function(node) {
  if (is.null(node$left) && is.null(node$right)) {
    node$size <- 1
  } else {
    left <- set_size_of_subtrees(node$left)
    right <- set_size_of_subtrees(node$right)
    node$size <- left$size + right$size + 1
  }
  node
}

tree <- set_size_of_subtrees(tree)
tree$size
```

Another thing we can do with a tree is to compute the depth-first-numbers of nodes. There is a neat trick for trees you can use to determine if a node is in a given sub-tree. If each node knows the range of depth-first-numbers, and we can map leaves to their depth-first-number, we can determine if it is in sub-tree just by checking if its depth-first-number is in the right range.

To compute the depth-first-numbers and annotate the tree with ranges, we need a slightly more complex function than the ones we have seen so far. It still follows the recursive function formula, though. We have a basis case for leaves and a recursive case where we need to call the function on both the left and the right sub-tree. The complexity lies only in what we have to return from the function. We need to keep track of the depth-first-numbers we have seen so far, we need to return a new node that has the range for its sub-tree, and we need to return a table of the depth-first-numbers.

```{r}
depth_first_numbers <- function(node, dfn = 1) {
  if (is.null(node$left) && is.null(node$right)) {
    node$range <- c(dfn, dfn)
    new_table <- table
    table <- c()
    table[node$name] <- dfn
    list(node = node, new_dfn = dfn + 1, table = table)
    
  } else {
    left <- depth_first_numbers(node$left, dfn)
    right <- depth_first_numbers(node$right, left$new_dfn)
    
    new_dfn <- right$new_dfn
    new_node <- make_node(node$name, left$node, right$node)
    new_node$range <- c(left$node$range[1], new_dfn)
    table <- c(left$table, right$table)
    table[node$name] <- new_dfn
    list(node = new_node, new_dfn = new_dfn + 1, table = table)
  }
}
```

```{r}
df <- depth_first_numbers(tree)
df$node$range
df$table
```

We can now exploit this depth-first-numbering to write a version of `node_depth` that only searches in the sub-tree where a node is actually found. We use a helper function for checking if a depth-first-number is in a node's range:

```{r}
in_df_range <- function(i, df_range) 
    df_range[1] <= i && i <= df_range[2]
```

and then simply check for this before we call recursively.

```{r}
node_depth <- function(tree, name, dfn_table, depth = 0) {
    dfn <- dfn_table[name]

    if (is.null(tree) || !in_df_range(dfn, tree$range)) {
       return(NA)
    }
    if (tree$name == name) {
        return(depth)
    }

    if (in_df_range(dfn, tree$left$range)) {
        node_depth(tree$left, name, dfn_table, depth + 1)
    } else if (in_df_range(dfn, tree$right$range)) {
        node_depth(tree$right, name, dfn_table, depth + 1)
    } else {
        NA
    }
}

node_depth <- Vectorize(node_depth, 
                        vectorize.args = "name",
                        USE.NAMES = FALSE)
node_depth(df$node, LETTERS[1:4], df$table)
```



## Tail-recursion

Functions, such as our search functions that return the result of recursive call without doing further computation on it are called *tail recursive*. Such functions are particularly desired in functional programming languages because they can be translated into loops, removing the overhead involved in calling functions. R, however, does not implement this tail-recursion optimisation. There are good but technical reasons why, having to do with scopes. This doesn't mean that we cannot exploit tail-recursion and the optimisations possible if we write our functions to be tail-recursive, we just have to translate our functions into loops explicitly. We cover that in the next section. First I will show you a technique for translating an otherwise not tail-recursive function into one that is.

As long as you have a function that only calls recursively zero or one time, it is a very simple trick. You pass along values in recursive calls that can be used to compute the final value once the recursion gets to a base case.

As a simple example, we can take the factorial function. The way we wrote it above was not tail-recursive. We called recursively and then multiplied $n$ to the result.

```{r}
factorial <- function(n) {
    if (n == 1) 1
    else n * factorial(n - 1)
}
```

We can translate it into a tail-recursive function by passing the product of the numbers we have seen so far along to the recursive call. Such a value that is passed along is typically called an accumulator. The tail-recursive function would look like this:

```{r}
factorial <- function(n, acc = 1) {
    if (n == 1) acc
    else factorial(n - 1, acc * n)
}
```
```{r, echo=FALSE}
assert(factorial(3) == 3*2)
```

Similarly, we can take the `find_duplicates` function we wrote and turn it into a tail-recursive function. The original function looks like this:

```{r}
find_duplicates <- function(x, i = 1) { 
    if (i >= length(x)) return(c())
    rest <- find_duplicates(x, i + 1) 
    if (x[i] == x[i + 1]) c(i, rest) else rest
}
```

It needs to return a list of indices so that is what we pass along as the accumulator:

```{r}
find_duplicates <- function(x, i = 1, acc = c()) { 
    if (i >= length(x)) return(acc)
    if (x[i] == x[i + 1]) find_duplicates(x, i + 1, c(acc, i))
    else find_duplicates(x, i + 1, acc)
}
```
```{r, echo=FALSE}
assert(all(find_duplicates(c(1,1,2,2)) == c(1,3)))
```

All functions that call themselves recursively at most once can equally easily be translated into tail-recursive functions using an appropriate accumulator.

It is harder for functions that make more than one recursive call, like the tree functions we wrote earlier. It is not impossible to make them tail-recursive, but it requires a trick called *continuation passing* which I will show you in the chapter on [Higher-order Functions].

## Runtime considerations

Now for the bad news. All the techniques I have shown you in this chapter for writing pure functional programs using recursion instead of loops are not actually the best way to write programs in R.

You will want to write pure functions, but relying on recursion instead of loops come at a runtime cost. We can our recursive linear search function with one that uses a `for`-loop to see how much overhead we incur.

The recursive function looked like this:

```{r}
r_lin_search <- function(element, sequence, i = 1) {
  if (i > length(sequence)) FALSE
  else if (sequence[i] == element) TRUE
  else r_lin_search(element, sequence, i + 1)
}
```

A version using a `for`-loop could look like this:

```{r}
l_lin_search <- function(element, sequence) {
  for (e in sequence) {
    if (e == element) return(TRUE)
  }
  return(FALSE)
}
```

We can use the function `microbenchmark` from the `microbenchmark` package to compare the two. If we search for an element that is not contained in the sequence we search in we will have to search through the entire sequence, so we can use that worst-case scenario for the performance measure.

```r
library(microbenchmark)
```
```{r lin_search_comparison, cache=TRUE}
x <- 1:1000
microbenchmark(r_lin_search(-1, x),
               l_lin_search(-1, x))

```

The recursive function is almost an order of magnitude slower than the function that uses a loop. Keep that in mind if people tell you that loops are slow in R; they might be, but recursive functions are slower.

It gets worse than that. R has a limit to how deep you can call a function recursively, and if we were searching in a sequence longer than about a thousand elements we would reach this limit, and R would terminate the call with an error.

This doesn't mean that reading this chapter was a complete waste of time. It can be very useful to think in terms of recursion when you are constructing a function. There is a reason why divide-and-conquer is frequently used to solve algorithmic problems. You just want to translate the recursive solution into a loop once you have designed the function.

For functions such as linear search, we would never program a solution as a recursive function in the first place. The `for`-loop version is much easier to write and much more efficient. Other problems are much easier to solve with a recursive algorithm, and there the implementation is also easier done by first thinking in terms of a recursive function. The binary search is an example of such a problem. It is inherently recursive since we solve the search by another search on a shorter string. It is also less likely to hit the allowed recursion limit since it will only call recursively a number of times that is logarithmic in the length of the input, but that is another issue.

The recursive binary search looked like this:

```{r}
r_binary_search <- function(element, x, 
                            first = 1, last = length(x)) {
  if (last < first) return(FALSE) # empty sequence
  
  middle <- (last - first) %/% 2 + first
  if (element == x[middle]) TRUE
  else if (element < x[middle]) {
    r_binary_search(element, x, first, middle - 1)
  } else {
    r_binary_search(element, x, middle + 1, last)
  }
}
```

It is a tail-recursive function and we can exploit that to translate it into a version that uses a loop instead of recursive calls. To translate a tail-recursive function into a looping function you put the body of the function in a `repeat`-loop. A `repeat`-loop will loop forever unless you explicitly exit from it, but the base case tests in the recursive function can be used to exit the loop using an explicit `return` call. When you would normally call recursively you instead just update the local parameters you passed as arguments to the function. The result looks like this:

```{r}
l_binary_search <- function(element, x, 
                            first = 1, last = length(x)) {
  repeat {
    if (last < first) return(FALSE) # empty sequence  
    
    middle <- (last - first) %/% 2 + first
    if (element == x[middle]) return(TRUE)
    
    else if (element < x[middle]) {
      last <- middle - 1
    } else {
      first <- middle + 1
    }
  }
}
```

The translation always follows this simple pattern, which is why many programming languages will do it for you automatically. We don't get as massive a performance boost by changing this algorithm into a looping version, simply because there aren't that many function calls in a binary search -- the power of logarithmic runtime algorithms -- but we do get a slightly more efficient version. We can again compare the two using `microbenchmark` to measure exactly how much improvement we get:

```{r bin_search_benchmark, cache=TRUE}
x <- 1:10000000
microbenchmark(r_binary_search(-1, x),
               l_binary_search(-1, x))
```

If your function is *not* tail-recursive it is a lot more work to translate it into a version that uses loops. You will essentially have to simulate the function call stack yourself. That involves a lot more programming, but it is not functional programming and thus is beyond the scope of this book. Not to worry, though, using continuations, a topic we cover later in the book, you can generally translate your functions into tail-recursive functions and then use a trick called a "trampoline" to replace recursion with looks.

