#create jobs table 
jobs_table <- read.csv("ssp_modeling/output_postprocessing/data/levers/Sisepuede - Employment Results - WB (SECTOR).csv")
jobs_table$ssp_sector <- do.call(rbind, strsplit(as.character(jobs_table$Strategy), ":"))[,1]
jobs_table$ssp_transformation_name <- do.call(rbind, strsplit(as.character(jobs_table$Strategy), ":"))[,2]
jobs_table <- subset(jobs_table,Country=="BGR")

run_suffix <- ""
if (exists("run")) {
  run_timestamp <- if (grepl("^sisepuede_results_sisepuede_run_", run)) {
    sub("^sisepuede_results_sisepuede_run_", "", run)
  } else {
    run
  }
  run_suffix <- paste0("_", run_timestamp)
}

write.csv(jobs_table,paste0("ssp_modeling/tableau/data/jobs_demand_bulgaria", run_suffix, ".csv"))

print("Jobs table created")
