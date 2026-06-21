#' Pipe operator
#'
#' See \code{magrittr::\link[magrittr:pipe]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL

# Suppress R CMD check notes about . and other dplyr variables
utils::globalVariables(c(
  ".",
  ".data",
  ".remove",
  "At_sec",
  "next_At",
  "next_X",
  "next_Y",
  "gap_sec"
))

