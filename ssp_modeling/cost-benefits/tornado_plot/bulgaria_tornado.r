# --------------------------------------------------
# Build tornado plot table (Updated for new strategy format)
# Only supports:
#   - Strategy TX:BASE
#   - Singleton - Default Value - ...
# Also removes: strategy == "Historical"
# --------------------------------------------------

library(reshape2)

# -----------------------------
# Paths
# -----------------------------
root <- "/Users/tony/Documents/sisepuede_modeling/ssp_bulgaria/ssp_modeling/cost-benefits/tornado_plot/"
dir.data <- paste0(root, "data/input/")
dir.out  <- paste0(root, "data/output/")

# -----------------------------
# Target sectors
# -----------------------------
target_sectors <- c(
  "AG - Crops",
  "AG - Livestock",
  "IN - Industrial Processes",
  "LULUCF - Forest Land",
  "LULUCF - HWP",
  "LULUCF - Wetlands",
  "LULUCF - Cropland",
  "LULUCF - Grassland",
  "LULUCF - Settlements",
  "LULUCF - Other Land",
  "Waste - Solid Waste",
  "Waste - Wastewater Treatment"
)

# -----------------------------
# Load tornado emissions file
# -----------------------------
file.name <- "decomposed_emissions_bulgaria_2022_tornado.csv"
tornado <- read.csv(paste0(dir.data, file.name))

# Remove Historical
tornado <- subset(tornado, strategy != "Historical")

# Keep target subsectors
tornado <- subset(tornado, CSC.Subsector %in% target_sectors)

cat("Tornado raw dim:", dim(tornado), "\n")
cat("Unique strategies (tornado):\n")
print(unique(tornado$strategy))

# -----------------------------
# Aggregate at inventory level
# -----------------------------
tornado <- aggregate(
  list(value = tornado$value),
  by = list(
    primary_id   = tornado$primary_id,
    strategy_id  = tornado$strategy_id,
    strategy     = tornado$strategy
  ),
  sum,
  na.rm = TRUE
)

# -----------------------------
# Identify baseline (TX:BASE)
# -----------------------------
base_runs <- subset(tornado, grepl("TX:BASE", strategy))

if (nrow(base_runs) == 0) {
  stop("No TX:BASE baseline run found in tornado data.")
}

# baseline by primary_id (this avoids hardcoding any number like 48.64)
base_tbl <- base_runs[, c("primary_id", "value")]
colnames(base_tbl) <- c("primary_id", "base_value")

# -----------------------------
# Keep only Singleton strategies
# -----------------------------
singleton_runs <- subset(tornado, grepl("^Singleton - Default Value", strategy))

if (nrow(singleton_runs) == 0) {
  stop("No Singleton strategies found in tornado data.")
}

# Merge baseline into singleton runs
singleton_runs <- merge(singleton_runs, base_tbl, by = "primary_id", all.x = TRUE)

# Diff from baseline
singleton_runs$emissions_diff <- singleton_runs$value - singleton_runs$base_value

# -----------------------------
# Build strategy_code in a robust way
# -----------------------------
# Example:
# "Singleton - Default Value - PFLO: Industrial c..."
# -> strategy_code = "Singleton_Default_Value_PFLO"
singleton_runs$strategy_code <- singleton_runs$strategy

# remove prefix
singleton_runs$strategy_code <- gsub("^Singleton - Default Value -\\s*", "", singleton_runs$strategy_code)

# keep first token before ":" if present (e.g. PFLO)
singleton_runs$strategy_code <- ifelse(
  grepl(":", singleton_runs$strategy_code),
  sub(":.*$", "", singleton_runs$strategy_code),
  singleton_runs$strategy_code
)

# sanitize
singleton_runs$strategy_code <- gsub("[^A-Za-z0-9_]+", "_", singleton_runs$strategy_code)
singleton_runs$strategy_code <- gsub("_+", "_", singleton_runs$strategy_code)

# add readable label too
singleton_runs$strategy_label <- singleton_runs$strategy

# -----------------------------
# OPTIONAL: merge strategy_names.csv if you still want
# -----------------------------
# If strategy_names exists and contains mapping for these strategy codes.
strategy_names_file <- paste0(dir.data, "strategy_names.csv")

