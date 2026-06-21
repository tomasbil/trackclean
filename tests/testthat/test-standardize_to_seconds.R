test_that("standardize_to_seconds collapses multiple readings in same second", {
  data <- data.frame(
    id_code = c(1L, 1L),
    At = as.POSIXct(c("2025-01-01 10:00:00.1", "2025-01-01 10:00:00.8"), tz = "UTC"),
    X  = c(10, 12),
    Y  = c(20, 22)
  )
  result <- standardize_to_seconds(data, verbose = FALSE)
  expect_equal(nrow(result), 1L)
  expect_equal(result$X, 11)
  expect_equal(result$Y, 21)
  expect_equal(result$n_entries, 2L)
  expect_equal(result$standardized, 1L)
})

test_that("standardize_to_seconds preserves single readings unchanged", {
  data <- data.frame(
    id_code = 1L,
    At = as.POSIXct("2025-01-01 10:00:00", tz = "UTC"),
    X  = 5.0,
    Y  = 10.0
  )
  result <- standardize_to_seconds(data, verbose = FALSE)
  expect_equal(nrow(result), 1L)
  expect_equal(result$X, 5.0)
  expect_equal(result$standardized, 0L)
  expect_equal(result$n_entries, 1L)
})

test_that("standardize_to_seconds produces one row per participant per interval", {
  data <- data.frame(
    id_code = c(1L, 1L, 2L, 2L),
    At = as.POSIXct(c(
      "2025-01-01 10:00:00.1", "2025-01-01 10:00:00.9",
      "2025-01-01 10:00:00.2", "2025-01-01 10:00:00.7"
    ), tz = "UTC"),
    X = c(1, 3, 10, 10),
    Y = c(1, 3, 20, 20)
  )
  result <- standardize_to_seconds(data, verbose = FALSE)
  expect_equal(nrow(result), 2L)
})

test_that("standardize_to_seconds respects custom unit", {
  data <- data.frame(
    id_code = 1L,
    At = as.POSIXct(c("2025-01-01 10:00:00", "2025-01-01 10:00:01"), tz = "UTC"),
    X = c(1, 3),
    Y = c(1, 3)
  )
  # With 2-second intervals, both readings fall in the same bin
  result <- standardize_to_seconds(data, unit = "2 seconds", verbose = FALSE)
  expect_equal(nrow(result), 1L)
  expect_equal(result$X, 2)
})
