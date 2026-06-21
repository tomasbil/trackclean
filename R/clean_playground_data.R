#' Clean tracking data (complete pipeline)
#'
#' Master function that runs the complete data cleaning pipeline:
#' 1. Map raw IDs to participant IDs
#' 2. Mark analysis and bell time periods
#' 3. Standardize to fixed time intervals
#' 4. Interpolate gaps (two-phase)
#' 5. Optionally export to CSV
#'
#' @param data Raw tracking data frame
#' @param id_mapping Path to ID mapping CSV file or mapping data frame
#' @param exclude_ids Vector of raw IDs to exclude from analysis
#' @param analyze_start Start time for analysis period (character or POSIXct)
#' @param analyze_end End time for analysis period (character or POSIXct)
#' @param bell_start Start time for bell period (optional)
#' @param bell_end End time for bell period (optional)
#' @param unit Time interval for standardization, passed to
#'   \code{standardize_to_seconds()} (default: \code{"second"}). Use
#'   \code{"2 seconds"}, \code{"5 seconds"}, etc. for coarser intervals.
#' @param time_step Expected time step in seconds between consecutive observations
#'   after standardization (default: 1). Must match the numeric value of \code{unit},
#'   e.g. set \code{time_step = 2} when \code{unit = "2 seconds"}.
#' @param max_gap_small Maximum gap for phase 1 interpolation in seconds (default: 10)
#' @param max_gap_large Maximum gap for phase 2 interpolation in seconds (default: NULL)
#' @param max_position_change Maximum position change for phase 2 in meters (default: 0.3)
#' @param output_file Path to save cleaned data as CSV (optional)
#' @param verbose Print progress messages (default: TRUE)
#' @param time_col Name of the timestamp column (default: \code{"At"})
#' @param x_col Name of the x-coordinate column (default: \code{"X"})
#' @param y_col Name of the y-coordinate column (default: \code{"Y"})
#' @param raw_id_col Name of the raw device ID column in the input data (default: \code{"ID"})
#' @param id_col Name of the output column for standardized participant IDs (default: \code{"id_code"})
#' @param analyze_col Name of the analysis period flag column (default: \code{"Analyze"})
#' @param bell_col Name of the bell period flag column (default: \code{"Bell"})
#'
#' @return Cleaned data frame
#' @export
#'
#' @examples
#' \dontrun{
#' # Complete pipeline using bundled example data
#' library(readr)
#' raw_data <- read_csv(system.file("extdata", "raw_tracking_data.csv",
#'                                  package = "trackclean"))
#'
#' cleaned_data <- clean_playground_data(
#'   data = raw_data,
#'   id_mapping = system.file("extdata", "id_mapping.csv", package = "trackclean"),
#'   analyze_start = "2025-03-18 11:47:00",
#'   analyze_end   = "2025-03-18 11:57:00",
#'   bell_start    = "2025-03-18 11:53:00",
#'   bell_end      = "2025-03-18 11:58:00"
#' )
#'
#' # Custom column names for a dataset with different structure
#' cleaned_data <- clean_playground_data(
#'   data = raw_data,
#'   id_mapping = "id_mapping.csv",
#'   analyze_start = "2025-03-18 11:47:00",
#'   analyze_end   = "2025-03-18 11:57:00",
#'   time_col    = "timestamp",
#'   x_col       = "pos_x",
#'   y_col       = "pos_y",
#'   raw_id_col  = "tag_id",
#'   id_col      = "participant_id",
#'   analyze_col = "in_window"
#' )
#' }
clean_playground_data <- function(data,
                                  id_mapping,
                                  exclude_ids = NULL,
                                  analyze_start,
                                  analyze_end,
                                  bell_start = NULL,
                                  bell_end = NULL,
                                  unit = "second",
                                  time_step = 1,
                                  max_gap_small = 10,
                                  max_gap_large = NULL,
                                  max_position_change = 0.3,
                                  output_file = NULL,
                                  verbose = TRUE,
                                  time_col    = "At",
                                  x_col       = "X",
                                  y_col       = "Y",
                                  raw_id_col  = "ID",
                                  id_col      = "id_code",
                                  analyze_col = "Analyze",
                                  bell_col    = "Bell") {

  if (verbose) {
    message("\n")
    message("==================================")
    message("     TRACKCLEAN DATA PIPELINE     ")
    message("==================================")
  }

  if (verbose) message("\n[1/4] Mapping IDs...")
  data <- map_ids(
    data        = data,
    mapping     = id_mapping,
    exclude_ids = exclude_ids,
    raw_id_col  = raw_id_col,
    id_col      = id_col,
    analyze_col = analyze_col
  )

  if (verbose) message("\n[2/4] Marking time periods...")
  data <- mark_time_periods(
    data          = data,
    time_col      = time_col,
    analyze_start = analyze_start,
    analyze_end   = analyze_end,
    bell_start    = bell_start,
    bell_end      = bell_end,
    analyze_col   = analyze_col,
    bell_col      = bell_col
  )

  if (verbose) message(sprintf("\n[3/4] Standardizing to %s intervals...", unit))
  data <- standardize_to_seconds(
    data     = data,
    time_col = time_col,
    x_col    = x_col,
    y_col    = y_col,
    id_col   = id_col,
    unit     = unit,
    verbose  = verbose
  )

  if (verbose) message("\n[4/4] Interpolating gaps...")
  data <- interpolate_gaps(
    data               = data,
    time_col           = time_col,
    x_col              = x_col,
    y_col              = y_col,
    id_col             = id_col,
    analyze_col        = analyze_col,
    time_step          = time_step,
    max_gap_small      = max_gap_small,
    max_gap_large      = max_gap_large,
    max_position_change = max_position_change,
    verbose            = verbose
  )

  if (!is.null(output_file)) {
    readr::write_csv(data, output_file)
    if (verbose) {
      message("\n==================================")
      message(sprintf("[OK] Cleaned data exported to: %s", output_file))
      message(sprintf("  Total rows: %d", nrow(data)))
      message("==================================\n")
    }
  } else {
    if (verbose) {
      message("\n==================================")
      message("[OK] Pipeline complete!")
      message(sprintf("  Total rows: %d", nrow(data)))
      message("==================================\n")
    }
  }

  return(data)
}
