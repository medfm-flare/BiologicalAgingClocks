# ============================================================
# 7_Aim_2_Generate_Results.R
# Purpose: Aim 2 analysis - Proteomic ageing and mortality or chronic disease risk
# Input: Cleaned merged dataset
# Author: James Groves
# Date: 2026-03-28
# ============================================================

#### SET-UP ####

# Load packages

library(tidyverse)
library(readxl)
library(broom)
library(haven)
library(survival)
library(openxlsx)
library(mice)
library(QRISK3)
library(miceadds)

#### LOAD DATA ####

# Set wd

setwd("S:/LHA_JG0923/Revision/7. Aim 2 - Mortality prediction")

# Load data 

load("imp_data.RData")

load("dataset_inc.RData")

organs <- c(
"Conventional", "Brain", 
"Heart", "Lung", 
"Liver", "Kidney", 
"Immune", "Artery")

# QRISK score

imp_list <- complete(imputed_data, action="all")

imp_list_qrisk <- lapply(imp_list, function(d) {

qrisk_dat <- d %>%
  rename(
    patid = id
  ) %>% 
  filter(
    IHD_prev == 0
  )

qrisk_dat$qrisk_smok <- ifelse(qrisk_dat$packyrs == 0, 1,
    ifelse(qrisk_dat$packyr5363 == 0 & qrisk_dat$packyrs > 0, 2,
    ifelse(qrisk_dat$packyrs > 0 & qrisk_dat$packyr5363 <= 5, 3,
    ifelse(qrisk_dat$packyr5363 > 5 & qrisk_dat$packyr5363 <= 10, 4, 
    ifelse(qrisk_dat$packyr5363 > 10, 5, NA))))
)

qrisk_out <- QRISK3::QRISK3_2017(
  data = qrisk_dat,
  patid = "patid",
  gender = "Sex_F",
  age = "Age60",
  atrial_fibrillation = "AF_prev",
  atypical_antipsy = "bnf421",
  regular_steroid_tablets = "bnf634",
  erectile_disfunction = "ED_prev",
  migraine = "Migraine_prev", 
  rheumatoid_arthritis = "RA_prev",
  chronic_kidney_disease = "ckd345",
  severe_mental_illness = "Severe_mental_prev",
  systemic_lupus_erythematosis = "SLE_prev",
  blood_pressure_treatment = "b2_5_09",
  diabetes2 = "T2DM_prev",
  weight = "wtn09",
  height = "htn09_v2",
  cholesterol_HDL_ratio = "chol_hdl",
  std_systolic_blood_pressure = "sbp_sd",
  systolic_blood_pressure = "sbp209",
  smoke = "qrisk_smok",
  townsend = "cars01_z",
  diabetes1 = "T1DM_prev",
  ethiniciy = "ethrisk",
  heart_attack_relative = "fh_cvd"
)

qrisk_out <- qrisk_out %>% rename(id = patid)

dat_q <- left_join(d, qrisk_out, by = "id")

dat_q

}
)

#### ORGANS & MORTALITY ####

# Cox Proportional Hazards models: organ ages

for (organ in organs) {
  
  agevariable <- paste0(organ, "Age60high")
  
  formula1 <- as.formula(paste(
  "Surv(death_yearssincesample, death) ~ ", 
  agevariable, " + Sex_F + Age60"))
  model <- coxph(formula1, data=dataset)
  
  tidy_model <- tidy(model)
  conf_intervals <- confint(model)
  tidy_model$lci <- exp(conf_intervals[,1])
  tidy_model$uci <- exp(conf_intervals[,2])
  tidy_model$hazardratio <- exp(tidy_model$estimate)
  
  model_name <- paste0("mort_ext_", organ)
  ageoutput <- tidy_model[1,]
  assign(model_name, ageoutput)
  
}

mort_ext_results <- bind_rows(
  "Conventional" = mort_ext_Conventional,
  "Brain" = mort_ext_Brain,
  "Heart" = mort_ext_Heart,
  "Lung" = mort_ext_Lung,
  "Liver" = mort_ext_Liver,
  "Kidney" = mort_ext_Kidney,
  "Immune" = mort_ext_Immune,
  "Artery" = mort_ext_Artery,
  .id="Organ")

mort_ext_results <- mort_ext_results %>% 
  subset(select=-c(term))

#### MULTI-ORGAN AGEING & MORTALITY ####

# Cox Proportional Hazards models: multi-organ extreme ageing

cox_model <- coxph(
Surv(death_yearssincesample, death) ~ as.factor(
multiorgan60high4max) + Sex_F + Age60, data=dataset)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(1:4)

mort_multiorgan <- data.frame(tidy_model)

mort_multiorgan <-  mort_multiorgan %>%
  mutate(term=ifelse(term=="as.factor(multiorgan60high4max)1",
"Extreme ageing in 1 organ",term))

mort_multiorgan <-  mort_multiorgan %>%
  mutate(term=ifelse(term=="as.factor(multiorgan60high4max)2",
"Extreme ageing in 2 organs",term))

mort_multiorgan <-  mort_multiorgan %>%
  mutate(term=ifelse(term=="as.factor(multiorgan60high4max)3",
"Extreme ageing in 3 organs",term))

mort_multiorgan <-  mort_multiorgan %>%
  mutate(term=ifelse(term=="as.factor(multiorgan60high4max)4",
"Extreme ageing in 4 or more organs",term))

multiorgan_death_counts <-
  dataset %>%
  group_by(multiorgan60high4max, death) %>% 
  summarise(n=n(), .groups="drop") %>%
  pivot_wider(names_from = death, values_from=n, 
  names_prefix = "death")

multiorgan_death_counts <-  multiorgan_death_counts %>%
rename("Number of organs with extreme ageing"="multiorgan60high4max",
"Survived"="death0", "Died"="death1")

