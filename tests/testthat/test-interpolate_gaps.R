make_gap_data <- function(x_end = 3, y_end = 0, gap_secs = 3) {
  data.frame(
    id_code = c(1L, 1L),
    At = as.POSIXct(c("2025-01-01 10:00:00",
                       paste0("2025-01-01 10:00:0", gap_secs)), tz = "UTC"),
    X = c(0, x_end),
    Y = c(0, y_end),
    Analyze = c(1L, 1L),
    n_entries = c(1L, 1L),
    standardized = c(0L, 0L)
  )
}

test_that("interpolate_gaps fills phase 1 small gap with correct linear interpolation", {
  data <- make_gap_data(x_end = 3, y_end = 0, gap_secs = 3)
  result <- interpolate_gaps(data, max_gap_small = 10, verbose = FALSE)

  # 3-second gap -> 2 interpolated points at t+1 and t+2
  expect_equal(nrow(result), 4L)
  expect_equal(sum(result$imputed), 2L)

  imputed <- result[result$imputed == 1L, ]
  expect_equal(imputed$X, c(1, 2))
  expect_equal(imputed$Y, c(0, 0))
})

test_that("interpolate_gaps does not fill gaps larger than max_gap_small with large movement", {
  data <- make_gap_data(x_end = 20, y_end = 20, gap_secs = 5)
  result <- interpolate_gaps(data,
    max_gap_small = 3,
    max_position_change = 0.3,
    verbose = FALSE)
  expect_equal(nrow(result), 2L)
  expect_equal(sum(result$imputed), 0L)
  expect_equal(sum(result$imputed_large), 0L)
})

test_that("interpolate_gaps fills phase 2 large gaps with small position change", {
  data <- make_gap_data(x_end = 0.1, y_end = 0.1, gap_secs = 5)
  result <- interpolate_gaps(data,
    max_gap_small = 3,
    max_position_change = 0.3,
    verbose = FALSE)
  expect_true(sum(result$imputed_large) > 0L)
  expect_equal(sum(result$imputed), 0L)
})

test_that("interpolate_gaps does not fill phase 2 gaps with large position change", {
  data <- make_gap_data(x_end = 5, y_end = 5, gap_secs = 5)
  result <- interpolate_gaps(data,
    max_gap_small = 3,
    max_position_change = 0.3,
    verbose = FALSE)
  expect_equal(nrow(result), 2L)
  expect_equal(sum(result$imputed_large), 0L)
})

test_that("interpolate_gaps respects max_gap_large limit in phase 2", {
  # 20-second gap, small movement — beyond max_gap_large so should not be filled
  data <- data.frame(
    id_code = c(1L, 1L),
    At = as.POSIXct(c("2025-01-01 10:00:00", "2025-01-01 10:00:20"), tz = "UTC"),
    X = c(0, 0.1),
    Y = c(0, 0.1),
    Analyze = c(1L, 1L),
    n_entries = c(1L, 1L),
    standardized = c(0L, 0L)
  )
  result <- interpolate_gaps(data,
    max_gap_small = 5,
    max_gap_large = 10,
    max_position_change = 0.3,
    verbose = FALSE)
  expect_equal(sum(result$imputed_large), 0L)
})

test_that("interpolate_gaps sets n_entries = 0 and standardized = 0 on imputed rows", {
  data <- make_gap_data(x_end = 3, gap_secs = 3)
  result <- interpolate_gaps(data, max_gap_small = 10, verbose = FALSE)
  imputed <- result[result$imputed == 1L, ]
  expect_true(all(imputed$n_entries == 0L))
  expect_true(all(imputed$standardized == 0L))
})

test_that("interpolate_gaps does not interpolate outside Analyze period", {
  data <- data.frame(
    id_code = c(1L, 1L),
    At = as.POSIXct(c("2025-01-01 10:00:00", "2025-01-01 10:00:03"), tz = "UTC"),
    X = c(0, 3),
    Y = c(0, 0),
    Analyze = c(0L, 0L),  # outside analysis window
    n_entries = c(1L, 1L),
    standardized = c(0L, 0L)
  )
  result <- interpolate_gaps(data, max_gap_small = 10, verbose = FALSE)
  expect_equal(nrow(result), 2L)
  expect_equal(sum(result$imputed), 0L)
})

test_that("interpolate_gaps works correctly with time_step = 2", {
  data <- data.frame(
    id_code = c(1L, 1L),
    At = as.POSIXct(c("2025-01-01 10:00:00", "2025-01-01 10:00:06"), tz = "UTC"),
    X = c(0, 6),
    Y = c(0, 0),
    Analyze = c(1L, 1L),
    n_entries = c(1L, 1L),
    standardized = c(0L, 0L)
  )
  result <- interpolate_gaps(data, time_step = 2, max_gap_small = 10, verbose = FALSE)
  # 6-second gap with 2-second step -> 2 interpolated rows at t+2 and t+4
  expect_equal(sum(result$imputed), 2L)
  imputed <- result[result$imputed == 1L, ]
  expect_equal(imputed$X, c(2, 4))
})
