# trackclean 0.1.0

* Initial release.
* Functions for the complete cleaning pipeline: `map_ids()`, `mark_time_periods()`, `standardize_to_seconds()`, `interpolate_gaps()`, `fix_tag_replacement()`, and `clean_playground_data()`.
* Two-phase gap interpolation: phase 1 for small gaps, phase 2 for larger gaps with minimal position change.
* Configurable time interval for standardization (`unit` parameter) and matching interpolation step (`time_step`).
* All column names are user-configurable with sensible defaults.
* Bundled example dataset (10 participants, 40m x 60m space, ~13 minutes) in `inst/extdata/`.