#### MORTALITY SENSITIVITY ANALYSES ####

# Frailty: Organ extreme ageing

for (organ in organs) {
  
  agevariable <- paste0(organ, "Age60high")
  
  formula1 <- as.formula(paste(
    "Surv(death_yearssincesample, death) ~ ", 
    agevariable, " + Sex_F + Age60 + fried"))
  model <- coxph(formula1, data=dataset)
  
  tidy_model <- tidy(model)
  conf_intervals <- confint(model)
  tidy_model$lci <- exp(conf_intervals[,1])
  tidy_model$uci <- exp(conf_intervals[,2])
  tidy_model$hazardratio <- exp(tidy_model$estimate)
  
  model_name <- paste0("mort_ext_", organ)
  ageoutput <- tidy_model[1,]
  assign(model_name, ageoutput)
  
}

org_frail <- bind_rows(
  "Conventional" = mort_ext_Conventional,
  "Brain" = mort_ext_Brain,
  "Heart" = mort_ext_Heart,
  "Lung" = mort_ext_Lung,
  "Liver" = mort_ext_Liver,
  "Kidney" = mort_ext_Kidney,
  "Immune" = mort_ext_Immune,
  "Artery" = mort_ext_Artery,
  .id="Organ")

org_frail <- org_frail %>% 
  subset(select=-c(term))

# Frailty: Multi-organ extreme ageing

cox_model <- coxph(
  Surv(death_yearssincesample, death) ~ as.factor(
    multiorgan60high4max) + Sex_F + Age60 + fried, data=dataset)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(1:4)

mult_frail <- data.frame(tidy_model)

mult_frail <-  mult_frail %>%
  mutate(term=ifelse(term=="as.factor(multiorgan60high4max)1",
                     "Extreme ageing in 1 organ",term))

mult_frail <-  mult_frail %>%
  mutate(term=ifelse(term=="as.factor(multiorgan60high4max)2",
                     "Extreme ageing in 2 organs",term))

mult_frail <-  mult_frail %>%
  mutate(term=ifelse(term=="as.factor(multiorgan60high4max)3",
                     "Extreme ageing in 3 organs",term))

mult_frail <-  mult_frail %>%
  mutate(term=ifelse(term=="as.factor(multiorgan60high4max)4",
                     "Extreme ageing in 4 or more organs",term))

# Major disease: Organ extreme ageing

for (organ in organs) {
  
  agevariable <- paste0(organ, "Age60high")
  
  formula1 <- as.formula(paste(
    "Surv(death_yearssincesample, death) ~ ", 
    agevariable, " + Sex_F + Age60"))
  model <- coxph(formula1, data = dataset, subset = disease == 0)
  
  tidy_model <- tidy(model)
  conf_intervals <- confint(model)
  tidy_model$lci <- exp(conf_intervals[,1])
  tidy_model$uci <- exp(conf_intervals[,2])
  tidy_model$hazardratio <- exp(tidy_model$estimate)
  
  model_name <- paste0("mort_ext_", organ)
  ageoutput <- tidy_model[1,]
  assign(model_name, ageoutput)
  
}

org_morbid <- bind_rows(
  "Conventional" = mort_ext_Conventional,
  "Brain" = mort_ext_Brain,
  "Heart" = mort_ext_Heart,
  "Lung" = mort_ext_Lung,
  "Liver" = mort_ext_Liver,
  "Kidney" = mort_ext_Kidney,
  "Immune" = mort_ext_Immune,
  "Artery" = mort_ext_Artery,
  .id="Organ")

org_morbid <- org_morbid %>% 
  subset(select=-c(term))

# Major disease: Multi-organ extreme ageing

cox_model <- coxph(
  Surv(death_yearssincesample, death) ~ as.factor(
    multiorgan60high4max) + Sex_F + Age60, data = dataset, subset = disease == 0)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(1:4)

mult_morbid <- data.frame(tidy_model)

mult_morbid <-  mult_morbid %>%
  mutate(term=ifelse(term=="as.factor(multiorgan60high4max)1",
                     "Extreme ageing in 1 organ",term))

mult_morbid <-  mult_morbid %>%
  mutate(term=ifelse(term=="as.factor(multiorgan60high4max)2",
                     "Extreme ageing in 2 organs",term))

mult_morbid <-  mult_morbid %>%
  mutate(term=ifelse(term=="as.factor(multiorgan60high4max)3",
                     "Extreme ageing in 3 organs",term))

mult_morbid <-  mult_morbid %>%
  mutate(term=ifelse(term=="as.factor(multiorgan60high4max)4",
                     "Extreme ageing in 4 or more organs",term))

mult_morbid_death_counts <-
  dataset %>%
  filter(disease == 0) %>%
  group_by(multiorgan60high4max, death) %>% 
  summarise(n = n(), .groups="drop") %>%
  pivot_wider(names_from = death, values_from=n, 
              names_prefix = "death")

mult_morbid_death_counts <-  mult_morbid_death_counts %>%
  rename("Number of organs with extreme ageing"="multiorgan60high4max",
         "Survived"="death0", "Died"="death1")

#### AVOS & MORTALITY ####

# AVOS & mortality

cox_model <-  coxph(
  Surv(death_yearssincesample, death) ~ scale(avos) + Sex_F + Age60, data=dataset
  )

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(1)

avos_mort <- data.frame(tidy_model)

# Sensitivity: Conventional

cox_model <-  coxph(
  Surv(death_yearssincesample, death) ~ scale(avos) + Sex_F + Age60 + ConventionalAge60, data=dataset
)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(c(1,4))

avos_conv <- data.frame(tidy_model)

# Sensitivity: Brain

cox_model <-  coxph(
  Surv(death_yearssincesample, death) ~ scale(avos) + Sex_F + Age60 + BrainAge60, data=dataset
)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(c(1,4))

