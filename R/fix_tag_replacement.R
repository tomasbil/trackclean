#' Fix tag replacements in raw data
#'
#' Handles cases where a participant's tracking tag was replaced during data collection.
#' Renames observations from the new tag to the original ID and removes invalid observations.
#'
#' @param data A data frame with raw tracking data
#' @param original_id The participant's original tag ID
#' @param replacement_id The new tag ID that replaced the original
#' @param replacement_time Time when tag was replaced (POSIXct or character, e.g. \code{"2025-03-18 11:20:00"})
#' @param time_col Name of the timestamp column (default: "At")
#' @param id_col Name of the ID column (default: "ID")
#'
#' @return Data frame with corrected IDs:
#'   - Observations from replacement_id >= replacement_time are renamed to original_id
#'   - Observations from original_id >= replacement_time are removed
#'   - Observations from replacement_id < replacement_time are removed
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Tag 106 replaced tag 159 at 11:20
#' raw_data <- fix_tag_replacement(
#'   data = raw_data,
#'   original_id = 159,
#'   replacement_id = 106,
#'   replacement_time = "2025-03-18 11:20:00"
#' )
#' }
fix_tag_replacement <- function(data,
                                original_id,
                                replacement_id,
                                replacement_time,
                                time_col = "At",
                                id_col = "ID") {

  data <- data %>%
    dplyr::mutate(!!time_col := as.POSIXct(.data[[time_col]]))

  if (is.character(replacement_time)) {
    replacement_time <- lubridate::ymd_hms(replacement_time)
  }

  n_original_before <- sum(data[[id_col]] == original_id & data[[time_col]] < replacement_time)
  n_original_after <- sum(data[[id_col]] == original_id & data[[time_col]] >= replacement_time)
  n_replacement_before <- sum(data[[id_col]] == replacement_id & data[[time_col]] < replacement_time)
  n_replacement_after <- sum(data[[id_col]] == replacement_id & data[[time_col]] >= replacement_time)

  # Mark rows to remove before renaming, to avoid ID collisions
  data <- data %>%
    dplyr::mutate(
      .remove = dplyr::case_when(
        .data[[id_col]] == original_id & .data[[time_col]] >= replacement_time ~ TRUE,
        .data[[id_col]] == replacement_id & .data[[time_col]] < replacement_time ~ TRUE,
        TRUE ~ FALSE
      )
    )

  data <- data %>%
    dplyr::mutate(
      !!id_col := dplyr::case_when(
        .data[[id_col]] == replacement_id & .data[[time_col]] >= replacement_time ~ original_id,
        TRUE ~ .data[[id_col]]
      )
    ) %>%
    dplyr::filter(!.remove) %>%
    dplyr::select(-.remove)

  message("\n=== Tag Replacement Fix ===")
  message(sprintf("Original ID: %d, Replacement ID: %d", original_id, replacement_id))
  message(sprintf("Replacement time: %s", format(replacement_time, "%Y-%m-%d %H:%M:%S")))
  message(sprintf("\nBefore replacement time (< %s):", format(replacement_time, "%H:%M")))
  message(sprintf("  [OK] Kept from original tag (%d): %d observations", original_id, n_original_before))
  message(sprintf("  [REMOVED] Removed from replacement tag (%d): %d observations", replacement_id, n_replacement_before))
  message(sprintf("\nFrom replacement time onwards (>= %s):", format(replacement_time, "%H:%M")))
  message(sprintf("  [OK] Renamed %d -> %d: %d observations", replacement_id, original_id, n_replacement_after))
  message(sprintf("  [REMOVED] Removed from original tag (%d): %d observations\n", original_id, n_original_after))

  return(data)
}
