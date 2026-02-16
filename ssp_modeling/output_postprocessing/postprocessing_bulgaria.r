#################################################
# Post processing process
#################################################

# load packages
library(data.table)
library(reshape2)
library(mFilter)
library(ggplot2)

rm(list=ls())

#ouputfile

# Use this for normal run
# run <- 'sisepuede_results_sisepuede_run_2026-02-09T11;16;12.109722'

# # Use this for tornado run
run <- 'sisepuede_results_sisepuede_run_2026-02-09T12;59;59.346494'

# Use this for debugging tornado run
# run <- "sisepuede_results_sisepuede_run_2026-01-29T15;28;40.322709"

run_timestamp <- if (grepl("^sisepuede_results_sisepuede_run_", run)) {
  sub("^sisepuede_results_sisepuede_run_", "", run)
} else {
  run
}
run_suffix <- paste0("_", run_timestamp)

dir.output  <- paste0('ssp_modeling/ssp_run_output/', run, '/')
output.file <- paste0(run, '_WIDE_INPUTS_OUTPUTS.csv')

region <- "bulgaria" 
iso_code3 <- "BGR"

year_ref <- 2022

source('ssp_modeling/output_postprocessing/scr/run_script_baseline_run_new.r')

source('ssp_modeling/output_postprocessing/scr/data_prep_new_mapping.r')

source('ssp_modeling/output_postprocessing/scr/data_prep_drivers.r')

# Levers table
source('ssp_modeling/output_postprocessing/scr/levers_table/#create levers table.r')

# # Jobs table
# source('ssp_modeling/output_postprocessing/scr/levers_table/#create jobs table.r')