avos_brain <- data.frame(tidy_model)

# Sensitivity: Heart

cox_model <-  coxph(
  Surv(death_yearssincesample, death) ~ scale(avos) + Sex_F + Age60 + HeartAge60, data=dataset
)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(c(1,4))

avos_heart <- data.frame(tidy_model)

# Sensitivity: Lung

cox_model <-  coxph(
  Surv(death_yearssincesample, death) ~ scale(avos) + Sex_F + Age60 + LungAge60, data=dataset
)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(c(1,4))

avos_lung <- data.frame(tidy_model)

# Sensitivity: Liver

cox_model <-  coxph(
  Surv(death_yearssincesample, death) ~ scale(avos) + Sex_F + Age60 + LiverAge60, data=dataset
)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(c(1,4))

avos_liver <- data.frame(tidy_model)

# Sensitivity: Kidney

cox_model <-  coxph(
  Surv(death_yearssincesample, death) ~ scale(avos) + Sex_F + Age60 + KidneyAge60, data=dataset
)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(c(1,4))

avos_kidney <- data.frame(tidy_model)

# Sensitivity: Immune

cox_model <-  coxph(
  Surv(death_yearssincesample, death) ~ scale(avos) + Sex_F + Age60 + ImmuneAge60, data=dataset
)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(c(1,4))

avos_immune <- data.frame(tidy_model)

# Sensitivity: Artery

cox_model <-  coxph(
  Surv(death_yearssincesample, death) ~ scale(avos) + Sex_F + Age60 + ArteryAge60, data=dataset
)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(c(1,4))

avos_artery <- data.frame(tidy_model)

# Sensitivity: Mean organ age

vars <- paste0(organs, "Age60")

vars <- vars[-1]

dataset$mean_organ_age <- rowMeans(dataset[ , vars])

cox_model <-  coxph(
  Surv(death_yearssincesample, death) ~ scale(avos) + Sex_F + Age60 + mean_organ_age, data=dataset
)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(c(1,4))

avos_mean <- data.frame(tidy_model)

# Sensitivity: Multi-organ extreme ageing

cox_model <-  coxph(
  Surv(death_yearssincesample, death) ~ scale(avos) + Sex_F + Age60 + multiorganageing, data=dataset
)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(c(1,4))

avos_multiorgan <- data.frame(tidy_model)

# Sensitivity: Exclude oldest organ

mat <- as.matrix(dataset[, vars])

max <- max.col(mat, ties.method = "first")

mat[cbind(1:nrow(mat), max)] <- NA

dataset$avos_oldest_rem <- apply(mat[, vars], 1, sd, na.rm = T)

cox_model <-  coxph(
  Surv(death_yearssincesample, death) ~ scale(avos_oldest_rem) + Sex_F + Age60, data=dataset
)

tidy_model <- tidy(cox_model)
conf_intervals <- confint(cox_model)
tidy_model$lci <- exp(conf_intervals[,1])
tidy_model$uci <- exp(conf_intervals[,2])
tidy_model$hazardratio <- exp(tidy_model$estimate)
tidy_model <- tidy_model %>% slice(1)

avos_no_max <- data.frame(tidy_model)

#### ORGAN-SPECIFIC DISEASE ####

# Ext heart ageing & AF: Base model

not_prev <- dataset %>% filter(AF_prev == 0)

fit <- coxph(Surv(AF_time, AF_event) ~ HeartAge60high + Sex_F + Age60, data = not_prev)

arhy_hea <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

arhy_hea$lci <- exp(conf_intervals[,1])
arhy_hea$uci <- exp(conf_intervals[,2])
arhy_hea$hazardratio <- exp(arhy_hea$estimate)

# Ext heart ageing & AF: Conventional Age controlled

fit <- coxph(Surv(AF_time, AF_event) ~ HeartAge60high + ConventionalAge60 + Sex_F + Age60, data = not_prev)

arhy_conv <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

arhy_conv$lci <- exp(conf_intervals[,1])
arhy_conv$uci <- exp(conf_intervals[,2])
arhy_conv$hazardratio <- exp(arhy_conv$estimate)

# Ext heart ageing & AF: 2 year washout

wo_2 <- not_prev 

wo_2$protdate <- wo_2$protdate + 2

wo_2$AF_prev <- ifelse(wo_2$AF_event == 1 & wo_2$AF_time <= wo_2$protdate, 1, wo_2$AF_prev)

not_prev_2y <- wo_2 %>% filter(AF_prev == 0) %>% filter(AF_time > protdate)

fit <- coxph(Surv(protdate, AF_time, AF_event) ~ HeartAge60high + Sex_F + Age60, data = not_prev_2y)

arhy_wo_2 <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

arhy_wo_2$lci <- exp(conf_intervals[,1])
arhy_wo_2$uci <- exp(conf_intervals[,2])
arhy_wo_2$hazardratio <- exp(arhy_wo_2$estimate)

# Ext heart ageing & AF: 5 year washout

wo_5 <- not_prev 

wo_5$protdate <- wo_5$protdate + 5

wo_5$AF_prev <- ifelse(wo_5$AF_event == 1 & wo_5$AF_time <= wo_5$protdate, 1, wo_5$AF_prev)

not_prev_5y <- wo_5 %>% filter(AF_prev == 0) %>% filter(AF_time > protdate)

fit <- coxph(Surv(protdate, AF_time, AF_event) ~ HeartAge60high + Sex_F + Age60, data = not_prev_5y)

arhy_wo_5 <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

arhy_wo_5$lci <- exp(conf_intervals[,1])
arhy_wo_5$uci <- exp(conf_intervals[,2])
arhy_wo_5$hazardratio <- exp(arhy_wo_5$estimate)

# Ext heart ageing & heart failure: Base model

not_prev <- dataset %>% filter(HF_prev == 0)

