test_that("clean_playground_data runs on bundled example data without error", {
  skip_if_not_installed("readr")

  raw_data <- readr::read_csv(
    system.file("extdata", "raw_tracking_data.csv", package = "trackclean"),
    show_col_types = FALSE
  )

  raw_data <- fix_tag_replacement(raw_data,
    original_id      = 3L,
    replacement_id   = 11L,
    replacement_time = "2025-03-18 11:51:00")

  result <- clean_playground_data(
    data          = raw_data,
    id_mapping    = system.file("extdata", "id_mapping.csv", package = "trackclean"),
    analyze_start = "2025-03-18 11:47:00",
    analyze_end   = "2025-03-18 11:57:00",
    bell_start    = "2025-03-18 11:53:00",
    bell_end      = "2025-03-18 11:58:00",
    verbose       = FALSE
  )

  expected_cols <- c("id_code", "At", "X", "Y", "Analyze", "Bell",
                     "n_entries", "standardized", "imputed", "imputed_large")
  expect_true(all(expected_cols %in% names(result)))
  expect_true(nrow(result) > 0L)
})

test_that("clean_playground_data output flags are binary", {
  skip_if_not_installed("readr")

  raw_data <- readr::read_csv(
    system.file("extdata", "raw_tracking_data.csv", package = "trackclean"),
    show_col_types = FALSE
  )

  result <- clean_playground_data(
    data          = raw_data,
    id_mapping    = system.file("extdata", "id_mapping.csv", package = "trackclean"),
    analyze_start = "2025-03-18 11:47:00",
    analyze_end   = "2025-03-18 11:57:00",
    verbose       = FALSE
  )

  expect_true(all(result$Analyze %in% c(0L, 1L)))
  expect_true(all(result$imputed %in% c(0L, 1L)))
  expect_true(all(result$imputed_large %in% c(0L, 1L)))
  expect_true(all(result$standardized %in% c(0L, 1L)))
})

test_that("clean_playground_data works without bell period", {
  skip_if_not_installed("readr")

  raw_data <- readr::read_csv(
    system.file("extdata", "raw_tracking_data.csv", package = "trackclean"),
    show_col_types = FALSE
  )

  result <- clean_playground_data(
    data          = raw_data,
    id_mapping    = system.file("extdata", "id_mapping.csv", package = "trackclean"),
    analyze_start = "2025-03-18 11:47:00",
    analyze_end   = "2025-03-18 11:57:00",
    verbose       = FALSE
  )

  expect_false("Bell" %in% names(result))
})

test_that("clean_playground_data imputed rows have n_entries = 0", {
  skip_if_not_installed("readr")

  raw_data <- readr::read_csv(
    system.file("extdata", "raw_tracking_data.csv", package = "trackclean"),
    show_col_types = FALSE
  )

  result <- clean_playground_data(
    data          = raw_data,
    id_mapping    = system.file("extdata", "id_mapping.csv", package = "trackclean"),
    analyze_start = "2025-03-18 11:47:00",
    analyze_end   = "2025-03-18 11:57:00",
    verbose       = FALSE
  )

  imputed_rows <- result[result$imputed == 1L | result$imputed_large == 1L, ]
  if (nrow(imputed_rows) > 0) {
    expect_true(all(imputed_rows$n_entries == 0L))
  }
})