if (file.exists(strategy_names_file)) {
  strategy_names <- read.csv(strategy_names_file)

  # normalize if it has TX:
  if ("strategy_code" %in% colnames(strategy_names)) {
    strategy_names$strategy_code <- gsub("^TX:", "", strategy_names$strategy_code)
  }

  singleton_runs <- merge(singleton_runs, strategy_names, by = "strategy_code", all.x = TRUE)
  cat("Merged strategy_names.csv\n")
}

# -----------------------------
# Load cost-benefit data and process
# -----------------------------
target_cb_file <- "costs_benefits_sisepuede_results_sisepuede_run_2026-01-12T18;06;55.813694_tornado_raw.csv"
cb_data <- read.csv(paste0(dir.data, target_cb_file))

cat("cb_data dim:", dim(cb_data), "\n")

# Parse cb variable
cb_chars <- data.frame(do.call(rbind, strsplit(as.character(cb_data$variable), ":")))
colnames(cb_chars) <- c("name","sector","cb_type","item_1","item_2")
cb_data <- cbind(cb_data, cb_chars)

# Scale units
cb_data$value <- cb_data$value / 1e9

# Year
cb_data$Year <- cb_data$time_period + 2015

# Merge strategy ids from ATTRIBUTE_STRATEGY.csv
as_file <- paste0(dir.data, "ATTRIBUTE_STRATEGY.csv")
as <- read.csv(as_file)
as <- unique(as[, c("strategy_code", "strategy_id")])

cb_data <- merge(cb_data, as, by = "strategy_code")

# Subset cb sectors (keep as in your original)
cb <- cb_data
cb <- subset(cb, sector %in% c("waso","soil","ippu","lvst","agrc","lndu","lsmm"))

# Aggregate cost-benefit by strategy
cb <- aggregate(
  list(Cumulative = cb$value),
  by = list(strategy_id = cb$strategy_id, cb_type = cb$cb_type),
  sum,
  na.rm = TRUE
)

# Wide format
wide_cb <- dcast(cb, strategy_id ~ cb_type, value.var = "Cumulative")
wide_cb[is.na(wide_cb)] <- 0

cb_cats <- setdiff(colnames(wide_cb), "strategy_id")

# add summary cols
wide_cb$net_benefit <- rowSums(wide_cb[, cb_cats, drop = FALSE])
wide_cb$additional_benefits <- rowSums(wide_cb[, setdiff(cb_cats, "technical_cost"), drop = FALSE])

# handle missing cols safely
cols_total_cost <- intersect(c("technical_cost", "technical_savings", "fuel_cost"), colnames(wide_cb))
wide_cb$total_transformation_costs <- rowSums(wide_cb[, cols_total_cost, drop = FALSE])

cb_cats <- c(cb_cats, "net_benefit", "additional_benefits", "total_transformation_costs")

# -----------------------------
# Choose baseline strategy for CB (TX:BASE)
# -----------------------------
# If you have a true base_id, keep it.
# Otherwise auto-detect from emissions file strategy_id of TX:BASE.

# base_id <- unique(base_runs$strategy_id)
base_id <- 1000 #NOTE: I hardcoiding it here to test MAKE SURE TO REVISE THIS!!!
if (length(base_id) != 1) {
  stop("Could not uniquely identify baseline strategy_id for TX:BASE in emissions tornado data.")
}

base_cb <- subset(wide_cb, strategy_id == base_id)
if (nrow(base_cb) == 0) {
  stop("Baseline strategy_id from emissions not found in cost-benefit wide_cb.")
}

colnames(base_cb) <- paste0(colnames(base_cb), "_ref")
base_cb$strategy_id_ref <- NULL

wide_cb <- merge(wide_cb, base_cb)

# Differences vs baseline
for (i in seq_along(cb_cats)) {
  wide_cb[, cb_cats[i]] <- wide_cb[, paste0(cb_cats[i], "_ref")] - wide_cb[, cb_cats[i]]
}

wide_cb[, paste0(cb_cats, "_ref")] <- NULL

# -----------------------------
# Merge CB into singleton tornado table
# -----------------------------
tornado_final <- merge(singleton_runs, wide_cb, by = "strategy_id", all.x = TRUE)

cat("Final tornado dim:", dim(tornado_final), "\n")

# -----------------------------
# Export
# -----------------------------
write.csv(tornado_final, paste0(dir.out, "tornado_plot.csv"), row.names = FALSE)

cat("✅ Wrote tornado CSV to:", paste0(dir.out, "tornado_plot.csv"), "\n")
