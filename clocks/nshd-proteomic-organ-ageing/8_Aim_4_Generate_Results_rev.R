# ============================================================
# 9_Aim_4_Generate_Results.R
# Aim 4 analysis: Plasma proteins connected to exposures & longevity
# Author: James Groves
# Date: 2025-08-30
# ============================================================

#### SET-UP ####

# Packages

library(tidyverse)
library(readxl)
library(broom)
library(haven)
library(glmnet)
library(survival)
library(caret)
library(mice)
library(openxlsx)
library(mitml)
library(miceadds)

# Directory

inp <- file.path(getwd(), "9. Aim 4 - Specific proteins connected to mortality & modifiable risk")
out <- file.path(getwd(), "9. Aim 4 - Specific proteins connected to mortality & modifiable risk")

#### LOAD & PREPARE DATA ####

# Complete data

load(file.path(inp, "dataset_inc.RData"))

# Imputed data

load(file.path(inp,"imp_data.RData"))

inp <- file.path(getwd(), "9. Aim 4 - Specific proteins connected to mortality & modifiable risk")

# Ages & mortality

organs <- c("Conventional", "Brain", 
            "Heart", "Lung",
            "Liver", "Kidney", 
            "Immune", "Artery")

# Add protein level data

prot <- read.csv(file.path(inp,"prot_final.csv"))

prot <- prot %>% rename(id=ID)

prot_log = prot %>% mutate(across(-1, ~log10(.)))

prot_norm = prot_log %>% mutate(across(-1, ~scale(.)[,1]))

imp_list <- complete(imputed_data, action="all")

imp_prot <- lapply(imp_list, function(df) {
  merge(df, prot_norm, by="id")
})

imp_p <- as.mitml.list(imp_prot)

dataset_p <- merge(dataset, prot_norm, by="id")

# Add protein metadata

prot_metadata <- read_xlsx(file.path(inp, "3.6 SL00000906_SomaScan_11K_v5.0_Plasma_Serum_Annotated_Menu.xlsx"))

colnames(prot_metadata) <- as.character(prot_metadata[4,])

prot_metadata <- prot_metadata[-(1:4),]

prot_metadata$SeqId <- paste0("X", gsub("-",".",prot_metadata$SeqId))

prot_metadata <- prot_metadata %>% 
  subset(select=c("SeqId", "SomaId", "Target Full Name", 
                  "UniProt ID", "Entrez Gene Name", "Organism",
                  "Type"))

# Identify human proteins

prot_metadata_h = prot_metadata %>% 
  filter(
  Type=="Protein" & Organism=="Human"
  )

h_seqids = prot_metadata_h$SeqId

cols = c("id", h_seqids)

long_mod = prot_norm %>% subset(select=c(cols))

base_data <- dataset_p %>% subset(
  select=c(
    cols, "death", "death_yearssincesample"
  ))

mort <- base_data %>% subset(
  select=c(
    "death", "death_yearssincesample"
  ))

long_mod <- base_data %>% subset(
  select=c(cols))

long_mod <- long_mod[ , -1]

#### PROTEIN ASSOCIATIONS ####

# Mortality (~ 6 min)

proteins <- h_seqids

results <- list()

for (i in seq_along(proteins)) {
  
  protein <- proteins[i]
  
  cat(i, ":", protein,"\n")
  
  formula1 <- as.formula(
  paste("Surv(death_yearssincesample, death) ~ ",
  protein, " + Sex_F + Age60"))
  
  model <- coxph(formula1, data=dataset_p)
  
  tidy_model <- tidy(model)
  
  results[[protein]] <- tidy_model
  
}

finaldf <- do.call(rbind, results)

finaldf <- finaldf %>% filter(!(term=="Sex_F"))
finaldf <- finaldf %>% filter(!(term=="Age60"))

finaldf$padj <- p.adjust(finaldf$p.value, method="BH")

finaldf$sig <- ifelse(finaldf$padj<0.05,1,0)

finaldf <- finaldf %>% rename(SeqId=term)