fit <- coxph(Surv(HF_time, HF_event) ~ HeartAge60high + Sex_F + Age60, data = not_prev)

hf_hea <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

hf_hea$lci <- exp(conf_intervals[,1])
hf_hea$uci <- exp(conf_intervals[,2])
hf_hea$hazardratio <- exp(hf_hea$estimate)

# Ext heart ageing & heart failure: Conventional age controlled

fit <- coxph(Surv(HF_time, HF_event) ~ HeartAge60high + ConventionalAge60 + Sex_F + Age60, data = not_prev)

hf_conv <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

hf_conv$lci <- exp(conf_intervals[,1])
hf_conv$uci <- exp(conf_intervals[,2])
hf_conv$hazardratio <- exp(hf_conv$estimate)

# Ext heart ageing & heart failure: 2-year washout

wo_2 <- not_prev 

wo_2$protdate <- wo_2$protdate + 2

wo_2$HF_prev <- ifelse(wo_2$HF_event == 1 & wo_2$HF_time <= wo_2$protdate, 1, wo_2$HF_prev)

not_prev_2y <- wo_2 %>% filter(HF_prev == 0) %>% filter(HF_time > protdate)

fit <- coxph(Surv(protdate, HF_time, HF_event) ~ HeartAge60high + Sex_F + Age60, data = not_prev_2y)

hf_wo_2 <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

hf_wo_2$lci <- exp(conf_intervals[,1])
hf_wo_2$uci <- exp(conf_intervals[,2])
hf_wo_2$hazardratio <- exp(hf_wo_2$estimate)

# Ext heart ageing & heart failure: 5-year washout

wo_5 <- not_prev 

wo_5$protdate <- wo_5$protdate + 5

wo_5$HF_prev <- ifelse(wo_5$HF_event == 1 & wo_5$HF_time <= wo_5$protdate, 1, wo_5$HF_prev)

not_prev_5y <- wo_5 %>% filter(HF_prev == 0) %>% filter(HF_time > protdate)

fit <- coxph(Surv(protdate, HF_time, HF_event) ~ HeartAge60high + Sex_F + Age60, data = not_prev_5y)

hf_wo_5 <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

hf_wo_5$lci <- exp(conf_intervals[,1])
hf_wo_5$uci <- exp(conf_intervals[,2])
hf_wo_5$hazardratio <- exp(hf_wo_5$estimate)

# Ext heart ageing & IHD: Base model

not_prev <- dataset %>% filter(IHD_prev == 0)

fit <- coxph(Surv(IHD_time, IHD_event) ~ HeartAge60high + Sex_F + Age60, data = not_prev)

ihd_hea <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

ihd_hea$lci <- exp(conf_intervals[,1])
ihd_hea$uci <- exp(conf_intervals[,2])
ihd_hea$hazardratio <- exp(ihd_hea$estimate)

# Ext heart ageing & IHD: Conventional age controlled

fit <- coxph(Surv(IHD_time, IHD_event) ~ HeartAge60high + ConventionalAge60 + Sex_F + Age60, data = not_prev)

ihd_conv <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

ihd_conv$lci <- exp(conf_intervals[,1])
ihd_conv$uci <- exp(conf_intervals[,2])
ihd_conv$hazardratio <- exp(ihd_conv$estimate)

# Ext heart ageing & IHD: 2-year washout

wo_2 <- not_prev 

wo_2$protdate <- wo_2$protdate + 2

wo_2$IHD_prev <- ifelse(wo_2$IHD_event == 1 & wo_2$IHD_time <= wo_2$protdate, 1, wo_2$IHD_prev)

not_prev_2y <- wo_2 %>% filter(IHD_prev == 0) %>% filter(IHD_time > protdate)

fit <- coxph(Surv(protdate, IHD_time, IHD_event) ~ HeartAge60high + Sex_F + Age60, data = not_prev_2y)

ihd_wo_2 <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

ihd_wo_2$lci <- exp(conf_intervals[,1])
ihd_wo_2$uci <- exp(conf_intervals[,2])
ihd_wo_2$hazardratio <- exp(ihd_wo_2$estimate)

# Ext heart ageing & IHD: 2-year washout

wo_5 <- not_prev 

wo_5$protdate <- wo_5$protdate + 5

wo_5$IHD_prev <- ifelse(wo_5$IHD_event == 1 & wo_5$IHD_time <= wo_5$protdate, 1, wo_5$IHD_prev)

not_prev_5y <- wo_5 %>% filter(IHD_prev == 0) %>% filter(IHD_time > protdate)

fit <- coxph(Surv(protdate, IHD_time, IHD_event) ~ HeartAge60high + Sex_F + Age60, data = not_prev_5y)

ihd_wo_5 <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

ihd_wo_5$lci <- exp(conf_intervals[,1])
ihd_wo_5$uci <- exp(conf_intervals[,2])
ihd_wo_5$hazardratio <- exp(ihd_wo_5$estimate)

# Heart ageing & IHD: QRISK analysis

