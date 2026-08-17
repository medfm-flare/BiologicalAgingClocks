**Eight decades of follow-up link life-course exposures to proteomic organ ageing and longevity**

This repository contains the analysis code supporting the manuscript:
“Eight decades of follow-up link life-course exposures to proteomic organ ageing and longevity.”

The repository provides a structured, script-based workflow for deriving proteomic organ ageing measures from SomaScan data, integrating life-course and mortality variables, handling missing data, and performing the main statistical analyses reported in the manuscript.

**Data access**

The underlying data used in this study are not publicly available due to participant confidentiality and data governance restrictions.
NSHD data: Bona fide researchers can apply to access the NSHD data via a standard application procedure (https://skylark.ucl.ac.uk/NSHD/access/).
Mortality data: Clinical data is not available for external data request due to data agreements with NHS Digital.
UK Biobank data: Available through application to UK Biobank (https://www.ukbiobank.ac.uk).
This repository provides the code required to reproduce the analytical workflow and results for researchers with appropriate data access.

**Overview of workflow**

The analysis proceeds through the following stages:
- Loading and cleaning SomaScan proteomic data from .adat files
- Deriving organ-specific ageing measures using externally developed models
- Loading and merging life-course, covariate, and mortality data
- Performing multiple imputation for missing data
- Running the main analyses corresponding to the study aims
- Conducting replication analyses in UK Biobank
- Intermediate outputs are saved between steps, and the workflow is designed to be run sequentially through the scripts provided in this repository.

**Running the analysis**

Scripts should be run in the following order:

NSHD analysis

1_Loading_and_cleaning_proteomic_data_rev.R

Loads and preprocesses SomaScan proteomic data from .adat files.

2_Generate_organ_ages_rev.ipynb

Applies externally developed proteomic ageing clocks to derive organ-specific age estimates.

3_Load_variables_and_clean_data_rev.R

Loads and cleans life-course exposures, covariates, and mortality outcomes, and merges them with the proteomic dataset.

4_Multiple_imputation_rev.R

Performs multiple imputation for missing exposure and covariate data.

5_Aim_1_Generate_Results_rev.R

Addresses **Q1: Does organ ageing vary in an identically aged birth cohort?**

6_Aim_2_Generate_Results_rev.R

Addresses **Q2: Is accelerated organ ageing a prognostic indicator for mortality risk?**

7_Aim_3_Generate_Results_rev.R

Addresses **Q3: Which life-course factors shape organ ageing?**

8_Aim_4_Generate_Results_rev.R

Addresses **Q4: Which proteins best capture life-course exposures and mortality risk?**

UK Biobank replication

9_UKB_load_and_clean_data.R

Loads and preprocesses UK Biobank data.

10_UKB_analysis.R

Performs replication analyses in UK Biobank.

**Input data**

The workflow expects the following input types:

Proteomic data in SomaScan .adat format
Life-course exposure data
Covariate data
Mortality and clinical diagnosis outcome data

Data are structured with one row per participant, with proteomic measurements represented as columns. These components are merged during the workflow to create the final analysis dataset.

**Organ ageing models**

Organ-specific ageing measures are derived by applying externally developed proteomic ageing models through the publicly available organage Python package:
https://github.com/hamiltonoh/organage

This repository provides code for the application of these models to the study data. The models themselves are not re-trained here.

**Software requirements**

R version 4.4.1

Python version 3.8

