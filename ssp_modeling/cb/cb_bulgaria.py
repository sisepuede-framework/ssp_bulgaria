# Load packages
from curses.ascii import alt
from costs_benefits_ssp.cb_calculate import CostBenefits
import numpy as np
import pandas as pd 
import os
import pathlib

# Define paths
dir_path = pathlib.Path(os.getcwd()) 

SSP_RESULTS_PATH = dir_path.joinpath("ssp_modeling/ssp_run")

# Load data
ssp_data = pd.read_csv(os.path.join(SSP_RESULTS_PATH, "sisepuede_results_sisepuede_mongolia_run.csv"))
ssp_data = ssp_data[ssp_data[['primary_id'] != 0]]
ssp_data.loc[ssp_data['primary_id'] == 69069, 'primary_id'] = 0

att_primary = pd.read_csv(os.path.join(SSP_RESULTS_PATH, "ATTRIBUTE_PRIMARY.csv"))
att_primary = att_primary[att_primary['primary_id'] != 0]
att_primary.loc[att_primary['primary_id'] == 69069, 'primary_id'] = 0
att_primary.loc[att_primary['strategy_id'] == 6003, 'strategy_id'] = 0


att_strategy = pd.read_csv(os.path.join(SSP_RESULTS_PATH, "ATTRIBUTE_STRATEGY.csv"))
att_strategy = att_strategy[att_strategy['strategy_id'] != 0]
att_strategy.loc[att_strategy['strategy_id'] == 6003, 'strategy_id'] = 0

# Define the strategy code base
# This is the code that will be used to identify the strategies in the cost-benefit analysis.
strategy_code_base = "PFLO:BAU"

# Instantiate CostBenefits object
cb = CostBenefits(ssp_data, att_primary, att_strategy, strategy_code_base)

# The export_db_to_excel method saves the initial configuration of the cost tables to an excel file.
# Each sheet represents a table in the cost and benefit program database.
# If the Excel file name is not given, the file will be saved with the default name cb_config_params.xlsx on the current python session.

CB_DEFAULT_DEFINITION_PATH = dir_path.joinpath("ssp_modeling/cb/cb_cost_factors")
CB_DEFAULT_DEFINITION_FILE_PATH = os.path.join(CB_DEFAULT_DEFINITION_PATH, "cb_config_params.xlsx")

cb.export_db_to_excel(CB_DEFAULT_DEFINITION_FILE_PATH)


# Once that the excel file has been updated, we can reload it in order to update the cost factors database
cb.load_cb_parameters(CB_DEFAULT_DEFINITION_FILE_PATH)

# Compute System Costs
results_system = cb.compute_system_cost_for_all_strategies()

# Compute Technical Costs
results_tx = cb.compute_technical_cost_for_all_strategies()

# Combine results
results_all = pd.concat([results_system, results_tx], ignore_index = True)

#-------------POST PROCESS SIMULATION RESULTS---------------
# Post process interactions among strategies that affect the same variables
results_all_pp = cb.cb_process_interactions(results_all)

# SHIFT any stray costs incurred from 2015 to 2025 to 2025 and 2035
results_all_pp_shifted = cb.cb_shift_costs(results_all_pp)

# Save the results
results_all_pp_shifted.to_csv(dir_path.joinpath("ssp_modeling/cb/cb_results/cost_benefit_results_tornado.csv"), index = False)