fit <- lapply(imp_list_qrisk, function(d) coxph(Surv(IHD_time, IHD_event) ~ scale(HeartAge60) + scale(QRISK3_2017), data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

ihd_qrisk <- summary(pooled)

ihd_qrisk <- 
  ihd_qrisk %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  ) %>%
  mutate(
    hr = exp(estimate),
    lci = exp(ci_lower),
    uci = exp(ci_upper)
  )

# Ext lung ageing & COPD: Base model

not_prev <- dataset %>% filter(COPD_prev == 0)

fit <- coxph(Surv(COPD_time, COPD_event) ~ LungAge60high + Sex_F + Age60, data = not_prev)

copd_lung <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

copd_lung$lci <- exp(conf_intervals[,1])
copd_lung$uci <- exp(conf_intervals[,2])
copd_lung$hazardratio <- exp(copd_lung$estimate)

# Ext lung ageing & COPD: Conventional age controlled

fit <- coxph(Surv(COPD_time, COPD_event) ~ LungAge60high + ConventionalAge60 + Sex_F + Age60, data = not_prev)

copd_conv <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

copd_conv$lci <- exp(conf_intervals[,1])
copd_conv$uci <- exp(conf_intervals[,2])
copd_conv$hazardratio <- exp(copd_conv$estimate)

# Ext lung ageing & COPD: 2-year washout

wo_2 <- not_prev 

wo_2$protdate <- wo_2$protdate + 2

wo_2$COPD_prev <- ifelse(wo_2$COPD_event == 1 & wo_2$COPD_time <= wo_2$protdate, 1, wo_2$COPD_prev)

not_prev_2y <- wo_2 %>% filter(COPD_prev == 0) %>% filter(COPD_time > protdate)

fit <- coxph(Surv(protdate, COPD_time, COPD_event) ~ LungAge60high + Sex_F + Age60, data = not_prev_2y)

copd_wo_2 <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

copd_wo_2$lci <- exp(conf_intervals[,1])
copd_wo_2$uci <- exp(conf_intervals[,2])
copd_wo_2$hazardratio <- exp(copd_wo_2$estimate)

# Ext lung ageing & COPD: 5-year washout

wo_5 <- not_prev 

wo_5$protdate <- wo_5$protdate + 5

wo_5$COPD_prev <- ifelse(wo_5$COPD_event == 1 & wo_5$COPD_time <= wo_5$protdate, 1, wo_5$COPD_prev)

not_prev_5y <- wo_5 %>% filter(COPD_prev == 0) %>% filter(COPD_time > protdate)

fit <- coxph(Surv(protdate, COPD_time, COPD_event) ~ LungAge60high + Sex_F + Age60, data = not_prev_5y)

copd_wo_5 <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

copd_wo_5$lci <- exp(conf_intervals[,1])
copd_wo_5$uci <- exp(conf_intervals[,2])
copd_wo_5$hazardratio <- exp(copd_wo_5$estimate)

# Ext lung ageing & COPD: Smoking controlled

fit <- with(imputed_data, coxph(Surv(COPD_time, COPD_event) ~ scale(LungAge60) + scale(packyrs) + Sex_F + Age60, subset = COPD_prev == 0))

pooled <- pool(fit)

copd_smok <- tidy(pooled, conf.int=T)

copd_smok$lci <- exp(copd_smok$conf.low)
copd_smok$uci <- exp(copd_smok$conf.high)
copd_smok$hazardratio <- exp(copd_smok$estimate)

copd_smok <- copd_smok %>% 
  subset(select=-c(
    statistic, df, dfcom, fmi, lambda, riv, ubar, m, b)) 

# Ext kidney ageing & CKD: Base model

not_prev <- dataset %>% filter(CKD_prev == 0)

fit <- coxph(Surv(CKD_time, CKD_event) ~ KidneyAge60high + Sex_F + Age60, data = not_prev)

ckd_kid <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

ckd_kid$lci <- exp(conf_intervals[,1])
ckd_kid$uci <- exp(conf_intervals[,2])
ckd_kid$hazardratio <- exp(ckd_kid$estimate)

# Ext kidney ageing & CKD: Conventional age controlled

fit <- coxph(Surv(CKD_time, CKD_event) ~ KidneyAge60high + ConventionalAge60 + Sex_F + Age60, data = not_prev)

ckd_conv <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

ckd_conv$lci <- exp(conf_intervals[,1])
ckd_conv$uci <- exp(conf_intervals[,2])
ckd_conv$hazardratio <- exp(ckd_conv$estimate)

# Ext kidney ageing & CKD: 2-year washout

wo_2 <- not_prev 

wo_2$protdate <- wo_2$protdate + 2

wo_2$CKD_prev <- ifelse(wo_2$CKD_event == 1 & wo_2$CKD_time <= wo_2$protdate, 1, wo_2$CKD_prev)

not_prev_2y <- wo_2 %>% filter(CKD_prev == 0) %>% filter(CKD_time > protdate)

fit <- coxph(Surv(protdate, CKD_time, CKD_event) ~ KidneyAge60high + Sex_F + Age60, data = not_prev_2y)

ckd_wo_2 <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

ckd_wo_2$lci <- exp(conf_intervals[,1])
ckd_wo_2$uci <- exp(conf_intervals[,2])
ckd_wo_2$hazardratio <- exp(ckd_wo_2$estimate)

# Ext kidney ageing & CKD: 5-year washout

wo_5 <- not_prev 

wo_5$protdate <- wo_5$protdate + 5

wo_5$CKD_prev <- ifelse(wo_5$CKD_event == 1 & wo_5$CKD_time <= wo_5$protdate, 1, wo_5$CKD_prev)

not_prev_5y <- wo_5 %>% filter(CKD_prev == 0) %>% filter(CKD_time > protdate)

fit <- coxph(Surv(protdate, CKD_time, CKD_event) ~ KidneyAge60high + Sex_F + Age60, data = not_prev_5y)

ckd_wo_5 <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

ckd_wo_5$lci <- exp(conf_intervals[,1])
ckd_wo_5$uci <- exp(conf_intervals[,2])
ckd_wo_5$hazardratio <- exp(ckd_wo_5$estimate)

# Ext kidney ageing & CKD: eGFR / HbA1c analysis

fit <- with(imputed_data, coxph(Surv(CKD_time, CKD_event) ~ scale(KidneyAge60) + scale(I(90-egfr09)) + scale(hba1c209) + Sex_F + Age60, subset = CKD_prev == 0))

pooled <- pool(fit)

ckd_egfr <- tidy(pooled, conf.int=T)

ckd_egfr$lci <- exp(ckd_egfr$conf.low)
ckd_egfr$uci <- exp(ckd_egfr$conf.high)
ckd_egfr$hazardratio <- exp(ckd_egfr$estimate)

ckd_egfr <- ckd_egfr %>% 
  subset(select=-c(
    statistic, df, dfcom, fmi, lambda, riv, ubar, m, b)) 

# COVID risk

fit <- coxph(Surv(COVID_time, COVID_event) ~ I(LungAge60high | ImmuneAge60high) + Sex_F + Age60, data = dataset)

covid_org <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

covid_org$lci <- exp(conf_intervals[,1])
covid_org$uci <- exp(conf_intervals[,2])
covid_org$hazardratio <- exp(covid_org$estimate)

fit <- coxph(Surv(COVID_time, COVID_event) ~ ConventionalAge60high + Sex_F + Age60, data = dataset)

covid_conv <- tidy(fit, conf.int=T)

conf_intervals <- confint(fit)

covid_conv$lci <- exp(conf_intervals[,1])
covid_conv$uci <- exp(conf_intervals[,2])
covid_conv$hazardratio <- exp(covid_conv$estimate)

#### OUTPUTS ####

res <- createWorkbook()

# ST5: Extreme organ ageing & mortality 
addWorksheet(res, "ST5.Extreme ageing & mortality")
writeData(res, "ST5.Extreme ageing & mortality", mort_ext_results)

# ST6: Multi-organ extreme ageing & mortality 
addWorksheet(res, "ST6.Multi-organ mortality")
writeData( res, "ST6.Multi-organ mortality", mort_multiorgan)
writeData( res, "ST6.Multi-organ mortality", multiorgan_death_counts, startRow=10)

# ST7: Sensitivity analyses for frailty & major disease 
addWorksheet(res, "ST7.Mortality sensitivity")
writeData(res, "ST7.Mortality sensitivity", org_frail)
writeData(res, "ST7.Mortality sensitivity", org_morbid, startRow = 10)
writeData(res, "ST7.Mortality sensitivity", mult_frail, startRow = 20)
writeData(res, "ST7.Mortality sensitivity", mult_morbid, startRow = 30)
writeData(res, "ST7.Mortality sensitivity", mult_morbid_death_counts, startRow = 40)

# ST10: AVOS & mortality
addWorksheet(res, "ST10.AVOS mortality")
writeData(res, "ST10.AVOS mortality", avos_mort)
writeData(res, "ST10.AVOS mortality", avos_conv, startRow = 10)
writeData(res, "ST10.AVOS mortality", avos_brain, startRow = 20)
writeData(res, "ST10.AVOS mortality", avos_heart, startRow = 30)
writeData(res, "ST10.AVOS mortality", avos_lung, startRow = 40)
writeData(res, "ST10.AVOS mortality", avos_liver, startRow = 50)
writeData(res, "ST10.AVOS mortality", avos_kidney, startRow = 60)
writeData(res, "ST10.AVOS mortality", avos_immune, startRow = 70)
writeData(res, "ST10.AVOS mortality", avos_artery, startRow = 80)
writeData(res, "ST10.AVOS mortality", avos_mean, startRow = 90)
writeData(res, "ST10.AVOS mortality", avos_multiorgan, startRow = 100)
writeData(res, "ST10.AVOS mortality", avos_no_max, startRow = 110)

# ST11: Heart & heart disease
addWorksheet(res, "ST11.Heart disease")
writeData(res, "ST11.Heart disease", arhy_hea)
writeData(res, "ST11.Heart disease", arhy_conv, startRow = 10)
writeData(res, "ST11.Heart disease", arhy_wo_2, startRow = 20)
writeData(res, "ST11.Heart disease", arhy_wo_5, startRow = 30)
writeData(res, "ST11.Heart disease", hf_hea, startRow = 40)
writeData(res, "ST11.Heart disease", hf_conv, startRow = 50)
writeData(res, "ST11.Heart disease", hf_wo_2, startRow = 60)
writeData(res, "ST11.Heart disease", hf_wo_5, startRow = 70)
writeData(res, "ST11.Heart disease", ihd_hea, startRow = 80)
writeData(res, "ST11.Heart disease", ihd_conv, startRow = 90)
writeData(res, "ST11.Heart disease", ihd_wo_2, startRow = 100)
writeData(res, "ST11.Heart disease", ihd_wo_5, startRow = 110)
writeData(res, "ST11.Heart disease", ihd_qrisk, startRow = 120)

# ST12: Lung & COPD
addWorksheet(res, "ST12.Lung & COPD")
writeData(res, "ST12.Lung & COPD", copd_lung)
writeData(res, "ST12.Lung & COPD", copd_conv, startRow = 10)
writeData(res, "ST12.Lung & COPD", copd_wo_2, startRow = 20)
writeData(res, "ST12.Lung & COPD", copd_wo_5, startRow = 30)
writeData(res, "ST12.Lung & COPD", copd_smok, startRow = 40)

# ST13: Kidney & CKD
addWorksheet(res, "ST13.Kidney & CKD")
writeData(res, "ST13.Kidney & CKD", ckd_kid)
writeData(res, "ST13.Kidney & CKD", ckd_conv, startRow = 10)
writeData(res, "ST13.Kidney & CKD", ckd_wo_2, startRow = 20)
writeData(res, "ST13.Kidney & CKD", ckd_wo_5, startRow = 30)
writeData(res, "ST13.Kidney & CKD", ckd_egfr, startRow = 40)

# ST14: Immune-Lung & COVID
addWorksheet(res, "ST14.COVID")
writeData(res, "ST14.COVID", covid_org)
writeData(res, "ST14.COVID", covid_conv, startRow = 10)

# Save
saveWorkbook(
res, "S:/LHA_JG0923/Revision/Aim_2_ST.xlsx", overwrite=TRUE)

# Source code files

sc <- createWorkbook()

# Fig 2c
addWorksheet(sc, "Fig 2c")
writeData(sc, "Fig 2c", mort_ext_results)

# Fig 2e
addWorksheet(sc, "Fig 2e")
writeData(sc, "Fig 2e", mort_multiorgan)
writeData(sc, "Fig 2e", multiorgan_death_counts, 
startRow=10, startCol=1)

# ED Fig 4c

# ED Fig 5b

# ED Fig 5c

# ED Fig 6b

# ED Fig 6c

# ED Fig 6d

# ED Fig 6e

# Save
saveWorkbook(
sc, "S:/LHA_JG0923/Revision/SC_Aim_2.xlsx", overwrite=TRUE)

#### VISUALISATION ####

# Mortality KM plots

for (organ in organs) {
  
  # Store the Name of The AgeVariable
  agevariable <- paste0(organ, "Age60high")
  
  # Fit model 
  formula1 <- as.formula(paste("Surv(death_yearssincesample, death) ~ ", agevariable))
  model <- survfit(formula1, data=dataset)
  km_data <- tidy(model)
  
  #Plot
  p <- ggplot(km_data, aes(x=time, y=1-estimate, color=strata)) + 
    geom_step() + 
    theme_minimal() +
    scale_color_manual(values = c("green",  "red")) +
    scale_fill_manual(values = c("green", "red")) +
    geom_ribbon(aes(ymin=1-conf.low, ymax=1-conf.high, fill=strata), alpha=0.3) +
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(), 
          axis.line=element_line(color="black"),
    axis.ticks=element_line(color="black")) +
    scale_y_continuous(labels = scales::percent, expand=expansion(mult=c(0,0.06)), limits=c(0,.5)) + 
    scale_x_continuous(expand=expansion(mult=c(0,0.05))) + 
    theme(legend.position="none",
          axis.title=element_blank())
  
  ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/Fig3a",organ,".pdf"), plot=p, width = 4, height = 3)
}