results_mort <- merge(finaldf, prot_metadata, by="SeqId")

# PFS (~ 80 minutes to run)

results <- list()

for (i in seq_along(proteins)) {
  
  protein <- proteins[i]
  
  cat(i, ":", protein,"\n")
  
  formula <- as.formula(paste0(protein, " ~ protectivefactors_new + Sex_F"))

  fit <- lapply(imp_p, function(d) lm(formula, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  results[[protein]] <- summary(pooled)
  
}

pooled_df <- bind_rows(
lapply(results, function(df) rownames_to_column(df, "term")), .id="SeqId")

pooled_df <- pooled_df %>% filter(term=="protectivefactors_new")

pooled_df$padj <- p.adjust(pooled_df$p, method="BH")

pooled_df$sig <- ifelse(pooled_df$padj<0.05,1,0)

results_pfs <- merge(pooled_df, prot_metadata, by="SeqId")

# Overlap

mort_sig <- results_mort %>% filter(sig==T)
mort_seqids <- mort_sig$SeqId

pfs_sig <- results_pfs %>% filter(sig==T)
pfs_seqids <- pfs_sig$SeqId

commonseqids <- intersect(mort_seqids, pfs_seqids)

common <- prot_metadata[prot_metadata$SeqId %in% commonseqids, ]

#### ELASTIC NET MODEL ####

# (~ 6.5 minutes to run)

y = Surv(mort$death_yearssincesample, mort$death)
x = as.matrix(long_mod)

set.seed(123)
fit_cindex_en = cv.glmnet(x,y,family="cox", alpha=0.5, type.measure="C")
max(fit_cindex_en$cvm)
coef_res = coef(fit_cindex_en, s="lambda.min")

coef_df = data.frame(SeqId=rownames(coef_res),coefficient=as.numeric(coef_res))
coef_df = coef_df[-1,]
coef_df$abs_coef = abs(coef_df$coefficient)
coef_df_sorted = coef_df[order(coef_df$abs_coef,decreasing=TRUE),]
head(coef_df_sorted)

coef_df_nonzero = coef_df_sorted[coef_df_sorted$coefficient!=0,]

model_proteins <- coef_df_nonzero$SeqId

model_proteins_info <- merge(coef_df_nonzero, prot_metadata, by="SeqId",all.x=TRUE)

model_proteins_info <- model_proteins_info %>% subset(select=c(
  `Entrez Gene Name`, `Target Full Name`, SeqId, SomaId, 
  `UniProt ID`, coefficient, abs_coef
))
  
# PFS associations

results <- list()

for (model_protein in model_proteins){
  
  formula <- as.formula(paste0(model_protein, " ~ protectivefactors_new + Sex_F + Age60"))

  fit <- lapply(imp_p, function(d) lm(formula, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  results[[model_protein]] <- summary(pooled)
  
}

pooled_df <- bind_rows(
lapply(results, function(df) rownames_to_column(df, "term")), .id="SeqId")

pooled_df <- pooled_df %>% filter(term=="protectivefactors_new")

pooled_df$padj <- p.adjust(pooled_df$p, method="BH")
pooled_df$sig <- ifelse(pooled_df$padj<0.05,1,0)

pooled_df <- 
  pooled_df %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

results_pfs_mod <- merge(pooled_df, prot_metadata, by="SeqId")

results_pfs_mod <- merge(results_pfs, coef_df_nonzero, by="SeqId",all.x=TRUE)

results_pfs_mod <- results_pfs_mod %>% subset(
select=c(SeqId, estimate, se, ci_lower, ci_upper, p, padj, sig))

model_proteins_info <- merge(model_proteins_info, results_pfs_mod, by="SeqId")

model_proteins_info <- model_proteins_info %>% arrange(desc(abs_coef))

#### MED9 ####

# Filter

med9info <- prot_metadata %>% filter(`Entrez Gene Name`=="MED9")

med9 <- med9info$SeqId

# Protective factors

formula <- as.formula(
  "`X31944.1` ~ normal_birthweight + 
high_ses + obtained_gcse + normal_adolescent_bmi + 
non_smoker + mod_alcohol +
active + no_adversity + Sex_F + Age60")

fit <- lapply(imp_p, function(d) lm(formula, data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

med9_rf <- summary(pooled)

med9_rf <- 
  med9_rf %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

med9_rf <- 
  med9_rf %>%
  subset(select=-c(missInfo))

med9_rf <- rownames_to_column(med9_rf, var="variable")
    
# Survival

imputed_data_prot_med9 <- lapply(imp_p, function(df) {
  
  cutoff <- quantile(df[["X31944.1"]], probs=0.1)
  
  df[["med9low"]] = as.integer(df[["X31944.1"]]<=cutoff,1,0)
  
  df
  
})

  formula1 <- as.formula(
  paste(
  "Surv(death_yearssincesample, death) ~ med9low + packyrs + Sex_F + Age60"))
  
  fit <- lapply(imputed_data_prot_med9, function(d) coxph(formula1, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  med9_surv <- summary(pooled)

med9_surv$ci_lower = exp(med9_surv$`(lower`)
med9_surv$ci_upper = exp(med9_surv$`upper)`)
med9_surv$hr = exp(med9_surv$results)

med9_surv <- med9_surv %>% subset(select=c(hr, se, ci_lower, ci_upper, p))

med9_surv <- rownames_to_column(med9_surv, var="variable")

formula2 <- as.formula(
  paste(
  "Surv(death_yearssincesample, death) ~ 
  as.factor(fifteenpackyrs) + Sex_F + Age60"))

fit <- lapply(imputed_data_prot_med9, function(d) coxph(formula2, data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

smok_surv <- summary(pooled)

smok_surv$ci_lower = exp(smok_surv$`(lower`)
smok_surv$ci_upper = exp(smok_surv$`upper)`)
smok_surv$hr = exp(smok_surv$results)

smok_surv <- smok_surv %>% subset(select=c(hr, se, ci_lower, ci_upper, p))

smok_surv <- rownames_to_column(smok_surv, var="variable")

# Conventional ageing

formula <- as.formula(
  "`X31944.1` ~ scale(ConventionalAge60) + Sex_F + Age60")

fit <- lapply(imp_p, function(d) lm(formula, data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

med9_age <- summary(pooled)

med9_age <- 
  med9_age %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

med9_age <- 
  med9_age %>%
  subset(select=-c(missInfo))

med9_age <- rownames_to_column(med9_age, var="variable")

# AVOS

formula <- as.formula(
  "`X31944.1` ~ scale(avos) + Sex_F + Age60")

fit <- lapply(imp_p, function(d) lm(formula, data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

med9_avos <- summary(pooled)

med9_avos <- 
  med9_avos %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

med9_avos <- 
  med9_avos %>%
  subset(select=-c(missInfo))

med9_avos <- rownames_to_column(med9_avos, var="variable")

# Cognitive & motor frailty

formula <- as.formula(
  "`X31944.1` ~ scale(acetotfin15x) + Sex_F + Age60")

fit <- lapply(imp_p, function(d) lm(formula, data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

med9_cog <- summary(pooled)

med9_cog <- 
  med9_cog %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

med9_cog <- 
  med9_cog %>%
  subset(select=-c(missInfo))

med9_cog <- rownames_to_column(med9_cog, var="variable")

formula <- as.formula(
  "`X31944.1` ~ scale(chrst09) + Sex_F + Age60")

fit <- lapply(imp_p, function(d) lm(formula, data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

med9_mot <- summary(pooled)

med9_mot <- 
  med9_mot %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

med9_mot <- 
  med9_mot %>%
  subset(select=-c(missInfo))

med9_mot <- rownames_to_column(med9_mot, var="variable")

#### SELENOP ####

# Filter

selenop <- prot_metadata %>% filter(`Entrez Gene Name`=="SELENOP")

selenop <- selenop$SeqId

# Protective factors

formula <- as.formula(
  "`X33030.6` ~ normal_birthweight + 
high_ses + obtained_gcse + normal_adolescent_bmi + 
non_smoker + mod_alcohol +
active + no_adversity + Sex_F + Age60")

fit <- lapply(imp_p, function(d) lm(formula, data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

sel_rf <- summary(pooled)

sel_rf <- 
  sel_rf %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

sel_rf <- 
  sel_rf %>%
  subset(select=-c(missInfo))

sel_rf <- rownames_to_column(sel_rf, var="variable")

# Survival

imputed_data_prot_selenop <- lapply(imp_p, function(df) {
  
  cutoff <- quantile(df[["X33030.6"]], probs=0.1)
  
  df[["selenoplow"]] = as.integer(df[["X33030.6"]]<=cutoff,1,0)
  
  df
  
})

formula1 <- as.formula(
  paste(
    "Surv(death_yearssincesample, death) ~ selenoplow + packyrs + Sex_F + Age60"))

fit <- lapply(imputed_data_prot_selenop, function(d) coxph(formula1, data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

sel_surv <- summary(pooled)

sel_surv$ci_lower = exp(sel_surv$`(lower`)
sel_surv$ci_upper = exp(sel_surv$`upper)`)
sel_surv$hr = exp(sel_surv$results)

sel_surv <- sel_surv %>% subset(select=c(hr, se, ci_lower, ci_upper, p))

sel_surv <- rownames_to_column(sel_surv, var="variable")

# Conventional ageing

formula <- as.formula(
  "`X31944.1` ~ scale(ConventionalAge60) + Sex_F + Age60")

fit <- lapply(imp_p, function(d) lm(formula, data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

sel_age <- summary(pooled)

sel_age <- 
  sel_age %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

sel_age <- 
  sel_age %>%
  subset(select=-c(missInfo))

sel_age <- rownames_to_column(sel_age, var="variable")

# AVOS

formula <- as.formula(
  "`X33030.6` ~ scale(avos) + Sex_F + Age60")

fit <- lapply(imp_p, function(d) lm(formula, data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

sel_avos <- summary(pooled)

sel_avos <- 
  sel_avos %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

sel_avos <- 
  sel_avos %>%
  subset(select=-c(missInfo))

sel_avos <- rownames_to_column(sel_avos, var="variable")

# Cognitive & motor frailty

formula <- as.formula(
  "`X33030.6` ~ scale(acetotfin15x) + Sex_F + Age60")

fit <- lapply(imp_p, function(d) lm(formula, data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

sel_cog <- summary(pooled)

sel_cog <- 
  sel_cog %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

sel_cog <- 
  sel_cog %>%
  subset(select=-c(missInfo))

sel_cog <- rownames_to_column(sel_cog, var="variable")

formula <- as.formula(
  "`X33030.6` ~ scale(chrst09) + Sex_F + Age60")

fit <- lapply(imp_p, function(d) lm(formula, data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

sel_mot <- summary(pooled)

sel_mot <- 
  sel_mot %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

sel_mot <- 
  sel_mot %>%
  subset(select=-c(missInfo))

sel_mot <- rownames_to_column(sel_mot, var="variable")

#### OUTPUT FILES ####

# Aim 4 Supplementary Tables

res <- createWorkbook()

# ST40: Protein-level associations & PFC
addWorksheet(res, "ST40.Proteins - PFC")
writeData(res, "ST40.Proteins - PFC", results_pfs)

# ST41: Protein-level associations & mortality
addWorksheet(res, "ST41.Proteins - mortality")
writeData(res, "ST41.Proteins - mortality", results_mort)

# ST42: Predictive model coefficients
addWorksheet(res, "ST42.Algorithm coefficients")
writeData(res, "ST42.Algorithm coefficients", model_proteins_info)

# ST44: MED9 associations
addWorksheet(res, "ST43.MED9 associations")
writeData(res, "ST43.MED9 associations", med9_rf, startRow = 1)
writeData(res, "ST43.MED9 associations", med9_surv, startRow = 13)
writeData(res, "ST43.MED9 associations", smok_surv, startRow = 18)
writeData(res, "ST43.MED9 associations", med9_age, startRow = 25)
writeData(res, "ST43.MED9 associations", med9_avos, startRow = 30)
writeData(res, "ST43.MED9 associations", med9_cog, startRow = 35)
writeData(res, "ST43.MED9 associations", med9_mot, startRow = 40)

# ST45: SELENOP associations
addWorksheet(res, "ST44.SELENOP associations")
writeData(res, "ST44.SELENOP associations", sel_rf, startRow = 1)
writeData(res, "ST44.SELENOP associations", sel_surv, startRow = 13)
writeData(res, "ST44.SELENOP associations", smok_surv, startRow = 18)
writeData(res, "ST44.SELENOP associations", sel_age, startRow = 25)
writeData(res, "ST44.SELENOP associations", sel_avos, startRow = 30)
writeData(res, "ST44.SELENOP associations", sel_cog, startRow = 35)
writeData(res, "ST44.SELENOP associations", sel_mot, startRow = 40)

# Save
saveWorkbook(res, file.path(out,"ST_Aim_4.xlsx"), overwrite=TRUE)

# Combine all
files <- c("S:/LHA_JG0923/Revision/6. Aim 1 - Organ age distributions/Aim_1_ST.xlsx",
"S:/LHA_JG0923/Revision/Aim_2_ST.xlsx",
"S:/LHA_JG0923/Revision/8. Aim 3 - Modifiable risk factor associations/Aim_3_ST.xlsx",
"S:/LHA_JG0923/Revision/9. Aim 4 - Specific proteins connected to mortality & modifiable risk/ST_Aim_4.xlsx")

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
"S:/LHA_JG0923/Revision/Supplementary_Tables.xlsx", overwrite = TRUE)

# Source code files

sc <- createWorkbook()

# Fig 6c
addWorksheet(sc, "Fig 6c")
writeData(sc, "Fig 6c", results_pfs)

# Fig 6d
addWorksheet(sc, "Fig 6d")
writeData(sc, "Fig 6d", results_mort)

# Fig 6e
addWorksheet(sc, "Fig 6e")
writeData(sc, "Fig 6e", med9_rf, startRow=1)
writeData(sc, "Fig 6e", med9_surv, startRow=13)
writeData(sc, "Fig 6e", smok_surv, startRow=18)
writeData(sc, "Fig 6e", med9_age, startRow=30)
writeData(sc, "Fig 6e", med9_avos, startRow=40)

# Fig 6f
addWorksheet(sc, "Fig 6f")
writeData(sc, "Fig 6f", sel_rf, startRow=1)
writeData(sc, "Fig 6f", sel_surv, startRow=13)
writeData(sc, "Fig 6f", smok_surv, startRow=18)
writeData(sc, "Fig 6f", sel_age, startRow=30)
writeData(sc, "Fig 6f", sel_avos, startRow=40)

# ED Fig 9b
addWorksheet(sc, "ED Fig 9b")
writeData(sc, "ED Fig 9b", model_proteins_info)

# Save
saveWorkbook(
sc, 
file.path(out1,"SC_Aim_4.xlsx"), 
overwrite=TRUE)

# Combine all
files <- c("S:/LHA_JG0923/Proteomic Ageing Project/Final Scripts & Data/SC_Aim_1.xlsx",
"S:/LHA_JG0923/Proteomic Ageing Project/Final Scripts & Data/SC_Aim_2.xlsx",
"S:/LHA_JG0923/Proteomic Ageing Project/Final Scripts & Data/SC_Aim_3.xlsx",
"S:/LHA_JG0923/Proteomic Ageing Project/Final Scripts & Data/SC_Aim_4.xlsx")

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
"S:/LHA_JG0923/Proteomic Ageing Project/Final Scripts & Data/Source_Data.xlsx", overwrite = TRUE)

