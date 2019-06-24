new_step <- function(parent,
                     vars = parent$vars,
                     groups = parent$groups,
                     env = caller_env(),
                     ...,
                     class = character()) {

  stopifnot(is.data.table(parent) || is_step(parent))
  stopifnot(is.character(vars))
  stopifnot(is.character(groups))

  structure(
    list(
      parent = parent,
      vars = vars,
      groups = groups,
      env = env,
      ...
    ),
    class = c(class, "dtplyr_step")
  )
}

print.dtplyr_step <- function(x) {
  cat_line("<dtplyr_step>")
  cat_line("Vars:   ", paste0(x$vars, collapse = ", "))
  cat_line("Groups: ", paste0(x$groups, collapse = ", "))
  cat_line("Call:   ", expr_text(dt_call(x)))

  invisible(x)
}

show_query.dtplyr_step <- function(x) {
  dt_call(x)
}

is_step <- function(x) inherits(x, "dtplyr_step")

dt_eval <- function(x) {
  dt <- dt_source(x)

  env <- env(x$env, `_DT` = dt)
  quo <- new_quosure(dt_call(x), env)

  eval_tidy(quo)
}

dt_needs_copy <- function(x) {
  UseMethod("dt_needs_copy")
}

dt_source <- function(x) {
  while (!is.data.table(x)) {
    x <- x$parent
  }
  x
}

dt_call <- function(x, needs_copy = dt_needs_copy(x)) {
  UseMethod("dt_call")
}

#' @examples
#' mtcars2 <- mtcars %>% lazy_dt()
#' mtcars2
#' mtcars2 %>% select(mpg:cyl)
#' mtcars2 %>% select(x = mpg, y = cyl)
#' mtcars2 %>% filter(x == 1) %>% select(mpg)
#' mtcars2 %>% select(mpg) %>% filter(x == 1)
#' mtcars2 %>% mutate(x2 = x * 2, x4 = x2 * 2)
#' mtcars2 %>% transmute(x2 = x * 2, x4 = x2 * 2)
#' mtcars2 %>% filter(x == 1) %>% mutate(x2 = x * 2)
#'
#' by_cyl <- mtcars2 %>% group_by(cyl)
#' by_cyl %>% summarise(x = mean(x))
#' by_cyl %>% group_by(mpg) %>% mutate(x = mean(x))
#' by_cyl %>% filter(mpg < mean(mpg)) %>% summarise(hp = mean(hp))
lazy_dt <- function(x) {
  new_step_first(as.data.table(x))
}

capture_dots <- function(..., vars, .named = TRUE) {
  enexprs(...)
}
