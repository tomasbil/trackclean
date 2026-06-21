#' Interpolate gaps in location tracking data (two-phase approach)
#'
#' Phase 1: Interpolates small gaps (gap <= max_gap_small seconds)
#' Phase 2: Interpolates larger gaps if position change is <= max_position_change meters
#'
#' Uses linear interpolation: X_t = X_start + (k/gap) * (X_end - X_start)
#'
#' @param data A data frame with location tracking data
#' @param time_col Name of the timestamp column (default: "At")
#' @param x_col Name of x-coordinate column (default: "X")
#' @param y_col Name of y-coordinate column (default: "Y")
#' @param id_col Name of ID column (default: "id_code")
#' @param analyze_col Name of column indicating rows to analyze (default: "Analyze")
#' @param time_step Expected time step in seconds between consecutive observations
#'   after standardization (default: 1). Set this to match the \code{unit} used
#'   in \code{standardize_to_seconds()}, e.g. \code{time_step = 2} if you
#'   standardized to 2-second intervals.
#' @param max_gap_small Maximum gap size for phase 1 in seconds (default: 10)
#' @param max_gap_large Maximum gap size for phase 2 in seconds (default: NULL for no limit)
#' @param max_position_change Maximum position change in meters for phase 2 (default: 0.3)
#' @param verbose Print progress messages (default: TRUE)
#'
#' @return Data frame with interpolated coordinates and flags:
#'   - imputed: 1 if row was added in phase 1 (small gaps)
#'   - imputed_large: 1 if row was added in phase 2 (large gaps)
#'   - n_entries: 0 for imputed rows
#'   - standardized: 0 for imputed rows
#' @export
#'
#' @examples
#' \dontrun{
#' # Default: phase 1 <=10sec, phase 2 unlimited with <=30cm movement
#' data_clean <- interpolate_gaps(standardized_data)
#'
#' # Custom thresholds
#' data_clean <- interpolate_gaps(standardized_data,
#'                                max_gap_small = 5,
#'                                max_gap_large = 30,
#'                                max_position_change = 0.5)
#'
#' # After 2-second standardization
#' data_clean <- interpolate_gaps(standardized_data, time_step = 2)
#' }
interpolate_gaps <- function(data,
                             time_col = "At",
                             x_col = "X",
                             y_col = "Y",
                             id_col = "id_code",
                             analyze_col = "Analyze",
                             time_step = 1,
                             max_gap_small = 10,
                             max_gap_large = NULL,
                             max_position_change = 0.3,
                             verbose = TRUE) {

  data <- data %>%
    dplyr::mutate(!!time_col := as.POSIXct(.data[[time_col]])) %>%
    dplyr::arrange(.data[[id_col]], .data[[time_col]])

  if (!"imputed" %in% names(data)) {
    data <- data %>% dplyr::mutate(imputed = 0L)
  }
  if (!"imputed_large" %in% names(data)) {
    data <- data %>% dplyr::mutate(imputed_large = 0L)
  }

  metadata_cols <- setdiff(
    names(data),
    c(time_col, x_col, y_col, id_col, analyze_col,
      "imputed", "imputed_large", "next_At", "next_X", "next_Y", "gap_sec")
  )

  # Phase 1: small gaps
  if (verbose) message("\n=== Phase 1: Interpolating gaps <= ", max_gap_small, " seconds ===")

  data_analyze <- data %>%
    dplyr::filter(.data[[analyze_col]] == 1) %>%
    dplyr::arrange(.data[[id_col]], .data[[time_col]])

  data_other <- data %>%
    dplyr::filter(.data[[analyze_col]] != 1)

  gaps_small <- data_analyze %>%
    dplyr::group_by(.data[[id_col]]) %>%
    dplyr::arrange(.data[[time_col]]) %>%
    dplyr::mutate(
      next_At = dplyr::lead(.data[[time_col]]),
      next_X = dplyr::lead(.data[[x_col]]),
      next_Y = dplyr::lead(.data[[y_col]]),
      gap_sec = as.integer(difftime(next_At, .data[[time_col]], units = "secs"))
    ) %>%
    dplyr::filter(!is.na(gap_sec),
                  gap_sec > time_step,
                  gap_sec <= (max_gap_small + time_step)) %>%
    dplyr::ungroup()

  if (nrow(gaps_small) > 0) {
    imputed_small <- do.call(rbind, lapply(seq_len(nrow(gaps_small)), function(i) {
      row <- gaps_small[i, ]
      start_time <- row[[time_col]]
      end_time <- row$next_At
      gap <- as.integer(difftime(end_time, start_time, units = "secs"))
      k <- seq(time_step, gap - time_step, by = time_step)

      result <- tibble::tibble(
        !!time_col := start_time + lubridate::seconds(k),
        !!x_col := row[[x_col]] + (k / gap) * (row$next_X - row[[x_col]]),
        !!y_col := row[[y_col]] + (k / gap) * (row$next_Y - row[[y_col]]),
        !!id_col := row[[id_col]],
        !!analyze_col := row[[analyze_col]],
        imputed = 1L,
        imputed_large = 0L,
        n_entries = 0L,
        standardized = 0L
      )

      for (col in metadata_cols) {
        if (col %in% names(row) && !col %in% c("n_entries", "standardized")) {
          result[[col]] <- row[[col]]
        }
      }

      result
    }))

    data <- dplyr::bind_rows(
      data_analyze,
      imputed_small,
      data_other
    ) %>%
      dplyr::arrange(.data[[id_col]], .data[[time_col]])

    if (verbose) {
      message(sprintf("  Found %d small gaps", nrow(gaps_small)))
      message(sprintf("  Created %d interpolated points", nrow(imputed_small)))
    }
  } else {
    data <- dplyr::bind_rows(data_analyze, data_other) %>%
      dplyr::arrange(.data[[id_col]], .data[[time_col]])
    if (verbose) message("  No small gaps found")
  }

  # Phase 2: larger gaps with small position change
  if (verbose) {
    message("\n=== Phase 2: Interpolating larger gaps with <=",
            max_position_change, "m position change ===")
  }

  data_analyze2 <- data %>%
    dplyr::filter(.data[[analyze_col]] == 1) %>%
    dplyr::arrange(.data[[id_col]], .data[[time_col]])

  data_other2 <- data %>%
    dplyr::filter(.data[[analyze_col]] != 1)

  gaps_large <- data_analyze2 %>%
    dplyr::group_by(.data[[id_col]]) %>%
    dplyr::arrange(.data[[time_col]]) %>%
    dplyr::mutate(
      next_At = dplyr::lead(.data[[time_col]]),
      next_X = dplyr::lead(.data[[x_col]]),
      next_Y = dplyr::lead(.data[[y_col]]),
      gap_sec = as.integer(difftime(next_At, .data[[time_col]], units = "secs"))
    ) %>%
    dplyr::filter(
      !is.na(gap_sec),
      gap_sec > (max_gap_small + time_step),
      abs(next_X - .data[[x_col]]) <= max_position_change,
      abs(next_Y - .data[[y_col]]) <= max_position_change
    )

  if (!is.null(max_gap_large)) {
    gaps_large <- gaps_large %>%
      dplyr::filter(gap_sec <= (max_gap_large + time_step))
  }

  gaps_large <- gaps_large %>% dplyr::ungroup()

  if (nrow(gaps_large) > 0) {
    imputed_large <- do.call(rbind, lapply(seq_len(nrow(gaps_large)), function(i) {
      row <- gaps_large[i, ]
      start_time <- row[[time_col]]
      end_time <- row$next_At
      gap <- as.integer(difftime(end_time, start_time, units = "secs"))
      k <- seq(time_step, gap - time_step, by = time_step)

      result <- tibble::tibble(
        !!time_col := start_time + lubridate::seconds(k),
        !!x_col := row[[x_col]] + (k / gap) * (row$next_X - row[[x_col]]),
        !!y_col := row[[y_col]] + (k / gap) * (row$next_Y - row[[y_col]]),
        !!id_col := row[[id_col]],
        !!analyze_col := row[[analyze_col]],
        imputed = 0L,
        imputed_large = 1L,
        n_entries = 0L,
        standardized = 0L
      )

      for (col in metadata_cols) {
        if (col %in% names(row) && !col %in% c("n_entries", "standardized")) {
          result[[col]] <- row[[col]]
        }
      }

      result
    }))

    data <- dplyr::bind_rows(
      data_analyze2,
      imputed_large,
      data_other2
    ) %>%
      dplyr::arrange(.data[[id_col]], .data[[time_col]])

    if (verbose) {
      message(sprintf("  Found %d large gaps meeting criteria", nrow(gaps_large)))
      message(sprintf("  Created %d interpolated points", nrow(imputed_large)))
    }
  } else {
    data <- dplyr::bind_rows(data_analyze2, data_other2) %>%
      dplyr::arrange(.data[[id_col]], .data[[time_col]])
    if (verbose) message("  No large gaps found")
  }

  if (verbose) {
    total_imputed <- sum(data$imputed == 1, na.rm = TRUE)
    total_imputed_large <- sum(data$imputed_large == 1, na.rm = TRUE)
    message(sprintf("\n=== Interpolation Complete ==="))
    message(sprintf("  Phase 1 points: %d", total_imputed))
    message(sprintf("  Phase 2 points: %d", total_imputed_large))
    message(sprintf("  Total new points: %d\n", total_imputed + total_imputed_large))
  }

  return(data)
}
