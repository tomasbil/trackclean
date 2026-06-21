#' Standardize location data to fixed time intervals
#'
#' Rounds timestamps to the nearest interval boundary and averages X/Y
#' coordinates if multiple signals fall within the same interval.
#'
#' @param data A data frame with location tracking data
#' @param time_col Name of the timestamp column (default: "At")
#' @param x_col Name of x-coordinate column (default: "X")
#' @param y_col Name of y-coordinate column (default: "Y")
#' @param id_col Name of ID column (default: "id_code")
#' @param unit Time interval to standardize to, passed to
#'   \code{lubridate::floor_date()} (default: \code{"second"}). Use
#'   \code{"2 seconds"}, \code{"5 seconds"}, etc. for coarser intervals.
#' @param verbose Print summary statistics (default: TRUE)
#'
#' @return Data frame with one row per (id, interval) with:
#'   - X, Y: Averaged coordinates
#'   - n_entries: Number of original signals in that interval
#'   - standardized: 1 if multiple signals were aggregated, 0 if single
#' @export
#'
#' @examples
#' \dontrun{
#' # Default: 1-second intervals
#' standardized_data <- standardize_to_seconds(raw_data)
#'
#' # 2-second intervals
#' standardized_data <- standardize_to_seconds(raw_data, unit = "2 seconds")
#' }
standardize_to_seconds <- function(data,
                                   time_col = "At",
                                   x_col = "X",
                                   y_col = "Y",
                                   id_col = "id_code",
                                   unit = "second",
                                   verbose = TRUE) {

  data <- data %>%
    dplyr::mutate(!!time_col := as.POSIXct(.data[[time_col]]))

  metadata_cols <- setdiff(
    names(data),
    c(time_col, x_col, y_col, id_col)
  )

  standardized_data <- data %>%
    dplyr::mutate(At_sec = lubridate::floor_date(.data[[time_col]], unit = unit)) %>%
    dplyr::group_by(.data[[id_col]], At_sec) %>%
    dplyr::summarise(
      !!x_col := mean(.data[[x_col]], na.rm = TRUE),
      !!y_col := mean(.data[[y_col]], na.rm = TRUE),
      n_entries = dplyr::n(),
      standardized = dplyr::if_else(dplyr::n() > 1L, 1L, 0L),
      dplyr::across(dplyr::all_of(metadata_cols), dplyr::first),
      .groups = "drop"
    ) %>%
    dplyr::rename(!!time_col := At_sec) %>%
    dplyr::arrange(.data[[id_col]], .data[[time_col]])

  if (verbose) {
    total_raw <- nrow(data)
    total_std <- nrow(standardized_data)
    total_entries <- sum(standardized_data$n_entries)
    pct_aggregated <- mean(standardized_data$standardized) * 100

    message(sprintf("\n=== Standardization to %s intervals ===", unit))
    message(sprintf("  Original rows: %d", total_raw))
    message(sprintf("  Standardized rows: %d", total_std))
    message(sprintf("  Rows aggregated: %.1f%%", pct_aggregated))
    message(sprintf("  Data integrity: %s",
                    if(total_entries == total_raw) "[OK] All rows accounted for" else "[MISMATCH] Row count mismatch"))
  }

  return(standardized_data)
}
