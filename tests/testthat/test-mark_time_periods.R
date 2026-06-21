timestamps <- as.POSIXct(c(
  "2025-01-01 09:00:00",
  "2025-01-01 10:00:00",
  "2025-01-01 11:00:00"
), tz = "UTC")

test_that("mark_time_periods creates correct Analyze column", {
  data <- data.frame(At = timestamps)
  result <- mark_time_periods(data,
    analyze_start = "2025-01-01 09:30:00",
    analyze_end   = "2025-01-01 10:30:00")
  expect_equal(result$Analyze, c(0L, 1L, 0L))
})

test_that("mark_time_periods creates Bell column when bell times provided", {
  data <- data.frame(At = timestamps)
  result <- mark_time_periods(data,
    analyze_start = "2025-01-01 08:00:00",
    analyze_end   = "2025-01-01 12:00:00",
    bell_start    = "2025-01-01 09:30:00",
    bell_end      = "2025-01-01 10:30:00")
  expect_true("Bell" %in% names(result))
  expect_equal(result$Bell, c(0L, 1L, 0L))
})

test_that("mark_time_periods omits Bell column when bell times not provided", {
  data <- data.frame(At = timestamps)
  result <- mark_time_periods(data,
    analyze_start = "2025-01-01 08:00:00",
    analyze_end   = "2025-01-01 12:00:00")
  expect_false("Bell" %in% names(result))
})

test_that("mark_time_periods errors when analyze_start >= analyze_end", {
  data <- data.frame(At = timestamps)
  expect_error(
    mark_time_periods(data,
      analyze_start = "2025-01-01 11:00:00",
      analyze_end   = "2025-01-01 09:00:00"),
    "before"
  )
})

test_that("mark_time_periods respects custom column names", {
  data <- data.frame(ts = timestamps)
  result <- mark_time_periods(data,
    time_col      = "ts",
    analyze_start = "2025-01-01 09:30:00",
    analyze_end   = "2025-01-01 10:30:00",
    analyze_col   = "in_window")
  expect_true("in_window" %in% names(result))
  expect_equal(result$in_window, c(0L, 1L, 0L))
})