# AF

formula1 <- as.formula("Surv(event_months, AF_event) ~ HeartAge60high")
formula2 <- as.formula("Surv(event_months, AF_event) ~ ConventionalAge60high")

sub <- dataset %>% filter(AF_prev == 0)

sub$event_months <- sub$AF_time - sub$protdate

model <- survfit(formula1, data = sub)

km_data <- tidy(model)

p <- ggplot(km_data, aes(x=time, y=1-estimate, color=strata)) + 
  geom_step() + 
  theme_minimal() +
  scale_color_manual(values = c("green",  "red")) +
  scale_fill_manual(values = c("green", "red")) +
  geom_ribbon(aes(ymin=1-conf.low, ymax=1-conf.high, fill=strata), alpha=0.3) +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line=element_line(color="black"),
        axis.ticks=element_line(color="black")) +
  scale_y_continuous(labels = scales::percent, expand=expansion(mult=c(0,0.06)), limits=c(0,.5)) + 
  scale_x_continuous(expand=expansion(mult=c(0,0.05))) + 
  theme(legend.position="none",
        axis.title=element_blank())
p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX6aHeart.pdf"), plot=p, width = 8, height = 6)

model <- survfit(formula2, data = sub)

km_data <- tidy(model)

p <- ggplot(km_data, aes(x=time, y=1-estimate, color=strata)) + 
  geom_step() + 
  theme_minimal() +
  scale_color_manual(values = c("green",  "red")) +
  scale_fill_manual(values = c("green", "red")) +
  geom_ribbon(aes(ymin=1-conf.low, ymax=1-conf.high, fill=strata), alpha=0.3) +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line=element_line(color="black"),
        axis.ticks=element_line(color="black")) +
  scale_y_continuous(labels = scales::percent, expand=expansion(mult=c(0,0.06)), limits=c(0,.5)) + 
  scale_x_continuous(expand=expansion(mult=c(0,0.05))) + 
  theme(legend.position="none",
        axis.title=element_blank())
