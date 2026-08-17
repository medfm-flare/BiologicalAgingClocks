# ============================================================
# 11_UKB_analysis.R
# UKB: Analyse data
# Author: James Groves
# Date: 2026-03-03
# ============================================================

#### SET-UP ####

# Packages

library(tidyverse)
library(broom)
library(openxlsx)

# Directory

setwd("S:/LHA_JG0923/Revision/")

inp <- file.path(getwd(), "11. UKB_analysis")
out <- file.path(getwd(), "11. UKB_analysis")

#### LOAD ####

load(file.path(inp, "dataset.RData"))

#### ANALYSE: BRAIN AGE & ALCOHOL ####

# Overall model

model <- lm(as.numeric(BrainAge60) ~ as.factor(alc_cat) + as.numeric(age) + sex, data = dataset)

brain_alc <- tidy(model, conf.int = T)

#  Alcohol & selection

dataset$obtained_gcse <- ifelse(dataset$educat == 1, 0, 1)

edu_tabs <- as.data.frame(prop.table(table(as.factor(dataset$alc_cat), dataset$obtained_gcse), 1))

alc_edu <- edu_tabs %>%
  rename(
    alcohol_intake = Var1,
    obtained_gcse = Var2
  ) %>%
  arrange(alcohol_intake, obtained_gcse)

#  Reduced alcohol & brain age

model <- lm(as.numeric(BrainAge60) ~ red + as.numeric(age) + sex, data = dataset, subset = !(is.na(health)))

red_alc <- tidy(model, conf.int = T)

red_alc <- red_alc[2, ]

model <- lm(as.numeric(BrainAge60) ~ red + as.numeric(age) + sex, data = dataset, subset = (health == 3 | health == 4))

red_alc_hea <- tidy(model, conf.int = T)

red_alc_hea <- red_alc_hea[2, ]

red_alc_hea$term <- "health"

model <- lm(as.numeric(BrainAge60) ~ red + as.numeric(age) + sex, data = dataset, subset = (health == 1 | health == 2))

red_alc_dis <- tidy(model, conf.int = T)

red_alc_dis <- red_alc_dis[2, ]

red_alc_dis$term <- "disease"

red_alc <- rbind(red_alc, red_alc_hea, red_alc_dis)

# Proteins

olink <- read.csv("S:/LHA_Stanford/Organ_ageing_scripts/Disease, Prot. Subset & All Alch. Participant/OLINK_subset_brain_age_proteins copy.csv")

proteins <- names(olink)[-(1:3)]

results <- list()

for (protein in proteins) {
  
  formula <- as.formula(paste0(protein, "~ as.numeric(alc_cat) + as.numeric(age) + sex"))
  
  fit <- lm(formula, data = dataset)
  
  results[[protein]] <- tidy(fit, conf.int = T)
  
}

proteins_df <- bind_rows(
  lapply(results, function(df) rownames_to_column(df, "row")), .id="Prot")

proteins_df <- proteins_df %>% filter(term=="as.numeric(alc_cat)")

proteins_df$padj_ukb <- p.adjust(proteins_df$p.value, method = "BH")

proteins_df$sig_ukb <- ifelse(proteins_df$padj_ukb < 0.05, 1, 0)

proteins_df$`Entrez Gene Name` <- toupper(proteins_df$Prot)

#### ANALYSE: CONVENTIONAL AGE & EDUCATION ####

# Overall model

model <- lm(as.numeric(ConventionalAge60) ~ as.factor(educat) + as.numeric(age) + sex, data = dataset)

edu_conv <- tidy(model, conf.int = T)

# Sex interaction model

model <- lm(as.numeric(ConventionalAge60) ~ as.factor(educat)*sex + as.numeric(age), data = dataset)

edu_int <- tidy(model, conf.int = T)

# Sex-education stratification

summary(lm(as.numeric(ConventionalAge60) ~ as.factor(educat)*sex + as.numeric(age), data = dataset))

edu_sex <- as.data.frame(prop.table(table(dataset$sex, dataset$educat), 1))

edu_sex <- edu_sex %>%
  rename(
    alcohol_intake = Var1,
    obtained_gcse = Var2
  ) %>%
  arrange(alcohol_intake, obtained_gcse)


#### OUTPUT FILES ####

# UKB Supplementary Tables

res <- createWorkbook()

# Brain age - alcohol
addWorksheet(res, "Brain age - alcohol")
writeData(res, "Brain age - alcohol", brain_alc)

# Alcohol & selection
addWorksheet(res, "Alcohol & selection")
writeData(res, "Alcohol & selection", alc_edu)

# Reduced alcohol
addWorksheet(res, "Reduced alcohol")
writeData(res, "Reduced alcohol", red_alc)

# Brain proteins
addWorksheet(res, "Brain proteins")
writeData(res, "Brain proteins", proteins_df)

# Conventional & education
addWorksheet(res, "Conventional & education")
writeData(res, "Conventional & education", edu_conv)
writeData(res, "Conventional & education", edu_int, startRow = 10)

# Education & sex
addWorksheet(res, "Education & sex")
writeData(res, "Education & sex", edu_sex)

# Save combined workbook
saveWorkbook(
  res, 
  "S:/LHA_JG0923/Revision/UKB_results.xlsx", overwrite = TRUE)

# Combine nshd & ukb
files <- c("S:/LHA_JG0923/Revision/UKB_results.xlsx",
           "S:/LHA_JG0923/Revision/Supplementary_Tables.xlsx")

comb <- createWorkbook()

for (f in files) {
  sheets <- getSheetNames(f)
  for (sheet in sheets) {
    data <- read.xlsx(f, sheet = sheet)
    addWorksheet(comb, paste0(sheet))
    writeData(comb, paste0(sheet), data)
  }
}

# Save combined workbook
saveWorkbook(
  comb, 
  "S:/LHA_JG0923/Revision/Final_export/final_results.xlsx", overwrite = TRUE)


