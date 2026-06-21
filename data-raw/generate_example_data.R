# data-raw/generate_example_data.R
#
# Generates example tracking data for the trackclean package.
# Run once from the package root to (re)create inst/extdata/ files.
#
# Study context (used as example throughout the package):
#   10 children tracked during a school recess on a playground.
#   Area: 40m x 60m. System: UWB, ~1-3 readings per participant per second.
#   One child's tag was replaced mid-session.
#
# Output files:
#   inst/extdata/raw_tracking_data.csv
#   inst/extdata/id_mapping.csv

set.seed(42)

library(dplyr)
library(tibble)
library(readr)
library(lubridate)

# ---- Parameters --------------------------------------------------------------

start_time    <- as.POSIXct("2025-03-18 11:45:00", tz = "UTC")
end_time      <- as.POSIXct("2025-03-18 11:58:30", tz = "UTC")
replace_time  <- as.POSIXct("2025-03-18 11:51:00", tz = "UTC")

x_min <- 0;  x_max <- 40
y_min <- 0;  y_max <- 60

# ---- ID mapping --------------------------------------------------------------
# raw_id 3 and raw_id 11 both map to child_id 5003:
#   raw_id 3  = original tag (used until 11:51)
#   raw_id 11 = replacement tag (from 11:51 onwards)

id_mapping <- tibble(
  raw_id   = c(1:10, 11),
  child_id = c(5001:5010, 5003)
)

# ---- Movement simulation -----------------------------------------------------

simulate_trajectory <- function(raw_id, start_x, start_y,
                                start_time, end_time,
                                gap_prob    = 0.08,
                                double_prob = 0.22,
                                step_sd     = 0.25) {

  seconds <- seq(from = start_time, to = end_time, by = 1)
  n <- length(seconds)

  x <- numeric(n)
  y <- numeric(n)
  x[1] <- start_x
  y[1] <- start_y

  for (i in 2:n) {
    # Occasionally take a larger step (walking burst)
    scale <- ifelse(runif(1) < 0.12, 4, 1)
    x[i] <- max(x_min + 0.3, min(x_max - 0.3, x[i-1] + rnorm(1, 0, step_sd * scale)))
    y[i] <- max(y_min + 0.3, min(y_max - 0.3, y[i-1] + rnorm(1, 0, step_sd * scale)))
  }

  # Drop some seconds to create gaps for interpolation
  keep <- runif(n) > gap_prob
  keep[1] <- TRUE

  rows <- tibble(
    ID = raw_id,
    At = seconds[keep],
    X  = round(x[keep], 3),
    Y  = round(y[keep], 3)
  )

  # Add double-readings within the same second (sub-second offset)
  # These will be collapsed by standardize_to_seconds()
  n_rows <- nrow(rows)
  is_double <- runif(n_rows) < double_prob
  double_rows <- rows[is_double, ] %>%
    mutate(
      At = At + runif(sum(is_double), 0.05, 0.95),
      X  = round(X + rnorm(sum(is_double), 0, 0.04), 3),
      Y  = round(Y + rnorm(sum(is_double), 0, 0.04), 3)
    )

  bind_rows(rows, double_rows) %>% arrange(At)
}

# Starting positions distributed across the field
start_pos <- tibble(
  raw_id  = 1:10,
  start_x = c( 5, 15, 35,  8, 28, 20, 32, 12, 38, 22),
  start_y = c(10, 45, 55, 30,  5, 30, 20, 55, 40, 15)
)

# ---- Generate trajectories ---------------------------------------------------

all_data <- vector("list", 10)

for (i in 1:10) {
  rid <- start_pos$raw_id[i]
  sx  <- start_pos$start_x[i]
  sy  <- start_pos$start_y[i]

  if (rid == 3) {
    # Before tag replacement: raw_id 3
    before <- simulate_trajectory(
      raw_id = 3, start_x = sx, start_y = sy,
      start_time = start_time,
      end_time   = replace_time - seconds(1)
    )
    # After tag replacement: raw_id 11, continuing from last known position
    last <- tail(before, 1)
    after <- simulate_trajectory(
      raw_id = 11, start_x = last$X, start_y = last$Y,
      start_time = replace_time,
      end_time   = end_time
    )
    all_data[[i]] <- bind_rows(before, after)
  } else {
    all_data[[i]] <- simulate_trajectory(
      raw_id = rid, start_x = sx, start_y = sy,
      start_time = start_time,
      end_time   = end_time
    )
  }
}

raw_data <- bind_rows(all_data) %>%
  arrange(At, ID) %>%
  mutate(At = format(At, "%Y-%m-%d %H:%M:%OS2"))

# ---- Write output files ------------------------------------------------------

dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)

write_csv(id_mapping, "inst/extdata/id_mapping.csv")
write_csv(raw_data,   "inst/extdata/raw_tracking_data.csv")

message(sprintf(
  "raw_tracking_data.csv: %d rows across %d raw tag IDs (~%.0f sec of data)",
  nrow(raw_data),
  n_distinct(raw_data$ID),
  as.numeric(difftime(end_time, start_time, units = "secs"))
))
message(sprintf("id_mapping.csv: %d entries (11 tags, 10 participants)",
                nrow(id_mapping)))
message("")
message("Use these parameters in your analysis calls:")
message("  analyze_start  = '2025-03-18 11:47:00'")
message("  analyze_end    = '2025-03-18 11:57:00'")
message("  bell_start     = '2025-03-18 11:53:00'")
message("  bell_end       = '2025-03-18 11:58:00'")
message("  Tag replacement: raw_id 3 -> raw_id 11 at '2025-03-18 11:51:00'")
