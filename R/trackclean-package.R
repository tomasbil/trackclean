#' trackclean: Tools for Cleaning High-Frequency Real-Time Location Tracking Data
#'
#' A toolkit for cleaning high-frequency positional data from real-time location
#' tracking systems (UWB, RFID, and similar technologies). Originally developed
#' for playground movement research, but applicable to any study collecting
#' high-frequency positional data from people moving within a defined space.
#' Provides functions for ID mapping, time period marking, data standardization,
#' and two-phase gap interpolation.
#'
#' @section Main Functions:
#'
#' **Complete Pipeline:**
#' * \code{\link{clean_playground_data}}: Master function running the complete pipeline
#'
#' **Data Preparation:**
#' * \code{\link{fix_tag_replacement}}: Fix tag replacements before cleaning
#'
#' **Individual Pipeline Steps:**
#' * \code{\link{map_ids}}: Map raw tracking IDs to standardized participant IDs
#' * \code{\link{mark_time_periods}}: Mark analysis and event time periods
#' * \code{\link{standardize_to_seconds}}: Standardize data to one-second intervals
#' * \code{\link{interpolate_gaps}}: Two-phase gap interpolation
#'
#' @section Typical Workflow:
#'
#' 1. Prepare an ID mapping CSV file with columns: raw_id, child_id
#' 2. Load your raw tracking data
#' 3. (Optional) Fix any tag replacements with \code{fix_tag_replacement()}
#' 4. Run \code{clean_playground_data()} with appropriate parameters
#' 5. Analyze the cleaned data
#'
#' @section Example:
#' \preformatted{
#' library(trackclean)
#' library(readr)
#'
#' raw_data <- read_csv(system.file("extdata", "raw_tracking_data.csv",
#'                                  package = "trackclean"))
#'
#' # Fix tag replacement (if needed)
#' raw_data <- fix_tag_replacement(
#'   data = raw_data,
#'   original_id = 3,
#'   replacement_id = 11,
#'   replacement_time = "2025-03-18 11:51:00"
#' )
#'
#' # Complete pipeline
#' cleaned_data <- clean_playground_data(
#'   data = raw_data,
#'   id_mapping = system.file("extdata", "id_mapping.csv", package = "trackclean"),
#'   analyze_start = "2025-03-18 11:47:00",
#'   analyze_end   = "2025-03-18 11:57:00",
#'   bell_start    = "2025-03-18 11:53:00",
#'   bell_end      = "2025-03-18 11:58:00"
#' )
#' }
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom magrittr %>%
#' @importFrom rlang .data :=
## usethis namespace: end
NULL