p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX6aConventional.pdf"), plot=p, width = 8, height = 6)

# Heart Failure

formula1 <- as.formula("Surv(event_months, HF_event) ~ HeartAge60high")
formula2 <- as.formula("Surv(event_months, HF_event) ~ ConventionalAge60high")

sub <- dataset %>% filter(HF_prev == 0)

sub$event_months <- sub$HF_time - sub$protdate

model <- survfit(formula1, data = sub)

km_data <- tidy(model)

p <- ggplot(km_data, aes(x=time, y=1-estimate, color=strata)) + 
  geom_step() + 
  theme_minimal() +
  scale_color_manual(values = c("green",  "red")) +
  scale_fill_manual(values = c("green", "red")) +
  geom_ribbon(aes(ymin=1-conf.low, ymax=1-conf.high, fill=strata), alpha=0.3) +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line=element_line(color="black"),
        axis.ticks=element_line(color="black")) +
  scale_y_continuous(labels = scales::percent, expand=expansion(mult=c(0,0.06)), limits=c(0,.3)) + 
  scale_x_continuous(expand=expansion(mult=c(0,0.05))) + 
  theme(legend.position="none",
        axis.title=element_blank())
p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX6bHeart.pdf"), plot=p, width = 8, height = 6)

model <- survfit(formula2, data = sub)

km_data <- tidy(model)

p <- ggplot(km_data, aes(x=time, y=1-estimate, color=strata)) + 
  geom_step() + 
  theme_minimal() +
  scale_color_manual(values = c("green",  "red")) +
  scale_fill_manual(values = c("green", "red")) +
  geom_ribbon(aes(ymin=1-conf.low, ymax=1-conf.high, fill=strata), alpha=0.3) +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line=element_line(color="black"),
        axis.ticks=element_line(color="black")) +
  scale_y_continuous(labels = scales::percent, expand=expansion(mult=c(0,0.06)), limits=c(0,.3)) + 
  scale_x_continuous(expand=expansion(mult=c(0,0.05))) + 
  theme(legend.position="none",
        axis.title=element_blank())
