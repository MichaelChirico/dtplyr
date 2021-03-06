#' Create a "lazy" data.table
#'
#' @description
#' A lazy data.table lazy captures the intent of dplyr verbs, only actually
#' performing computation when requested (with [collect()], [pull()],
#' [as.data.frame()], [data.table::as.data.table()], or [tibble::as_tibble()]).
#' This allows dtplyr to convert dplyr verbs into as few data.table expressions
#' as possible, which leads to a high performance translation.
#'
#' See `vignette("translation")` for more details.
#'
#' @param x A data table (or something can can be coerced to a data table)
#' @param immutable If `TRUE`, `x` is treated as immutable and will never
#'   be modified in place. Alternatively, set `immutable = FALSE` to state
#'   that it's ok for dtplyr to modify the input.
#' @param name Optionally, supply a name to be used in generated expressions.
#'   For expert use only.
#' @export
#' @examples
#' library(dplyr)
#'
#' mtcars2 <- lazy_dt(mtcars)
#' mtcars2
#' mtcars2 %>% select(mpg:cyl)
#' mtcars2 %>% select(x = mpg, y = cyl)
#' mtcars2 %>% filter(cyl == 4) %>% select(mpg)
#' mtcars2 %>% select(mpg, cyl) %>% filter(cyl == 4)
#' mtcars2 %>% mutate(cyl2 = cyl * 2, cyl4 = cyl2 * 2)
#' mtcars2 %>% transmute(cyl2 = cyl * 2, vs2 = vs * 2)
#' mtcars2 %>% filter(cyl == 8) %>% mutate(cyl2 = cyl * 2)
#'
#' by_cyl <- mtcars2 %>% group_by(cyl)
#' by_cyl %>% summarise(mpg = mean(mpg))
#' by_cyl %>% mutate(mpg = mean(mpg))
#' by_cyl %>% filter(mpg < mean(mpg)) %>% summarise(hp = mean(hp))
lazy_dt <- function(x, name = NULL, immutable = TRUE) {
  if (!is.data.table(x)) {
    x <- as.data.table(x)
  }

  step_first(x, name = name, immutable = immutable, env = caller_env())
}

step_first <- function(parent, name = NULL, immutable = TRUE, env = caller_env()) {
  stopifnot(is.data.table(parent))

  if (is.null(name)) {
    name <- unique_name()
  }

  new_step(parent,
    vars = names(parent),
    groups = character(),
    implicit_copy = !immutable,
    needs_copy = FALSE,
    name = sym(name),
    env = env,
    class = "dtplyr_step_first"
  )
}

dt_call.dtplyr_step_first <- function(x, needs_copy = FALSE) {
  if (needs_copy) {
    expr(copy(!!x$name))
  } else {
    x$name
  }
}

dt_sources.dtplyr_step_first <- function(x) {
  stats::setNames(list(x$parent), as.character(x$name))
}

unique_name <- local({
  i <- 0
  function() {
    i <<- i + 1
    paste0("_DT", i)
  }
})
