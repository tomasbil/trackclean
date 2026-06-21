#' Mark time periods for analysis and bell time in raw data
#'
#' Creates binary columns indicating whether each timestamp falls within
#' specified time periods (e.g., recess period, bell ringing period)
#'
#' @param data A data frame with timestamp data
#' @param time_col Name of the timestamp column (default: "At")
#' @param analyze_start Start time for analysis period (POSIXct or character, e.g. \code{"2025-03-18 11:50:00"})
#' @param analyze_end End time for analysis period (POSIXct or character)
#' @param bell_start Start time for bell period (POSIXct or character, optional)
#' @param bell_end End time for bell period (POSIXct or character, optional)
#' @param analyze_col Name of column to create for analysis period (default: "Analyze")
#' @param bell_col Name of column to create for bell period (default: "Bell")
#'
#' @return Data frame with added binary columns (1 = within period, 0 = outside period)
#' @export
#'
#' @examples
#' \dontrun{
#' # Mark analysis period only
#' raw_data <- mark_time_periods(
#'   raw_data,
#'   analyze_start = "2025-03-18 11:50:00",
#'   analyze_end = "2025-03-18 13:11:00"
#' )
#'
#' # Mark both analysis and bell periods
#' raw_data <- mark_time_periods(
#'   raw_data,
#'   analyze_start = "2025-03-18 11:50:00",
#'   analyze_end = "2025-03-18 13:11:00",
#'   bell_start = "2025-03-18 12:30:00",
#'   bell_end = "2025-03-18 14:00:00"
#' )
#' }
mark_time_periods <- function(data,
                              time_col = "At",
                              analyze_start,
                              analyze_end,
                              bell_start = NULL,
                              bell_end = NULL,
                              analyze_col = "Analyze",
                              bell_col = "Bell") {

  data <- data %>%
    dplyr::mutate(!!time_col := as.POSIXct(.data[[time_col]]))

  if (is.character(analyze_start)) {
    analyze_start <- lubridate::ymd_hms(analyze_start)
  }
  if (is.character(analyze_end)) {
    analyze_end <- lubridate::ymd_hms(analyze_end)
  }

  if (analyze_start >= analyze_end) {
    stop("analyze_start must be before analyze_end")
  }

  data <- data %>%
    dplyr::mutate(
      !!analyze_col := dplyr::if_else(
        .data[[time_col]] >= analyze_start & .data[[time_col]] <= analyze_end,
        1L,
        0L
      )
    )

  n_analyze <- sum(data[[analyze_col]] == 1)
  message(sprintf("[OK] Analysis period marked: %s to %s",
                  format(analyze_start, "%Y-%m-%d %H:%M:%S"),
                  format(analyze_end, "%Y-%m-%d %H:%M:%S")))
  message(sprintf("  - Rows in analysis period: %d (%.1f%%)",
                  n_analyze,
                  100 * n_analyze / nrow(data)))

  if (!is.null(bell_start) && !is.null(bell_end)) {

    if (is.character(bell_start)) {
      bell_start <- lubridate::ymd_hms(bell_start)
    }
    if (is.character(bell_end)) {
      bell_end <- lubridate::ymd_hms(bell_end)
    }

    if (bell_start >= bell_end) {
      stop("bell_start must be before bell_end")
    }

    data <- data %>%
      dplyr::mutate(
        !!bell_col := dplyr::if_else(
          .data[[time_col]] >= bell_start & .data[[time_col]] <= bell_end,
          1L,
          0L
        )
      )

    n_bell <- sum(data[[bell_col]] == 1)
    message(sprintf("[OK] Bell period marked: %s to %s",
                    format(bell_start, "%Y-%m-%d %H:%M:%S"),
                    format(bell_end, "%Y-%m-%d %H:%M:%S")))
    message(sprintf("  - Rows in bell period: %d (%.1f%%)",
                    n_bell,
                    100 * n_bell / nrow(data)))

    n_overlap <- sum(data[[analyze_col]] == 1 & data[[bell_col]] == 1)
    if (n_overlap > 0) {
      message(sprintf("  - Overlap between periods: %d rows (%.1f%% of bell period)",
                      n_overlap,
                      100 * n_overlap / n_bell))
    }
  }

  return(data)
}