p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX6bConventional.pdf"), plot=p, width = 8, height = 6)

# Ischaemic Heart disease

b <- imp_list_qrisk[[1]]

b$qrisk20 <- ifelse(b$QRISK3_2017>20, 1, 0)

b$heart_qrisk <- ifelse(b$HeartAge60high == 0 & b$qrisk20 == 1, 1,
                 ifelse(b$HeartAge60high == 1 & b$qrisk20 == 0, 2, 
                 ifelse(b$HeartAge60high == 1 & b$qrisk20 == 1, 3, 0)))

formula1 <- as.formula("Surv(event_months, IHD_event) ~ heart_qrisk")

sub <- b %>% filter(IHD_prev == 0)

sub$event_months <- sub$IHD_time - sub$protdate

model <- survfit(formula1, data = sub)

km_data <- tidy(model)

p <- ggplot(km_data, aes(x=time, y=1-estimate, color=strata)) + 
  geom_step(linewidth = 3) + 
  theme_minimal() +
  scale_color_manual(values = c("#009E73", "#4C72B0", "#DD8452", "red")) +
  scale_fill_manual(values = c("#009E73", "#4C72B0", "#DD8452", "red")) +
#  geom_ribbon(aes(ymin=1-conf.low, ymax=1-conf.high, fill=strata), alpha=0.3) +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line=element_line(color="black"),
        axis.ticks=element_line(color="black")) +
  scale_y_continuous(labels = scales::percent, expand=expansion(mult=c(0,0.06)), limits=c(0,.3)) + 
  scale_x_continuous(expand=expansion(mult=c(0,0.05))) + 
  theme(legend.position="none",
        axis.title=element_blank())
p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX6cHeart.pdf"), plot=p, width = 8, height = 6)

# COPD

a <- complete(imputed_data, 1)

a$lung_smok <- ifelse(a$LungAge60high == 0 & a$packyrs >= 15, 1,
                        ifelse(a$LungAge60high == 1 & a$packyrs < 15, 2, 
                               ifelse(a$LungAge60high == 1 & a$packyrs >= 15, 3, 0)))

formula1 <- as.formula("Surv(event_months, COPD_event) ~ lung_smok")

sub <- a %>% filter(COPD_prev == 0)

sub$event_months <- sub$COPD_time - sub$protdate

model <- survfit(formula1, data = sub)

km_data <- tidy(model)

p <- ggplot(km_data, aes(x=time, y=1-estimate, color=strata)) + 
  geom_step(linewidth = 3) + 
  theme_minimal() +
  scale_color_manual(values = c("#009E73", "#4C72B0", "#DD8452", "red")) +
  scale_fill_manual(values = c("#009E73", "#4C72B0", "#DD8452", "red")) +
#  geom_ribbon(aes(ymin=1-conf.low, ymax=1-conf.high, fill=strata), alpha=0.3) +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line=element_line(color="black"),
        axis.ticks=element_line(color="black")) +
  scale_y_continuous(labels = scales::percent, expand=expansion(mult=c(0,0.06)), limits=c(0,.6)) + 
  scale_x_continuous(expand=expansion(mult=c(0,0.05))) + 
  theme(legend.position="none",
        axis.title=element_blank())
p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX6dLung.pdf"), plot=p, width = 8, height = 6)

# CKD

a$kidney_ckd <- ifelse(a$KidneyAge60high == 0 & a$egfr09 < 90, 1,
                      ifelse(a$KidneyAge60high == 1 & a$egfr09 >= 90, 2, 
                             ifelse(a$KidneyAge60high == 1 & a$egfr09 < 90, 3, 0)))

formula1 <- as.formula("Surv(event_months, CKD_event) ~ kidney_ckd")

sub <- a %>% filter(CKD_prev == 0)

sub$event_months <- sub$CKD_time - sub$protdate

model <- survfit(formula1, data = sub)

km_data <- tidy(model)

p <- ggplot(km_data, aes(x=time, y=1-estimate, color=strata)) + 
  geom_step(linewidth = 3) + 
  theme_minimal() +
  scale_color_manual(values = c("#009E73", "#4C72B0", "#DD8452", "red")) +
  scale_fill_manual(values = c("#009E73", "#4C72B0", "#DD8452", "red")) +
  # geom_ribbon(aes(ymin=1-conf.low, ymax=1-conf.high, fill=strata), alpha=0.3) +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line=element_line(color="black"),
        axis.ticks=element_line(color="black")) +
  scale_y_continuous(labels = scales::percent, expand=expansion(mult=c(0,0.06)), limits=c(0,.3)) + 
  scale_x_continuous(expand=expansion(mult=c(0,0.05))) + 
  theme(legend.position="none",
        axis.title=element_blank())
p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX6eKidney.pdf"), plot=p, width = 8, height = 6)

# COVID-19 cases

cases <- dataset %>% filter(COVID_event==1)

p <- ggplot(cases, aes(x = COVID_time)) + 
  annotate("rect", xmin = 2006.5, xmax = 2011.167,
           ymin = 0, ymax = 20, 
           fill = "#D8CFF7", alpha = 0.3) +
  geom_histogram(binwidth = 1, fill = "#00A087", color = "black") + 
  scale_x_continuous(expand = c(0, 0), limits = c(2006, 2024), breaks = seq(2006, 2024, by = 2)) + 
  scale_y_continuous(expand = c(0, 0), limits = c(0, 20)) + 
  geom_vline(xintercept=2019.5, color="red") +
  theme_classic() 

p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX6fCOVID.pdf"), plot=p, width = 10, height = 3)







