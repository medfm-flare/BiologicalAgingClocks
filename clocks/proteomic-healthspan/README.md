## Healthspan Proteomic Score (HPS)

## Preprint
A proteomic signature of healthspan
Kuo CL, Liu P, Drouard G, Vuoksimaa E, Kaprio J, Ollikainen M, Chen Z, Pilling LC, Atkins JL, Fortinsky RH, Kuchel GA, Diniz BS. A proteomic signature of healthspan. Proc Natl Acad Sci U S A. 2025 Jun 10;122(23):e2414086122. doi: 10.1073/pnas.2414086122. Epub 2025 Jun 6. PMID: 40478878.

We developed a proteomics-based signature of healthspan (healthspan proteomic score (HPS)) using data from the UK Biobank Pharma Proteomics Project (53,018 individuals and 2920 proteins). In line with previous studies, we defined healthspan as the number of years from birth without a major chronic medical condition, including cancer (excluding non-melanoma skin cancer), diabetes (type I diabetes, type II diabetes, and malnutrition-related diabetes), heart failure, myocardial infarction (MI), stroke, chronic obstructive pulmonary disease (COPD), dementia, or death. Our findings demonstrate the validity of HPS, making it a valuable tool for assessing healthspan and as a potential surrogate marker in geroscience-guided studies.

## Setup
Users are required to download and install R but no R package is needed to calculate the healthspan proteomic score (HPS).

## Input file
The input file, as shown in "hps_example_data.csv", should have the first column designated as the ID column, with any arbitrary column name. This should be followed by columns containing age and the required proteins. The input file may include additional proteins beyond those needed, and the protein column names will be converted to lowercase.

## Example
The R code below shows you how to load the "HPS" function in "HPS.R" to calculate healthspan proteomic scores for five subjects with input data in "hps_example_data.csv".
```
source("HPS.R")
hps_input=read.csv("hps_example_data.csv")
HPS(hps_input)
```
