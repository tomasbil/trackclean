make_tag_data <- function() {
  data.frame(
    ID = c(3L, 3L, 11L, 11L),
    At = as.POSIXct(c(
      "2025-01-01 10:00:00", "2025-01-01 10:29:00",
      "2025-01-01 10:05:00", "2025-01-01 10:31:00"
    ), tz = "UTC"),
    X = c(1, 2, 99, 3),
    Y = c(1, 2, 99, 3)
  )
}

test_that("fix_tag_replacement renames replacement tag to original ID", {
  result <- fix_tag_replacement(make_tag_data(),
    original_id      = 3L,
    replacement_id   = 11L,
    replacement_time = "2025-01-01 10:30:00")
  expect_false(11L %in% result$ID)
  expect_true(all(result$ID == 3L))
})

test_that("fix_tag_replacement removes original tag observations after replacement time", {
  data <- data.frame(
    ID = c(3L, 3L, 11L),
    At = as.POSIXct(c("2025-01-01 10:00:00", "2025-01-01 10:31:00",
                       "2025-01-01 10:31:00"), tz = "UTC"),
    X  = c(1, 2, 3), Y = c(1, 2, 3)
  )
  result <- fix_tag_replacement(data,
    original_id      = 3L,
    replacement_id   = 11L,
    replacement_time = "2025-01-01 10:30:00")
  # Original tag row at 10:31 removed; replacement tag row at 10:31 renamed to 3 and kept
  expect_equal(nrow(result), 2L)
  expect_true(all(result$ID == 3L))
})

test_that("fix_tag_replacement removes replacement tag observations before replacement time", {
  result <- fix_tag_replacement(make_tag_data(),
    original_id      = 3L,
    replacement_id   = 11L,
    replacement_time = "2025-01-01 10:30:00")
  # The row with X = 99 (replacement tag before swap time) should be gone
  expect_false(99 %in% result$X)
})

test_that("fix_tag_replacement accepts character replacement_time", {
  expect_no_error(
    fix_tag_replacement(make_tag_data(),
      original_id      = 3L,
      replacement_id   = 11L,
      replacement_time = "2025-01-01 10:30:00")
  )
})
