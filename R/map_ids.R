#' Map raw tracking IDs to standardized child IDs
#'
#' @param data A data frame with raw tracking data
#' @param mapping Either:
#'   - Path to CSV file with columns 'raw_id' and 'child_id'
#'   - Data frame with columns 'raw_id' and 'child_id'
#'   - Named vector (raw_id = child_id)
#' @param exclude_ids Vector of raw IDs to exclude from analysis (sets Analyze = 0)
#' @param raw_id_col Name of the raw ID column in data (default: "ID")
#' @param id_col Name of the output column for standardized IDs (default: "id_code")
#' @param analyze_col Name of the Analyze column in data (default: "Analyze")
#'
#' @return Data frame with added id_code column and updated Analyze column
#' @export
#' @importFrom stats setNames
#'
#' @examples
#' \dontrun{
#' # Using a CSV file (recommended)
#' data_mapped <- map_ids(raw_data, "id_mapping.csv", exclude_ids = c(67, 72, 80))
#'
#' # Using a data frame
#' id_map <- data.frame(raw_id = c(2, 3, 6), child_id = c(5129, 5113, 5222))
#' data_mapped <- map_ids(raw_data, id_map, exclude_ids = c(67, 72, 80))
#' }
map_ids <- function(data,
                    mapping,
                    exclude_ids = NULL,
                    raw_id_col = "ID",
                    id_col = "id_code",
                    analyze_col = "Analyze") {

  if (is.character(mapping) && length(mapping) == 1) {
    if (!file.exists(mapping)) {
      stop(sprintf("Mapping file not found: %s", mapping))
    }
    mapping <- readr::read_csv(mapping,
                               col_types = readr::cols(
                                 raw_id = readr::col_integer(),
                                 child_id = readr::col_integer()
                               ),
                               show_col_types = FALSE)
  }

  if (is.data.frame(mapping)) {
    if (!all(c("raw_id", "child_id") %in% names(mapping))) {
      stop("Mapping must have columns 'raw_id' and 'child_id'")
    }
    mapping_vec <- setNames(mapping$child_id, as.character(mapping$raw_id))
  } else if (is.vector(mapping)) {
    mapping_vec <- mapping
  } else {
    stop("Mapping must be a file path, data frame, or named vector")
  }

  data <- data %>%
    dplyr::mutate(
      !!id_col := mapping_vec[as.character(.data[[raw_id_col]])]
    )

  if (!is.null(exclude_ids)) {
    if (!analyze_col %in% names(data)) {
      data <- data %>%
        dplyr::mutate(!!analyze_col := 1L)
    }

    data <- data %>%
      dplyr::mutate(
        !!analyze_col := dplyr::if_else(
          .data[[raw_id_col]] %in% exclude_ids,
          0L,
          .data[[analyze_col]]
        )
      )
  }

  n_mapped <- sum(!is.na(data[[id_col]]))
  n_unmapped <- sum(is.na(data[[id_col]]))
  n_excluded <- if (!is.null(exclude_ids)) sum(data[[raw_id_col]] %in% exclude_ids) else 0

  message(sprintf("ID Mapping Results:
  - Mapped: %d rows
  - Unmapped (NA): %d rows
  - Excluded from analysis: %d rows", n_mapped, n_unmapped, n_excluded))

  return(data)
}
