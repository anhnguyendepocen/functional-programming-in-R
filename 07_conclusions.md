
# Conclusions

This concludes this book on functional programming in R. You now know all the basic programming patterns used in day to day functional programming and how to use them in the R programming language.

Getting used to writing functional programs might take a little effort if you are only used to imperative or object-oriented programming, but the combination of higher-order functions and closures is a very powerful paradigm for effective programming and writing pure functions whenever possible makes for code that is much simpler to reason about.

R is not a pure functional programming language, though, so your code will usually mix imperative programming---which in most cases means using loops instead of recursions, both for convenience and efficiency reasons---with functional patterns. With careful programming, you can still keep the changing states of a program to a minimum and keep most of your program pure.

Helping you keep programming pure is the immutability of data in R. Whenever you “modify” data, you will implicitly create a copy of the data and then modify the copy. For reasoning about your programs, that is good news. It is very hard to create side effects of functions. It does come with some drawbacks, however. Many classical data structures assume that you can modify data. Since you cannot do this in R, you will instead have to construct your data structures such that updating them means creating new, modified, data structures.

We have seen how we can use linked lists (“next lists” in the terminology I have used in this book) and trees with functions that modify the data when computing on it. Lists and trees form the basic constructions for data structures in functional programs, but efficient functional data structures are beyond the scope of this book. I plan to return to it in a later book in the series.

I will end the book here, but I hope it is not the end of your exploration of functional programming in R.

If you liked this book, why not check out my [list of other books](http://wp.me/P9B2l-DN) or 
[sign up to my mailing list](http://eepurl.com/cwIbR5)?


## Acknowledgements

I would like to thank Duncan Murdoch and the people on the R-help mailing list for helping me work out a kink in lazy evaluation in the trampoline example.