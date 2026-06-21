test_that("map_ids maps IDs correctly from a data frame", {
  data <- data.frame(ID = c(1L, 2L, 3L), X = 1:3, Y = 1:3)
  mapping <- data.frame(raw_id = 1:3, child_id = c(101L, 102L, 103L))
  result <- map_ids(data, mapping)
  expect_equal(unname(result$id_code), c(101L, 102L, 103L))
})

test_that("map_ids returns NA id_code for unmapped IDs", {
  data <- data.frame(ID = c(1L, 99L), X = 1:2, Y = 1:2)
  mapping <- data.frame(raw_id = 1L, child_id = 101L)
  result <- map_ids(data, mapping)
  expect_true(is.na(result$id_code[result$ID == 99L]))
})

test_that("map_ids sets Analyze = 0 for excluded IDs", {
  data <- data.frame(ID = c(1L, 2L, 3L), X = 1:3, Y = 1:3)
  mapping <- data.frame(raw_id = 1:3, child_id = 101:103)
  result <- map_ids(data, mapping, exclude_ids = 2L)
  expect_equal(result$Analyze[result$ID == 2L], 0L)
  expect_equal(result$Analyze[result$ID != 2L], c(1L, 1L))
})

test_that("map_ids respects custom id_col name", {
  data <- data.frame(ID = 1L, X = 1, Y = 1)
  mapping <- data.frame(raw_id = 1L, child_id = 101L)
  result <- map_ids(data, mapping, id_col = "participant_id")
  expect_true("participant_id" %in% names(result))
  expect_false("id_code" %in% names(result))
})

test_that("map_ids errors when mapping file not found", {
  data <- data.frame(ID = 1L)
  expect_error(map_ids(data, "nonexistent.csv"), "not found")
})
