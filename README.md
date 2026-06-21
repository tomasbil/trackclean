# trackclean

Tools for cleaning high-frequency real-time location tracking data.

`trackclean` was developed to process data from playground movement research, but applies to any study collecting high-frequency positional data from people moving within a defined space — classrooms, sports facilities, rehabilitation settings, and similar environments.

## Installation

```r
# Install from local source
devtools::install()

# Or if the package is in another location
devtools::install("path/to/trackclean")
```

## Example Data

The package includes a small example dataset that can be used to trial the full pipeline without any real data. It simulates 10 children tracked during a school recess on a 40m × 60m playground using a UWB positioning system.

```r
library(trackclean)
library(readr)

raw_data   <- read_csv(system.file("extdata", "raw_tracking_data.csv", package = "trackclean"))
id_mapping <- system.file("extdata", "id_mapping.csv", package = "trackclean")
```

The example dataset includes:
- 10 participants with raw tag IDs 1–10, mapped to child IDs 5001–5010
- ~13.5 minutes of data (11:45:00–11:58:30), with observations both inside and outside the analysis window
- Sub-second timestamps causing multiple readings per second — handled by `standardize_to_seconds()`
- Randomly dropped seconds creating gaps — handled by `interpolate_gaps()`
- One tag replacement: participant 5003 starts on raw tag ID 3, which is swapped to raw tag ID 11 at 11:51:00 — handled by `fix_tag_replacement()`

**Analysis parameters for this dataset:**

| Parameter | Value |
|-----------|-------|
| `analyze_start` | `"2025-03-18 11:47:00"` |
| `analyze_end` | `"2025-03-18 11:57:00"` |
| `bell_start` | `"2025-03-18 11:53:00"` |
| `bell_end` | `"2025-03-18 11:58:00"` |
| Tag replacement | raw_id 3 → raw_id 11 at `"2025-03-18 11:51:00"` |

### Expected input format

**Raw tracking data** (`raw_tracking_data.csv`):

| ID | At | X | Y |
|----|----|---|---|
| 1 | 2025-03-18 11:45:00.00 | 5.000 | 10.000 |
| 1 | 2025-03-18 11:45:01.00 | 5.383 | 10.239 |
| 1 | 2025-03-18 11:45:01.47 | 5.341 | 10.261 |
| ... | | | |

- `ID`: raw tag ID as assigned by the tracking system
- `At`: timestamp (POSIXct-readable, sub-second precision supported)
- `X`, `Y`: position in meters

**ID mapping** (`id_mapping.csv`):

| raw_id | child_id |
|--------|----------|
| 1 | 5001 |
| 3 | 5003 |
| 11 | 5003 |
| ... | |

- `raw_id`: tag ID as it appears in the raw data
- `child_id`: standardized participant ID to use in analysis
- A participant with a replaced tag appears twice (one row per tag, same `child_id`)

## Quick Start

### Optional: Fix Tag Replacements

If a participant's tag was replaced during data collection, run this before the main pipeline:

```r
raw_data <- fix_tag_replacement(
  data = raw_data,
  original_id = 3,
  replacement_id = 11,
  replacement_time = "2025-03-18 11:51:00"
)
```

This will:
- Keep observations from tag 3 before 11:51
- Rename tag 11 observations from 11:51 onwards to tag 3
- Remove tag 3 observations from 11:51 onwards (duplicate/invalid)
- Remove tag 11 observations before 11:51 (not yet attached)

### 1. Prepare Your ID Mapping

Create a CSV file with two columns mapping raw device IDs to your participant IDs:

```csv
raw_id,child_id
1,5001
2,5002
3,5003
```

Or use the bundled example file:

```r
id_mapping <- system.file("extdata", "id_mapping.csv", package = "trackclean")
```

### 2. Run the Complete Pipeline

```r
library(trackclean)
library(readr)

raw_data <- read_csv(system.file("extdata", "raw_tracking_data.csv", package = "trackclean"))

# Fix tag replacement first (if applicable)
raw_data <- fix_tag_replacement(
  data = raw_data,
  original_id = 3,
  replacement_id = 11,
  replacement_time = "2025-03-18 11:51:00"
)

cleaned_data <- clean_playground_data(
  data = raw_data,
  id_mapping = system.file("extdata", "id_mapping.csv", package = "trackclean"),
  analyze_start = "2025-03-18 11:47:00",
  analyze_end   = "2025-03-18 11:57:00",
  bell_start    = "2025-03-18 11:53:00",
  bell_end      = "2025-03-18 11:58:00",
  output_file   = "cleaned_data.csv"
)
```

### 3. Use Individual Functions

For more control, run each step separately:

```r
# Step 1: Map IDs
data <- map_ids(raw_data, id_mapping)

# Step 2: Mark time periods
data <- mark_time_periods(
  data,
  analyze_start = "2025-03-18 11:47:00",
  analyze_end   = "2025-03-18 11:57:00",
  bell_start    = "2025-03-18 11:53:00",
  bell_end      = "2025-03-18 11:58:00"
)

# Step 3: Standardize to seconds
data <- standardize_to_seconds(data)

# Step 4: Interpolate gaps
data <- interpolate_gaps(
  data,
  max_gap_small = 10,
  max_position_change = 0.3
)
```

## Key Features

### Two-Phase Gap Interpolation

The package uses a two-phase approach to handle missing data:

**Phase 1**: Interpolates small gaps (≤10 seconds by default)
- Uses linear interpolation between known points
- Appropriate for brief signal losses

**Phase 2**: Interpolates larger gaps conditionally
- Only when position change between endpoints is minimal (≤30cm by default)
- Indicates the participant remained stationary during the gap
- Prevents false movement estimates for longer signal dropouts

### Quality Assurance

All functions provide:
- Progress messages and summaries
- Data integrity checks
- Row count validation
- Clear flagging of imputed vs. original data

## Function Reference

| Function | Purpose |
|----------|---------|
| `clean_playground_data()` | Complete pipeline in one call |
| `fix_tag_replacement()` | Fix tag replacements (run before pipeline) |
| `map_ids()` | Map raw device IDs to participant IDs |
| `mark_time_periods()` | Create Analyze and Bell columns |
| `standardize_to_seconds()` | Aggregate to one-second intervals |
| `interpolate_gaps()` | Two-phase gap interpolation |

## Output Columns

The cleaned dataset includes these flags:

- `id_code`: Standardized participant ID
- `Analyze`: 1 if within analysis period, 0 otherwise
- `Bell`: 1 if within bell period, 0 otherwise (if specified)
- `n_entries`: Original number of signals in that second
- `standardized`: 1 if multiple signals were averaged, 0 otherwise
- `imputed`: 1 if row added via phase 1 interpolation
- `imputed_large`: 1 if row added via phase 2 interpolation

## Parameters

### Customizable Thresholds

```r
cleaned_data <- clean_playground_data(
  data = raw_data,
  id_mapping = "id_mapping.csv",
  analyze_start = "2025-03-18 11:47:00",
  analyze_end   = "2025-03-18 11:57:00",
  max_gap_small = 5,             # Phase 1: ≤5 seconds
  max_gap_large = 30,            # Phase 2: ≤30 seconds max
  max_position_change = 0.5      # Phase 2: ≤50cm movement
)
```

## Author

Tomas Bilevicius

## License

CC BY 4.0 — you are free to use, share, and adapt this package for any purpose, including commercially, as long as you give appropriate credit to the author.
