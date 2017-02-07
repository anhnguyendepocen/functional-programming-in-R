
# Introduction

Welcome to the *Functional Programming in R*. I wrote this book, to have teaching material beyond the typical introductory level most textbooks on R have. This book is intended to give an introduction to functions in R, and how to write functional programs in R. Functional programming is a style of programming, like object-oriented programming, but one that focuses on data transformations and calculations rather than objects and state.

Where in object-oriented programming you model your programs by describing which states an object can be in and how methods will reveal or modify that state---in functional programming you model programs by describing how functions translate input data to output data. Functions themselves are considered data that you can manipulate, and much of the strength of functional programming comes from manipulating functions, building more complex functions by combining simpler functions.

The R programming language supports both object-oriented programming and functional programming, but it is mainly a functional language. It is not a "pure" functional language. Pure functional languages will not allow you to modify the state of the program by changing values parameters hold and will not allow functions to have side-effects (and need various tricks to deal with program input and output because of it).

R is somewhat close to "pure" functional languages. In general, data is immutable, so changes to data inside a function do ordinarily not alter the state of data outside that function. But R does allow side-effects, such as printing data or making plots and of course allows variables to change values. 

Pure functions are functions that have no side-effects and where a function called with the same input will always return the same output. Pure functions are easier to debug and to reason about because of this. They can be reasoned about in isolation and will not depend on the context in which they are called. The R language does not guarantee that the functions you write are pure, but you can write most of your programs using only pure functions. By keeping your code mostly purely functional, you will write more robust code and code that is easier to modify when the need arises.

You will just have to move the impure functions to a small subset of your program. These functions are typically those that need to sample random data, or that produces output (either text or plots). If you know where your impure functions are, you know when to be extra careful with modifying code.

The next chapter contains a short introduction to functions in R. Some parts you might already know, and then feel free to skip ahead, but I give an exhaustive description of how functions are defined and used to make sure that we are all on the same page. The following chapters then move on to more complex issues.
