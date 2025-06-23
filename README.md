# SSP_Mongolia

This repository contains notebooks and supporting files used to run the
**SISEPUEDE** model on Mongolia's mitigation scenarios. All modeling resources
reside in the `ssp_modeling` folder described below.


## Get Started

Create a conda environment with Python 3.11 (you can use any name):

```bash
conda create -n sisepuede python=3.11
```

Activate the environment:

```bash
conda activate sisepuede
```

Install the working version of the sisepuede package:

```bash
pip install git+https://github.com/jcsyme/sisepuede.git@working_version
```

Install the cost benefits package:

```bash
pip install git+https://github.com/milocortes/costs_benefits_ssp.git@main
```

Install additional libraries:

```bash
pip install -r requirements.txt
```

## Project Structure

The most relevant files are inside the `ssp_modeling` directory:

- `config_files/` – YAML configuration files used by the notebooks.
- `input_data/` – Raw CSVs for each scenario.
- `notebooks/` – Jupyter notebooks that manage the modeling runs.
- `ssp_run/` – Output folders created after executing a scenario.
- `scenario_mapping/` – Spreadsheets with the mapping between SSP transformations and region-specific measures. This is where the scenarios and transformation intensities are defined.
- `transformations/` – CSVs and YAML files describing the transformations applied by the model.
- `output_postprocessing/` – R scripts used to rescale model results and
    generate processed outputs.

## Mongolia Manager Workbooks

We use notebooks to drive the modeling process:

- **`mongolia_manager_wb.ipynb`** – Runs the mapped scenarios using
    `mongolia_config.yaml`.

Each notebook loads the appropriate configuration file, prepares the input data
frame, applies the transformations listed in the corresponding workbook, and
produces a CSV in `ssp_run/` with the results.
