---
title: Functional Programming in R
series: Advanced Statistical Programming in R
author: Thomas Mailund
---

```{r, echo=FALSE, warning=FALSE}
suppressPackageStartupMessages(library(magrittr, quietly = TRUE))
suppressPackageStartupMessages(library(pryr, quietly = TRUE))
suppressPackageStartupMessages(library(microbenchmark, quietly = TRUE))
suppressPackageStartupMessages(library(purrr, quietly = TRUE))

assert <- function(expr, expected) {
	if (!expr) stop(paste0("ERROR: ", expr))
}

options(width = 50)

Sys.setenv(LANG = "en")

```
