
# ============================================================
# 8_Aim_3_Generate_Results.R
# Aim 3 analysis: Life course exposures & organ ageing
# Author: James Groves
# Date: 2025-08-30
# ============================================================

#### SET-UP ####

# Packages

library(tidyverse)
library(readxl)
library(broom)
library(haven)
library(openxlsx)
library(glmnet)
library(mice)
library(mediation)
library(survival)
library(car)
library(mitml)
library(miceadds)
library(lmerTest)
library(mfp)
library(medflex)

# Directory

setwd("S:/LHA_JG0923/Revision/")

inp <- file.path(getwd(), "8. Aim 3 - Modifiable risk factor associations")
out <- file.path(getwd(), "8. Aim 3 - Modifiable risk factor associations")

#### LOAD & PREPARE DATA ####

dataset_all <- read.csv(file.path(inp, "dataset_all.csv"))

load(file.path(inp, "dataset_inc.RData"))

load(file.path(inp, "imp_data.RData"))

inp <- file.path(getwd(), "8. Aim 3 - Modifiable risk factor associations")

load(file.path(inp, "imp_data_men.RData"))

load(file.path(inp, "imp_data_women.RData"))

sex_interactions <- lapply(1:30, function(i){
  df1 <- complete(imputed_data_men, action = i)
  df2 <- complete(imputed_data_women, action = i)
  
  rbind(df1, df2)
}
)

imp_list <- complete(imputed_data, action="all")

organs <- c("Conventional", "Brain", 
            "Heart", "Lung", 
            "Liver", "Kidney", 
            "Immune", "Artery")

#### EXPOSURES & ORGAN AGEING: PRIMARY ANALYSES ####

# Life course exposures & organ ages

for (organ in organs) {
  
agevariable <- paste0(organ, "Age60")
  
formula1 <- as.formula(paste(agevariable, " ~  lowbwt + chsc + Sex_F + Age60"))

models <- with(imputed_data, {
  f <- formula1
  environment(f) <- environment()
  lm(f)
})

  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("bwt_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Childhood Social Class
  formula1 <- as.formula(paste(agevariable, " ~  high_ses + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("socio_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  
  # Examine Associations with Education
  formula1 <- as.formula(paste(agevariable, "~  obtained_gcse + chsc + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("gcse_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Adolescent BMI
  formula1 <- as.formula(paste(agevariable," ~  adolescent_overweight + chsc + Sex_F + Age60"))

  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("cbmi_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Smoking
  formula1 <- as.formula(paste(agevariable," ~ packyrs + chsc + sc1553 + Sex_F + Age60"))
 
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("smok_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Alcohol
  formula1 <- as.formula(paste(agevariable, "~ alcohol_intake + chsc + sc1553 + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("alc_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Activity
  formula1 <- as.formula(paste(agevariable, "~ active + chsc + sc1553 + Sex_F + Age60"))
 
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("act_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Adversity
  formula1 <- as.formula(paste(agevariable, "~ adall + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("adv_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
}

bwt_res <- bind_rows(
  "Conventional" = bwt_Conventional,
  "Brain" = bwt_Brain,
  "Heart" = bwt_Heart,
  "Lung" = bwt_Lung,
  "Liver" = bwt_Liver,
  "Kidney" = bwt_Kidney,
  "Immune" = bwt_Immune,
  "Artery" = bwt_Artery,
  .id="Organ"
)

bwt_res$padj <- p.adjust(bwt_res$p.value, method="BH")

bwt_res <- bwt_res %>% subset(select=-c(term, df))
bwt_res <- bwt_res %>% rename(lci=`2.5 %`, uci=`97.5 %`)

socio_res <- bind_rows(
  "Conventional" = socio_Conventional,
  "Brain" = socio_Brain,
  "Heart" = socio_Heart,
  "Lung" = socio_Lung,
  "Liver" = socio_Liver,
  "Kidney" = socio_Kidney,
  "Immune" = socio_Immune,
  "Artery" = socio_Artery,
  .id="Organ"
)

socio_res$padj <- p.adjust(socio_res$p.value, method="BH")
socio_res <- socio_res %>% subset(select=-c(term, df))
socio_res <- socio_res %>% rename(lci=`2.5 %`, uci=`97.5 %`)

gcse_res <- bind_rows(
  "Conventional" = gcse_Conventional,
  "Brain" = gcse_Brain,
  "Heart" = gcse_Heart,
  "Lung" = gcse_Lung,
  "Liver" = gcse_Liver,
  "Kidney" = gcse_Kidney,
  "Immune" = gcse_Immune,
  "Artery" = gcse_Artery,
  .id="Organ"
)

gcse_res$padj <- p.adjust(gcse_res$p.value, method="BH")

gcse_res <- gcse_res %>% subset(select=-c(term, df))
gcse_res <- gcse_res %>% rename(lci=`2.5 %`, uci=`97.5 %`)

cbmi_res <- bind_rows(
  "Conventional" = cbmi_Conventional,
  "Brain" = cbmi_Brain,
  "Heart" = cbmi_Heart,
  "Lung" = cbmi_Lung,
  "Liver" = cbmi_Liver,
  "Kidney" = cbmi_Kidney,
  "Immune" = cbmi_Immune,
  "Artery" = cbmi_Artery,
  .id="Organ"
)

cbmi_res$padj <- p.adjust(cbmi_res$p.value, method="BH")

cbmi_res <- cbmi_res %>% subset(select=-c(term, df))
cbmi_res <- cbmi_res %>% rename(lci=`2.5 %`, uci=`97.5 %`)

smoking_res <- bind_rows(
  "Conventional" = smok_Conventional,
  "Brain" = smok_Brain,
  "Heart" = smok_Heart,
  "Lung" = smok_Lung,
  "Liver" = smok_Liver,
  "Kidney" = smok_Kidney,
  "Immune" = smok_Immune,
  "Artery" = smok_Artery,
  .id="Organ"
)

smoking_res$padj <- p.adjust(smoking_res$p.value, method="BH")

smoking_res <- smoking_res %>% subset(select=-c(term, df))
smoking_res <- smoking_res %>% rename(lci=`2.5 %`, uci=`97.5 %`)

alc_res <- bind_rows(
  "Conventional" = alc_Conventional,
  "Brain" = alc_Brain,
  "Heart" = alc_Heart,
  "Lung" = alc_Lung,
  "Liver" = alc_Liver,
  "Kidney" = alc_Kidney,
  "Immune" = alc_Immune,
  "Artery" = alc_Artery,
  .id="Organ"
)

alc_res$padj <- p.adjust(alc_res$p.value, method="BH")

alc_res <- alc_res %>% subset(select=-c(term, df))
alc_res <- alc_res %>% rename(lci=`2.5 %`, uci=`97.5 %`)

act_res <- bind_rows(
  "Conventional" = act_Conventional,
  "Brain" = act_Brain,
  "Heart" = act_Heart,
  "Lung" = act_Lung,
  "Liver" = act_Liver,
  "Kidney" = act_Kidney,
  "Immune" = act_Immune,
  "Artery" = act_Artery,
  .id="Organ"
)

act_res$padj <- p.adjust(act_res$p.value, method="BH")
act_res <- act_res %>% subset(select=-c(term, df))
act_res <- act_res %>% rename(lci=`2.5 %`, uci=`97.5 %`)

adv_res <- bind_rows(
  "Conventional" = adv_Conventional,
  "Brain" = adv_Brain,
  "Heart" = adv_Heart,
  "Lung" = adv_Lung,
  "Liver" = adv_Liver,
  "Kidney" = adv_Kidney,
  "Immune" = adv_Immune,
  "Artery" = adv_Artery,
  .id="Organ"
)

adv_res$padj <- p.adjust(adv_res$p.value, method="BH")

adv_res <- adv_res %>% subset(select=-c(term, df))
adv_res <- adv_res %>% rename(lci=`2.5 %`, uci=`97.5 %`)

# Sex interactions: Life course exposures & organ ages

for (organ in organs) {
  
  agevariable <- paste0(organ, "Age60")
  
  formula1 <- as.formula(paste(agevariable, " ~  lowbwt * Sex_F + chsc + Age60"))
  
  fit <- lapply(sex_interactions, function(d) lm(formula1, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  tidy_model <- summary(pooled, conf.int=TRUE)
  
  model_name <- paste0("bwt_", organ)
  ageoutput <- tidy_model[10,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Childhood Social Class
  formula1 <- as.formula(paste(agevariable, " ~  high_ses * Sex_F + Age60"))
  
  fit <- lapply(sex_interactions, function(d) lm(formula1, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  tidy_model <- summary(pooled, conf.int=TRUE)
  
  model_name <- paste0("socio_", organ)
  ageoutput <- tidy_model[5,]
  assign(model_name, ageoutput)
  
  
  # Examine Associations with Education
  formula1 <- as.formula(paste(agevariable, "~  obtained_gcse * Sex_F + chsc + Age60"))
  
  fit <- lapply(sex_interactions, function(d) lm(formula1, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  tidy_model <- summary(pooled, conf.int=TRUE)
  
  model_name <- paste0("gcse_", organ)
  ageoutput <- tidy_model[10,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Adolescent BMI
  formula1 <- as.formula(paste(agevariable," ~  adolescent_overweight * Sex_F + chsc + Age60"))
  
  fit <- lapply(sex_interactions, function(d) lm(formula1, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  tidy_model <- summary(pooled, conf.int=TRUE)
  
  model_name <- paste0("cbmi_", organ)
  ageoutput <- tidy_model[10,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Smoking
  formula1 <- as.formula(paste(agevariable," ~ packyrs * Sex_F + chsc + sc1553 + Age60"))
  
  fit <- lapply(sex_interactions, function(d) lm(formula1, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  tidy_model <- summary(pooled, conf.int=TRUE)
  
  model_name <- paste0("smok_", organ)
  ageoutput <- tidy_model[15,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Alcohol
  formula1 <- as.formula(paste(agevariable, "~ alcohol_intake * Sex_F + chsc + sc1553 + Age60"))
  
  fit <- lapply(sex_interactions, function(d) lm(formula1, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  tidy_model <- summary(pooled, conf.int=TRUE)
  
  model_name <- paste0("alc_", organ)
  ageoutput <- tidy_model[15,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Activity
  formula1 <- as.formula(paste(agevariable, "~ active * Sex_F + chsc + sc1553 + Age60"))
  
  fit <- lapply(sex_interactions, function(d) lm(formula1, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  tidy_model <- summary(pooled, conf.int=TRUE)
  
  model_name <- paste0("act_", organ)
  ageoutput <- tidy_model[15,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Adversity
  formula1 <- as.formula(paste(agevariable, "~ adall * Sex_F + Age60"))
  
  fit <- lapply(sex_interactions, function(d) lm(formula1, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  tidy_model <- summary(pooled, conf.int=TRUE)
  
  model_name <- paste0("adv_", organ)
  ageoutput <- tidy_model[5,]
  assign(model_name, ageoutput)
  
}

bwt_sex <- bind_rows(
  "Conventional" = bwt_Conventional,
  "Brain" = bwt_Brain,
  "Heart" = bwt_Heart,
  "Lung" = bwt_Lung,
  "Liver" = bwt_Liver,
  "Kidney" = bwt_Kidney,
  "Immune" = bwt_Immune,
  "Artery" = bwt_Artery,
  .id="Organ"
)

bwt_sex$padj <- p.adjust(bwt_sex$p, method="BH")
bwt_sex <- bwt_sex %>% rename(lci=`(lower`, uci=`upper)`)

socio_sex <- bind_rows(
  "Conventional" = socio_Conventional,
  "Brain" = socio_Brain,
  "Heart" = socio_Heart,
  "Lung" = socio_Lung,
  "Liver" = socio_Liver,
  "Kidney" = socio_Kidney,
  "Immune" = socio_Immune,
  "Artery" = socio_Artery,
  .id="Organ"
)

socio_sex$padj <- p.adjust(socio_sex$p, method="BH")
socio_sex <- socio_sex %>% rename(lci=`(lower`, uci=`upper)`)

gcse_sex <- bind_rows(
  "Conventional" = gcse_Conventional,
  "Brain" = gcse_Brain,
  "Heart" = gcse_Heart,
  "Lung" = gcse_Lung,
  "Liver" = gcse_Liver,
  "Kidney" = gcse_Kidney,
  "Immune" = gcse_Immune,
  "Artery" = gcse_Artery,
  .id="Organ"
)

gcse_sex$padj <- p.adjust(gcse_sex$p, method="BH")
gcse_sex <- gcse_sex %>% rename(lci=`(lower`, uci=`upper)`)

cbmi_sex <- bind_rows(
  "Conventional" = cbmi_Conventional,
  "Brain" = cbmi_Brain,
  "Heart" = cbmi_Heart,
  "Lung" = cbmi_Lung,
  "Liver" = cbmi_Liver,
  "Kidney" = cbmi_Kidney,
  "Immune" = cbmi_Immune,
  "Artery" = cbmi_Artery,
  .id="Organ"
)

cbmi_sex$padj <- p.adjust(cbmi_sex$p, method="BH")
cbmi_sex <- cbmi_sex %>% rename(lci=`(lower`, uci=`upper)`)

smoking_sex <- bind_rows(
  "Conventional" = smok_Conventional,
  "Brain" = smok_Brain,
  "Heart" = smok_Heart,
  "Lung" = smok_Lung,
  "Liver" = smok_Liver,
  "Kidney" = smok_Kidney,
  "Immune" = smok_Immune,
  "Artery" = smok_Artery,
  .id="Organ"
)

smoking_sex$padj <- p.adjust(smoking_sex$p, method="BH")
smoking_sex <- smoking_sex %>% rename(lci=`(lower`, uci=`upper)`)

alc_sex <- bind_rows(
  "Conventional" = alc_Conventional,
  "Brain" = alc_Brain,
  "Heart" = alc_Heart,
  "Lung" = alc_Lung,
  "Liver" = alc_Liver,
  "Kidney" = alc_Kidney,
  "Immune" = alc_Immune,
  "Artery" = alc_Artery,
  .id="Organ"
)

alc_sex$padj <- p.adjust(alc_sex$p, method="BH")
alc_sex <- alc_sex %>% rename(lci=`(lower`, uci=`upper)`)

act_sex <- bind_rows(
  "Conventional" = act_Conventional,
  "Brain" = act_Brain,
  "Heart" = act_Heart,
  "Lung" = act_Lung,
  "Liver" = act_Liver,
  "Kidney" = act_Kidney,
  "Immune" = act_Immune,
  "Artery" = act_Artery,
  .id="Organ"
)

act_sex$padj <- p.adjust(act_sex$p, method="BH")
act_sex <- act_sex %>% rename(lci=`(lower`, uci=`upper)`)

adv_sex <- bind_rows(
  "Conventional" = adv_Conventional,
  "Brain" = adv_Brain,
  "Heart" = adv_Heart,
  "Lung" = adv_Lung,
  "Liver" = adv_Liver,
  "Kidney" = adv_Kidney,
  "Immune" = adv_Immune,
  "Artery" = adv_Artery,
  .id="Organ"
)

adv_sex$padj <- p.adjust(adv_sex$p, method="BH")
adv_sex <- adv_sex %>% rename(lci=`(lower`, uci=`upper)`)

# Healthy subset: Sensitivity analysis for organ age - life course exposure associations

for (organ in organs) {
  
  agevariable <- paste0(organ, "Age60")
  
  formula1 <- as.formula(paste(agevariable, " ~  lowbwt + chsc + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("bwt_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Childhood Social Class
  formula1 <- as.formula(paste(agevariable, " ~  high_ses + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("socio_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  
  # Examine Associations with Education
  formula1 <- as.formula(paste(agevariable, "~  obtained_gcse + chsc + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("gcse_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Adolescent BMI
  formula1 <- as.formula(paste(agevariable," ~  adolescent_overweight + chsc + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("cbmi_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Smoking
  formula1 <- as.formula(paste(agevariable," ~ packyrs + chsc + sc1553 + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("smok_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Alcohol
  formula1 <- as.formula(paste(agevariable, "~ alcohol_intake + chsc + sc1553 + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("alc_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Activity
  formula1 <- as.formula(paste(agevariable, "~ active + chsc + sc1553 + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("act_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Adversity
  formula1 <- as.formula(paste(agevariable, "~ adall + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  tidy_model <- summary(results, conf.int=TRUE)
  
  model_name <- paste0("adv_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
}

bwt_sens <- bind_rows(
  "Conventional" = bwt_Conventional,
  "Brain" = bwt_Brain,
  "Heart" = bwt_Heart,
  "Lung" = bwt_Lung,
  "Liver" = bwt_Liver,
  "Kidney" = bwt_Kidney,
  "Immune" = bwt_Immune,
  "Artery" = bwt_Artery,
  .id="Organ"
)

bwt_sens$padj <- p.adjust(bwt_sens$p.value, method="BH")

bwt_sens <- bwt_sens %>% subset(select=-c(term, df))
bwt_sens <- bwt_sens %>% rename(lci=`2.5 %`, uci=`97.5 %`)

socio_sens <- bind_rows(
  "Conventional" = socio_Conventional,
  "Brain" = socio_Brain,
  "Heart" = socio_Heart,
  "Lung" = socio_Lung,
  "Liver" = socio_Liver,
  "Kidney" = socio_Kidney,
  "Immune" = socio_Immune,
  "Artery" = socio_Artery,
  .id="Organ"
)

socio_sens$padj <- p.adjust(socio_sens$p.value, method="BH")
socio_sens <- socio_sens %>% subset(select=-c(term, df))
socio_sens <- socio_sens %>% rename(lci=`2.5 %`, uci=`97.5 %`)

gcse_sens <- bind_rows(
  "Conventional" = gcse_Conventional,
  "Brain" = gcse_Brain,
  "Heart" = gcse_Heart,
  "Lung" = gcse_Lung,
  "Liver" = gcse_Liver,
  "Kidney" = gcse_Kidney,
  "Immune" = gcse_Immune,
  "Artery" = gcse_Artery,
  .id="Organ"
)

gcse_sens$padj <- p.adjust(gcse_sens$p.value, method="BH")

gcse_sens <- gcse_sens %>% subset(select=-c(term, df))
gcse_sens <- gcse_sens %>% rename(lci=`2.5 %`, uci=`97.5 %`)

cbmi_sens <- bind_rows(
  "Conventional" = cbmi_Conventional,
  "Brain" = cbmi_Brain,
  "Heart" = cbmi_Heart,
  "Lung" = cbmi_Lung,
  "Liver" = cbmi_Liver,
  "Kidney" = cbmi_Kidney,
  "Immune" = cbmi_Immune,
  "Artery" = cbmi_Artery,
  .id="Organ"
)

cbmi_sens$padj <- p.adjust(cbmi_sens$p.value, method="BH")

cbmi_sens <- cbmi_sens %>% subset(select=-c(term, df))
cbmi_sens <- cbmi_sens %>% rename(lci=`2.5 %`, uci=`97.5 %`)

smoking_sens <- bind_rows(
  "Conventional" = smok_Conventional,
  "Brain" = smok_Brain,
  "Heart" = smok_Heart,
  "Lung" = smok_Lung,
  "Liver" = smok_Liver,
  "Kidney" = smok_Kidney,
  "Immune" = smok_Immune,
  "Artery" = smok_Artery,
  .id="Organ"
)

smoking_sens$padj <- p.adjust(smoking_sens$p.value, method="BH")

smoking_sens <- smoking_sens %>% subset(select=-c(term, df))
smoking_sens <- smoking_sens %>% rename(lci=`2.5 %`, uci=`97.5 %`)

alc_sens <- bind_rows(
  "Conventional" = alc_Conventional,
  "Brain" = alc_Brain,
  "Heart" = alc_Heart,
  "Lung" = alc_Lung,
  "Liver" = alc_Liver,
  "Kidney" = alc_Kidney,
  "Immune" = alc_Immune,
  "Artery" = alc_Artery,
  .id="Organ"
)

alc_sens$padj <- p.adjust(alc_sens$p.value, method="BH")

alc_sens <- alc_sens %>% subset(select=-c(term, df))
alc_sens <- alc_sens %>% rename(lci=`2.5 %`, uci=`97.5 %`)

act_sens <- bind_rows(
  "Conventional" = act_Conventional,
  "Brain" = act_Brain,
  "Heart" = act_Heart,
  "Lung" = act_Lung,
  "Liver" = act_Liver,
  "Kidney" = act_Kidney,
  "Immune" = act_Immune,
  "Artery" = act_Artery,
  .id="Organ"
)

act_sens$padj <- p.adjust(act_sens$p.value, method="BH")
act_sens <- act_sens %>% subset(select=-c(term, df))
act_sens <- act_sens %>% rename(lci=`2.5 %`, uci=`97.5 %`)

adv_sens <- bind_rows(
  "Conventional" = adv_Conventional,
  "Brain" = adv_Brain,
  "Heart" = adv_Heart,
  "Lung" = adv_Lung,
  "Liver" = adv_Liver,
  "Kidney" = adv_Kidney,
  "Immune" = adv_Immune,
  "Artery" = adv_Artery,
  .id="Organ"
)

adv_sens$padj <- p.adjust(adv_sens$p.value, method="BH")

adv_sens <- adv_sens %>% subset(select=-c(term, df))
adv_sens <- adv_sens %>% rename(lci=`2.5 %`, uci=`97.5 %`)

# Non-linearity: Select significant associations to examine

cbmi_res$exposure <- "bmi61u"
smoking_res$exposure <- "packrs"
alc_res$exposure <- "alcohol_intake"
act_res$exposure <- "as.numeric(activecategory)"
adv_res$exposure <- "adall"

all_ass <- rbind (cbmi_res, smoking_res, alc_res, act_res, adv_res)

sig_ass <- all_ass %>%
  filter(
    padj < 0.05
  ) %>%
  subset(
    select = c(Organ, exposure)
  )

# Non-linearity: Examine childhood BMI associations

conv_bmi_fp <- mfp(ConventionalAge60 ~ fp(bmi61u, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
conv_bmi <- data.frame(Organ = "Conventional", Exposure = "bmi61u", p_value = conv_bmi_fp$pvalues["bmi61u", "p.lin"])

liv_bmi_fp <- mfp(LiverAge60 ~ fp(bmi61u, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
liv_bmi <- data.frame(Organ = "Liver", Exposure = "bmi61u", p_value = liv_bmi_fp$pvalues["bmi61u", "p.lin"])

kid_bmi_fp <- mfp(KidneyAge60 ~ fp(bmi61u, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
kid_bmi <- data.frame(Organ = "Kidney", Exposure = "bmi61u", p_value = kid_bmi_fp$pvalues["bmi61u", "p.lin"])

imm_bmi_fp <- mfp(ImmuneAge60 ~ fp(bmi61u, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
imm_bmi <- data.frame(Organ = "Immune", Exposure = "bmi61u", p_value = imm_bmi_fp$pvalues["bmi61u", "p.lin"])

# Non-linearity: Examine smoking associations

dataset$packyrs <- dataset$packyr20 + dataset$packyr2025 + dataset$packyr2531 + dataset$packyr3136 +
                    dataset$packyr3643 + dataset$packyr4353 + dataset$packyr5363

conv_smok_fp <- mfp(ConventionalAge60 ~ fp(packyrs, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
conv_smok <- data.frame(Organ = "Conventional", Exposure = "packyrs", p_value = conv_smok_fp$pvalues["packyrs", "p.lin"])

heart_smok_fp <- mfp(HeartAge60 ~ fp(packyrs, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
heart_smok <- data.frame(Organ = "Heart", Exposure = "packyrs", p_value = heart_smok_fp$pvalues["packyrs", "p.lin"])

lung_smok_fp <- mfp(LungAge60 ~ fp(packyrs, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
lung_smok <- data.frame(Organ = "Lung", Exposure = "packyrs", p_value = lung_smok_fp$pvalues["packyrs", "p.lin"])

liv_smok_fp <- mfp(LiverAge60 ~ fp(packyrs, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
liv_smok <- data.frame(Organ = "Liver", Exposure = "packyrs", p_value = liv_smok_fp$pvalues["packyrs", "p.lin"])

kid_smok_fp <- mfp(KidneyAge60 ~ fp(packyrs, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
kid_smok <- data.frame(Organ = "Kidney", Exposure = "packyrs", p_value = kid_smok_fp$pvalues["packyrs", "p.lin"])

imm_smok_fp <- mfp(ImmuneAge60 ~ fp(packyrs, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
imm_smok <- data.frame(Organ = "Immune", Exposure = "packyrs", p_value = imm_smok_fp$pvalues["packyrs", "p.lin"])

# Non-linearity: Examine alcohol associations

dataset$alcohol_intake <- dataset$avalc82u + dataset$avalc89u + dataset$avalc99u + dataset$avalc09u

bra_alc_fp <- mfp(BrainAge60 ~ fp(alcohol_intake, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
bra_alc <- data.frame(Organ = "Brain", Exposure = "alcohol_intake", p_value = bra_alc_fp$pvalues["alcohol_intake", "p.lin"])

# Non-linearity: Examine activity associations

dataset$activecategory <- ifelse(rowSums(cbind(dataset$exer82, dataset$exer89x, dataset$exer99x, dataset$exer09x)==1)==4,1,
ifelse(rowSums(cbind(dataset$exer82, dataset$exer89x, dataset$exer99x, dataset$exer09x)==1)==3,2,
ifelse(rowSums(cbind(dataset$exer82, dataset$exer89x, dataset$exer99x, dataset$exer09x)==1)==2,3,
ifelse(rowSums(cbind(dataset$exer82, dataset$exer89x, dataset$exer99x, dataset$exer09x)==1)==1,4,
ifelse(rowSums(cbind(dataset$exer82, dataset$exer89x, dataset$exer99x, dataset$exer09x)==1)==0,5,NA)))))

conv_act_fp <- mfp(ConventionalAge60 ~ fp(activecategory, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
conv_act <- data.frame(Organ = "Conventional", Exposure = "activecategory", p_value = conv_act_fp$pvalues["activecategory", "p.lin"])

liv_act_fp <- mfp(LiverAge60 ~ fp(activecategory, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
liv_act <- data.frame(Organ = "Liver", Exposure = "activecategory", p_value = liv_act_fp$pvalues["activecategory", "p.lin"])

kid_act_fp <- mfp(KidneyAge60 ~ fp(activecategory, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
kid_act <- data.frame(Organ = "Kidney", Exposure = "activecategory", p_value = kid_act_fp$pvalues["activecategory", "p.lin"])

imm_act_fp <- mfp(ImmuneAge60 ~ fp(activecategory, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
imm_act <- data.frame(Organ = "Immune", Exposure = "activecategory", p_value = imm_act_fp$pvalues["activecategory", "p.lin"])

# Non-linearity: Examine activity associations

dataset$eco16 <- ifelse(dataset$CROW15y == 1 | dataset$amenities == 1 | dataset$childSES == 1 , 1, 0)

dataset$eco36 <- ifelse(dataset$finance36 == 1 | dataset$employed36 == 1 | dataset$amenities26 == 1 | dataset$crow26 == 1 | dataset$work36==1, 1, 0)

dataset$eco4353 <- ifelse(dataset$work4353 == 1 | dataset$finance4353 == 1 | dataset$housecondition43 == 1, 1, 0)

dataset$eco63 <- ifelse(dataset$work63 == 1 | dataset$finance63 == 1, 1, 0)

dataset$phy <- ifelse(dataset$phy16 == 1, 1, 0)

dataset$psyc16 <- ifelse(dataset$matsep == 1 | dataset$divorce16 == 1 | dataset$peers == 1, 1, 0) 

dataset$psyc36 <- ifelse(dataset$social36 == 1 | dataset$divorce36 == 1, 1, 0)

dataset$psyc4353 <- ifelse(dataset$support4353 == 1 | dataset$lostcontact4353 == 1 | dataset$chdconflict4353 == 1 | dataset$divorce4353 == 1 | dataset$social4353 == 1, 1, 0)

dataset$psyc63 <- ifelse(dataset$support63 == 1 | dataset$lostcontact63 == 1 | dataset$chdconflict63 == 1 | dataset$divorce63 == 1 | dataset$social63 == 1, 1, 0)

dataset$childad_sum <- rowSums(cbind(dataset$eco16, dataset$psyc16, dataset$phy))

dataset$childad <- ifelse(dataset$childad_sum == 0, 0, 1)

dataset$yadult36_sum <- rowSums(cbind(dataset$eco36, dataset$psyc36))

dataset$yadult36 <- ifelse(dataset$yadult36_sum == 0, 0, 1)

dataset$midadult4353_sum <- rowSums(cbind(dataset$eco4353, dataset$psyc4353))

dataset$midadult4353 <- ifelse(dataset$midadult4353_sum == 0, 0, 1)

dataset$lateadult63_sum <- rowSums(cbind(dataset$eco63, dataset$psyc63))

dataset$lateadult63 <- ifelse(dataset$lateadult63_sum == 0, 0, 1)

dataset$adall <- rowSums(cbind(dataset$childad, dataset$yadult36, dataset$midadult4353, dataset$lateadult63))

conv_adv_fp <- mfp(ConventionalAge60 ~ fp(adall, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
conv_adv <- data.frame(Organ = "Conventional", Exposure = "adall", p_value = conv_adv_fp$pvalues["adall", "p.lin"])

liv_adv_fp <- mfp(LiverAge60 ~ fp(adall, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
liv_adv <- data.frame(Organ = "Liver", Exposure = "adall", p_value = liv_adv_fp$pvalues["adall", "p.lin"])

kid_adv_fp <- mfp(KidneyAge60 ~ fp(adall, df = 4, select = 0.05) + Sex_F + Age60, data = dataset, family = gaussian)
kid_adv <- data.frame(Organ = "Kidney", Exposure = "adall", p_value = kid_adv_fp$pvalues["adall", "p.lin"])

# Non-linearity: Bind results

non_lin <- rbind(
  conv_bmi, liv_bmi, kid_bmi, imm_bmi,
  conv_smok, heart_smok, lung_smok, liv_smok, kid_smok, imm_smok,
  bra_alc,
  conv_act, liv_act, kid_act, imm_act, 
  conv_adv, liv_adv, kid_adv
)

non_lin <- non_lin %>%
  group_by(Exposure) %>%
  mutate(padj = p.adjust(p_value, method = "BH")) %>%
  ungroup()

# Sensitivity analyses for disease: Life course exposures & organ ages

for (organ in organs) {
  
  agevariable <- paste0(organ, "Age60")
  
  formula1 <- as.formula(paste(agevariable, " ~  lowbwt + chsc + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  
  tidy_model <- tidy(results, conf.int=TRUE)
  
  model_name <- paste0("bwt_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Childhood Social Class
  formula1 <- as.formula(paste(agevariable, " ~  high_ses + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  
  tidy_model <- tidy(results, conf.int=TRUE)
  
  model_name <- paste0("socio_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  
  # Examine Associations with Education
  formula1 <- as.formula(paste(agevariable, "~  obtained_gcse + chsc + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  
  tidy_model <- tidy(results, conf.int=TRUE)
  
  model_name <- paste0("gcse_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Adolescent BMI
  formula1 <- as.formula(paste(agevariable," ~  adolescent_overweight + chsc + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  
  tidy_model <- tidy(results, conf.int=TRUE)
  
  model_name <- paste0("cbmi_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Smoking
  formula1 <- as.formula(paste(agevariable," ~ packyrs + chsc + sc1553 + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  
  tidy_model <- tidy(results, conf.int=TRUE)
  
  model_name <- paste0("smok_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Alcohol
  formula1 <- as.formula(paste(agevariable, "~ alcohol_intake + chsc + sc1553 + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  
  tidy_model <- tidy(results, conf.int=TRUE)
  
  model_name <- paste0("alc_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Activity
  formula1 <- as.formula(paste(agevariable, "~ active + chsc + sc1553 + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  
  tidy_model <- tidy(results, conf.int=TRUE)
  
  model_name <- paste0("act_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
  # Examine Associations with Adversity
  formula1 <- as.formula(paste(agevariable, "~ adall + Sex_F + Age60"))
  
  models <- with(imputed_data, {
    f <- formula1
    environment(f) <- environment()
    lm(f, subset = disease == 0)
  })
  
  results <- pool(models)
  
  tidy_model <- tidy(results, conf.int=TRUE)
  
  model_name <- paste0("adv_", organ)
  ageoutput <- tidy_model[2,]
  assign(model_name, ageoutput)
  
}

bwt_sens <- bind_rows(
  "Conventional" = bwt_Conventional,
  "Brain" = bwt_Brain,
  "Heart" = bwt_Heart,
  "Lung" = bwt_Lung,
  "Liver" = bwt_Liver,
  "Kidney" = bwt_Kidney,
  "Immune" = bwt_Immune,
  "Artery" = bwt_Artery,
  .id="Organ"
)

bwt_sens$padj <- p.adjust(bwt_sens$p.value, method="BH")

bwt_sens <- bwt_sens %>% subset(select=-c(term))
bwt_sens <- bwt_sens %>% rename(lci=conf.low, uci=conf.high)

socio_sens <- bind_rows(
  "Conventional" = socio_Conventional,
  "Brain" = socio_Brain,
  "Heart" = socio_Heart,
  "Lung" = socio_Lung,
  "Liver" = socio_Liver,
  "Kidney" = socio_Kidney,
  "Immune" = socio_Immune,
  "Artery" = socio_Artery,
  .id="Organ"
)

socio_sens$padj <- p.adjust(socio_sens$p.value, method="BH")
socio_sens <- socio_sens %>% subset(select=-c(term))
socio_sens <- socio_sens %>% rename(lci=conf.low, uci=conf.high)

gcse_sens <- bind_rows(
  "Conventional" = gcse_Conventional,
  "Brain" = gcse_Brain,
  "Heart" = gcse_Heart,
  "Lung" = gcse_Lung,
  "Liver" = gcse_Liver,
  "Kidney" = gcse_Kidney,
  "Immune" = gcse_Immune,
  "Artery" = gcse_Artery,
  .id="Organ"
)

gcse_sens$padj <- p.adjust(gcse_sens$p.value, method="BH")

gcse_sens <- gcse_sens %>% subset(select=-c(term))
gcse_sens <- gcse_sens %>% rename(lci=conf.low, uci=conf.high)

cbmi_sens <- bind_rows(
  "Conventional" = cbmi_Conventional,
  "Brain" = cbmi_Brain,
  "Heart" = cbmi_Heart,
  "Lung" = cbmi_Lung,
  "Liver" = cbmi_Liver,
  "Kidney" = cbmi_Kidney,
  "Immune" = cbmi_Immune,
  "Artery" = cbmi_Artery,
  .id="Organ"
)

cbmi_sens$padj <- p.adjust(cbmi_sens$p.value, method="BH")

cbmi_sens <- cbmi_sens %>% subset(select=-c(term))
cbmi_sens <- cbmi_sens %>% rename(lci=conf.low, uci=conf.high)

smoking_sens <- bind_rows(
  "Conventional" = smok_Conventional,
  "Brain" = smok_Brain,
  "Heart" = smok_Heart,
  "Lung" = smok_Lung,
  "Liver" = smok_Liver,
  "Kidney" = smok_Kidney,
  "Immune" = smok_Immune,
  "Artery" = smok_Artery,
  .id="Organ"
)

smoking_sens$padj <- p.adjust(smoking_sens$p.value, method="BH")

smoking_sens <- smoking_sens %>% subset(select=-c(term))
smoking_sens <- smoking_sens %>% rename(lci=conf.low, uci=conf.high)

alc_sens <- bind_rows(
  "Conventional" = alc_Conventional,
  "Brain" = alc_Brain,
  "Heart" = alc_Heart,
  "Lung" = alc_Lung,
  "Liver" = alc_Liver,
  "Kidney" = alc_Kidney,
  "Immune" = alc_Immune,
  "Artery" = alc_Artery,
  .id="Organ"
)

alc_sens$padj <- p.adjust(alc_sens$p.value, method="BH")

alc_sens <- alc_sens %>% subset(select=-c(term))
alc_sens <- alc_sens %>% rename(lci=conf.low, uci=conf.high)

act_sens <- bind_rows(
  "Conventional" = act_Conventional,
  "Brain" = act_Brain,
  "Heart" = act_Heart,
  "Lung" = act_Lung,
  "Liver" = act_Liver,
  "Kidney" = act_Kidney,
  "Immune" = act_Immune,
  "Artery" = act_Artery,
  .id="Organ"
)

act_sens$padj <- p.adjust(act_sens$p.value, method="BH")
act_sens <- act_sens %>% subset(select=-c(term))
act_sens <- act_sens %>% rename(lci=conf.low, uci=conf.high)

adv_sens <- bind_rows(
  "Conventional" = adv_Conventional,
  "Brain" = adv_Brain,
  "Heart" = adv_Heart,
  "Lung" = adv_Lung,
  "Liver" = adv_Liver,
  "Kidney" = adv_Kidney,
  "Immune" = adv_Immune,
  "Artery" = adv_Artery,
  .id="Organ"
)

adv_sens$padj <- p.adjust(adv_sens$p.value, method="BH")

adv_sens <- adv_sens %>% subset(select=-c(term))
adv_sens <- adv_sens %>% rename(lci=conf.low, uci=conf.high)

# AVOS & life course exposures

fit <- with(imputed_data, lm(scale(avos) ~ lowbwt + chsc + Sex_F + Age60))
pooled <- pool(fit)
avos_bwt <- tidy(pooled, conf.int = T)
avos_bwt <- avos_bwt[2, ]

fit <- with(imputed_data, lm(scale(avos) ~ high_ses + Sex_F + Age60))
pooled <- pool(fit)
avos_ses <- tidy(pooled, conf.int = T)
avos_ses <- avos_ses[2, ]

fit <- with(imputed_data, lm(scale(avos) ~ obtained_gcse + chsc + Sex_F + Age60))
pooled <- pool(fit)
avos_gcse <- tidy(pooled, conf.int = T)
avos_gcse <- avos_gcse[2, ]

fit <- with(imputed_data, lm(scale(avos) ~ adolescent_overweight + chsc + Sex_F + Age60))
pooled <- pool(fit)
avos_ow <- tidy(pooled, conf.int = T)
avos_ow <- avos_ow[2, ]

fit <- with(imputed_data, lm(scale(avos) ~ packyrs + chsc + sc1553 + Sex_F + Age60))
pooled <- pool(fit)
avos_smok <- tidy(pooled, conf.int = T)
avos_smok <- avos_smok[2, ]

fit <- with(imputed_data, lm(scale(avos) ~ alcohol_intake + chsc + sc1553 + Sex_F + Age60))
pooled <- pool(fit)
avos_alc <- tidy(pooled, conf.int = T)
avos_alc <- avos_alc[2, ]

fit <- with(imputed_data, lm(scale(avos) ~ active + chsc + sc1553 + Sex_F + Age60))
pooled <- pool(fit)
avos_act <- tidy(pooled, conf.int = T)
avos_act <- avos_act[2, ]

fit <- with(imputed_data, lm(scale(avos) ~ adall + Sex_F + Age60))
pooled <- pool(fit)
avos_adv <- tidy(pooled, conf.int = T)
avos_adv <- avos_adv[2, ]

lc_avos <- bind_rows(
  "Low birthweight" = avos_bwt,
  "Childhood SES" = avos_ses,
  "Educational attainment" = avos_gcse,
  "Adolescent overweight" = avos_ow,
  "Smoking" = avos_smok,
  "Alcohol" = avos_alc,
  "Activity" = avos_act,
  "Adversity" = avos_adv,
  .id="Organ"
)

#### EXPOSURES & ORGAN AGEING: SECONDARY ANALYSES ####

# Adolescent overweight - Conventional age with adult BMI controlled

fit <- with(imputed_data,lm(
ConventionalAge60 ~ adolescent_overweight + chsc + Sex_F + sc1553 + ifelse(bmi09>25,1,0) + Age60))

adolescent_overweight_63 <- pool(fit)

adolescent_overweight_63 <- tidy(adolescent_overweight_63, conf.int=T)

adolescent_overweight_63 <- adolescent_overweight_63 %>% 
subset(select=-c(
  statistic, df, dfcom, fmi, lambda, riv, ubar, m, b)) 

fit <- with(imputed_data,lm(
ConventionalAge60 ~ adolescent_overweight + chsc + Sex_F  
+ sc1553 + ifelse(bmi09>25,1,0) + ifelse(bmi99u>25,1,0)))

adolescent_overweight_53 <- pool(fit)

adolescent_overweight_53 <- tidy(adolescent_overweight_53, conf.int=T)

adolescent_overweight_53 <- adolescent_overweight_53 %>% 
subset(select=-c(
  statistic, df, dfcom, fmi, lambda, riv, ubar, m, b)) 

fit <- with(imputed_data,lm(
ConventionalAge60 ~ adolescent_overweight + chsc + Sex_F + 
sc1553 + ifelse(bmi99u>25,1,0) + ifelse(bmi89u>25,1,0) + ifelse(bmi09>25,1,0) + Age60))

adolescent_overweight_43 <- pool(fit)

adolescent_overweight_43 <- tidy(adolescent_overweight_43, conf.int=T)

adolescent_overweight_43 <- adolescent_overweight_43 %>% 
subset(select=-c(
  statistic, df, dfcom, fmi, lambda, riv, ubar, m, b)) 

fit <- with(imputed_data,lm(
  ConventionalAge60 ~ adolescent_overweight + chsc + Sex_F + 
    sc1553 + ifelse(bmi99u>25,1,0) + ifelse(bmi89u>25,1,0) + 
    ifelse(bmi82u>25,1,0) + ifelse(bmi09>25,1,0) + Age60))

adolescent_overweight_36 <- pool(fit)

adolescent_overweight_36 <- tidy(adolescent_overweight_36, conf.int=T)

adolescent_overweight_36 <- adolescent_overweight_36 %>% 
subset(select=-c(
  statistic, df, dfcom, fmi, lambda, riv, ubar, m, b)) 

# Test dose-dependent association between Activity - Chronological age

fit <- with(imputed_data, lm(ConventionalAge60 ~ as.factor(activecategory)  +
                               chsc + sc1553 + Sex_F + Age60))

activity_dose <- pool(fit)

activity_dose <- tidy(activity_dose, conf.int=T)

activity_dose <- activity_dose[2:5,]

activity_dose <- activity_dose %>% subset(
  select=-c(statistic, df, dfcom, fmi, 
            lambda, riv, ubar, m, b)) 

# Adversity components & accelerated ageing

fit <- with(imputed_data, lm(ConventionalAge60 ~ CROW15y + 
                               amenities + childSES + phy16 +
                               finance36 + employed36 + amenities26 + crow26 + 
                               work4353 + work36 + finance4353 + housecondition43 +
                               work63 + finance63 + matsep + divorce16 + 
                               peers + social36 + divorce36 + support4353 + 
                               lostcontact4353 + chdconflict4353 + divorce4353 + social4353 + 
                               support63 + lostcontact63 + chdconflict63 + 
                               divorce63 + social63 + Sex_F + Age60))

adversity_multivariable <- pool(fit)

adversity_multivariable <- tidy(adversity_multivariable)

adversity_multivariable <- adversity_multivariable %>% subset(select=-c(statistic, df, dfcom, fmi, lambda, riv, ubar, m, b)) 

# Stopping smoking & ageing

fit <- with(imputed_data, lm(ConventionalAge60 ~ as.factor(stopstatus) 
                             + chsc + sc1553 + Sex_F + Age60))

pooled_smok <- pool(fit)

pooled_smok <- tidy(pooled_smok, conf.int=T)

pooled_smok <- pooled_smok[2:5,]

pooled_smok <- pooled_smok %>% subset(
  select=-c(statistic, df, dfcom, fmi, 
            lambda, riv, ubar, m, b)) 

# Education group & ageing

fit <- with(imputed_data, lm(ConventionalAge60 ~ as.factor(educat) 
                             + chsc + Sex_F + Age60))

edu_pooled <- pool(fit)

edu_pooled <- tidy(edu_pooled, conf.int=T)

edu_pooled <- edu_pooled[2:5,]

edu_pooled <- edu_pooled %>% subset(
  select=-c(statistic, df, dfcom, fmi, 
            lambda, riv, ubar, m, b))

# Education results sex stratified

fit <- with(imputed_data, lm(ConventionalAge60 ~ as.factor(educat) 
                             + chsc+ Age60, subset = Sex_F == 0))

edu_men <- pool(fit)

edu_men <- tidy(edu_men, conf.int=T)

edu_men <- edu_men[2:5,]

edu_men <- edu_men %>% subset(
  select=-c(statistic, df, dfcom, fmi, 
            lambda, riv, ubar, m, b))

fit <- with(imputed_data, lm(ConventionalAge60 ~ as.factor(educat) 
                             + chsc+ Age60, subset = Sex_F == 1))

edu_women <- pool(fit)

edu_women <- tidy(edu_women, conf.int=T)

edu_women <- edu_women[2:5,]

edu_women <- edu_women %>% subset(
  select=-c(statistic, df, dfcom, fmi, 
            lambda, riv, ubar, m, b))

# Education categories sex stratified

edu_n_men <- lapply(imp_list, function(df){
  df %>% filter(Sex_F==0) %>%
    count(educat) %>%
    rename(value = educat, count=n)
})

edu_n_men <- bind_rows(edu_n_men, .id="m")

edu_n_men <- edu_n_men %>%
  group_by(value) %>%
  summarise(meancount = mean(count))

edu_n_women <- lapply(imp_list, function(df){
  df %>% filter(Sex_F==1) %>%
    count(educat) %>%
    rename(value = educat, count=n)
})

edu_n_women <- bind_rows(edu_n_women, .id="m")

edu_n_women <- edu_n_women %>%
  group_by(value) %>%
  summarise(meancount = mean(count))

# Alcohol & social advantage

edu_tabs <- with(imputed_data, 
                prop.table(table(ntile(alcohol_intake, 5), obtained_gcse), 1)
                )

alc_edu <- as.data.frame(Reduce("+", edu_tabs$analyses) / length(edu_tabs$analyses))

alc_edu <- alc_edu %>%
  rename(
    alcohol_intake = Var1
  ) %>%
  arrange(alcohol_intake, obtained_gcse)

prof_tabs <- with(imputed_data, 
                 prop.table(table(ntile(alcohol_intake, 5), prof), 1)
)

alc_prof <- as.data.frame(Reduce("+", prof_tabs$analyses) / length(prof_tabs$analyses))

alc_prof <- alc_prof %>%
  rename(
    alcohol_intake = Var1
  ) %>%
  arrange(alcohol_intake, prof)

cog_tabs <- with(imputed_data, 
                  prop.table(table(ntile(alcohol_intake, 5), ntile(cogchild, 3)), 1)
)

alc_cog <- as.data.frame(Reduce("+", cog_tabs$analyses) / length(cog_tabs$analyses))

alc_cog <- alc_cog %>%
  rename(
    alcohol_intake = Var1,
    cogchild = Var2
  ) %>%
  arrange(alcohol_intake, cogchild)

# Alcohol & selection

dataset_all$prot <- ifelse(!is.na(dataset_all$BrainAge60), 1, 0)

sel_36 <- glm(prot ~ I(avalc82u>0) + sex, data = dataset_all)

sel_36 <- tidy(sel_36, conf.int = T)

sel_36 <- sel_36[2, ]

sel_43 <- glm(prot ~ I(avalc89u>0) + sex, data = dataset_all)

sel_43 <- tidy(sel_43, conf.int = T)

sel_43 <- sel_43[2, ]

sel_53 <- glm(prot ~ I(avalc99u>0) + sex, data = dataset_all)

sel_53 <- tidy(sel_53, conf.int = T)

sel_53 <- sel_53[2, ]

alc_sel <- rbind(sel_36, sel_43, sel_53)

alc_sel$or <- exp(alc_sel$estimate)
alc_sel$lci <- exp(alc_sel$conf.low)
alc_sel$uci <- exp(alc_sel$conf.high)

# Stopping alcohol & brain age

stop <- lapply(imp_list, function(df){
  df %>%
    mutate(
      stopped = ifelse((wt82bciav + wt82wnav + wt82spiav > 0 |
                          wt89bciav + wt89wnav + wt89spiav > 0) &
                         wt09bciav + wt09wnav + wt09spiav == 0, 1, 0)
    ) %>%
    mutate(
      persistent = ifelse((wt82bciav + wt82wnav + wt82spiav > 0 |
                wt89bciav + wt89wnav + wt89spiav > 0) &
               wt09bciav + wt09wnav + wt09spiav > 0, 1, 0)
    ) %>%
    mutate(
      s_p = ifelse(stopped == 1, 1,
            ifelse(persistent == 1, 0, NA)
            ) 
    )
}
)

fits <- lapply(stop, function(df){
  glm(BrainAge60 ~ s_p + Sex_F + Age60, data = df)
})

pooled <- pool_mi(qhat=lapply(fits, coef), u=lapply(fits,vcov))

alc_stop <- summary(pooled)
alc_stop <- alc_stop[2,]

fits <- lapply(stop, function(df){
  lm(BrainAge60 ~ s_p + Sex_F + Age60, data = df, subset = disease == 1)
})

pooled <- pool_mi(qhat=lapply(fits, coef), u=lapply(fits,vcov))

stop_dis <- summary(pooled)
stop_dis <- stop_dis[2,]

fits <- lapply(stop, function(df){
  lm(BrainAge60 ~ s_p + Sex_F + Age60, data = df, subset = disease == 0)
})

pooled <- pool_mi(qhat=lapply(fits, coef), u=lapply(fits,vcov))

stop_heal <- summary(pooled)
stop_heal <- stop_heal[2,]

alc_stop_dis <- rbind(alc_stop, stop_dis, stop_heal)

#### PROTECTIVE FACTORS (PFC) ANALYSES ####

# Protective factor distributions

imp_list <- complete(imputed_data, "all")

pfs_count_list <- lapply(imp_list, function(df){
  df %>% count(protectivefactors_grouped_new) %>%
    rename(value = protectivefactors_grouped_new, count=n)
})

pfs_count_df <- bind_rows(pfs_count_list, .id="m")

pf_averagedvalues <- pfs_count_df %>%
group_by(value) %>%
summarise(meancount = mean(count))

pf_averagedvalues <- pf_averagedvalues %>%
rename(pfs_score = value, 
mean_n_across_imputations=meancount)

# Conventional ageing risk

fit <- with(imputed_data, glm(
ConventionalAge60high ~ as.factor(protectivefactors_grouped_new) + 
Sex_F + Age60, family="binomial"))

pfc_Conv <- pool(fit)

pfc_Conv <- tidy(pfc_Conv, conf.int=TRUE, conf.level=0.95)

pfc_Conv <-  pfc_Conv %>%
mutate(term=ifelse(
term=="as.factor(protectivefactors_grouped)4","4 protective factors",term))
pfc_Conv <-  pfc_Conv %>%
mutate(term=ifelse(
term=="as.factor(protectivefactors_grouped)5","5 protective factors",term))
pfc_Conv <-  pfc_Conv %>%
mutate(term=ifelse(
term=="as.factor(protectivefactors_grouped)6","6 protective factors",term))
pfc_Conv <-  pfc_Conv %>%
mutate(term=ifelse(
term=="as.factor(protectivefactors_grouped)7",
"7 or more protective factors",term))

pfc_Conv$hr <- exp(pfc_Conv$estimate)

pfc_Conv$lower_ci <- exp(pfc_Conv$conf.low)

pfc_Conv$upper_ci <- exp(pfc_Conv$conf.high)

pfc_Conv <- pfc_Conv %>% subset(select=-c(
b, df, dfcom, fmi, lambda, m, riv, ubar, conf.low, conf.high))

pfc_Conv <- pfc_Conv[-1,]

# Mutli-organ extreme ageing risk 

fit <- with(imputed_data, glm(
multiorganageing ~ 
as.factor(protectivefactors_grouped_new) + Sex_F + Age60, family="binomial"))

pfc_multi <- pool(fit)

pfc_multi <- tidy(pfc_multi, conf.int=TRUE, conf.level=0.95)

pfc_multi <-  pfc_multi %>%
mutate(term=ifelse(
term=="as.factor(protectivefactors_grouped)4",
"4 protective factors",term))
pfc_multi <-  pfc_multi %>%
mutate(term=ifelse(
term=="as.factor(protectivefactors_grouped)5",
"5 protective factors",term))
pfc_multi <-  pfc_multi %>%
mutate(term=ifelse(
term=="as.factor(protectivefactors_grouped)6",
"6 protective factors",term))
pfc_multi <-  pfc_multi %>%
mutate(term=ifelse(term=="as.factor(protectivefactors_grouped)7",
"7 or more protective factors",term))

pfc_multi$hr <- exp(pfc_multi$estimate)

pfc_multi$lower_ci <- exp(pfc_multi$conf.low)

pfc_multi$upper_ci <- exp(pfc_multi$conf.high)

pfc_multi <- pfc_multi %>% subset(
select=-c(b, df, dfcom, fmi, lambda, m, riv, ubar, conf.low, conf.high))

pfc_multi <- pfc_multi[-1,]

# Protective factor multivariable models

model_conv <- with(imputed_data, glm(
ConventionalAge60high ~ 
normal_birthweight + high_ses + 
obtained_gcse + normal_adolescent_bmi + non_smoker + 
  active + no_adversity + Sex_F + Age60, 
family="binomial"))

pooled_conv <- pool(model_conv)

pooled_conv <- tidy(pooled_conv)

pooled_conv <- pooled_conv %>% subset(
select=-c(statistic, df, dfcom, fmi, lambda, riv, ubar, m, b)) 

model_multiorgan <- with(imputed_data, glm(
multiorganageing ~ 
normal_birthweight + high_ses + 
obtained_gcse + normal_adolescent_bmi + non_smoker +
active + no_adversity + Sex_F + Age60, 
family="binomial"))

pooled_multiorgan <- pool(model_multiorgan)

pooled_multiorgan <- tidy(pooled_multiorgan)

pooled_multiorgan <- pooled_multiorgan %>% subset(
select=-c(statistic, df, dfcom, fmi, lambda, riv, ubar, m, b)) 

# Protective factors & mortality

pfc_mort <- with(imputed_data, glm(
death ~ protectivefactors_new + Sex_F + Age60, 
family="binomial"))

pfc_mort <- pool(pfc_mort)
pfc_mort_tidy <- tidy(pfc_mort)

pfc_mort_tidy$oddsratio <- exp(pfc_mort_tidy$estimate)
pfc_mort_tidy <- as.data.frame(pfc_mort_tidy)

r <- with(imputed_data, mean(multiorganageing[protectivefactors_grouped_new==7]))

mean(unlist(r$analyses))

# Protective factors & AVOS

fit <- with(imputed_data, lm(
  scale(avos) ~ 
    as.factor(protectivefactors_grouped_new) + Sex_F + Age60))

pfc_avos <- pool(fit)

pfc_avos <- tidy(pfc_avos, conf.int=TRUE, conf.level=0.95)

pfc_avos <-  pfc_avos %>%
  mutate(term=ifelse(
    term=="as.factor(protectivefactors_grouped)4",
    "4 protective factors",term))
pfc_avos <-  pfc_avos %>%
  mutate(term=ifelse(
    term=="as.factor(protectivefactors_grouped)5",
    "5 protective factors",term))
pfc_avos <-  pfc_avos %>%
  mutate(term=ifelse(
    term=="as.factor(protectivefactors_grouped)6",
    "6 protective factors",term))
pfc_avos <-  pfc_avos %>%
  mutate(term=ifelse(term=="as.factor(protectivefactors_grouped)7",
                     "7 or more protective factors",term))

pfc_avos$hr <- exp(pfc_avos$estimate)

pfc_avos$lower_ci <- exp(pfc_avos$conf.low)

pfc_avos$upper_ci <- exp(pfc_avos$conf.high)

pfc_avos <- pfc_avos %>% subset(
  select=-c(b, df, dfcom, fmi, lambda, m, riv, ubar, conf.low, conf.high))

pfc_avos <- pfc_avos[-1,]

#### MEDIATION ANALYSES ####

# Separate mediation analysis (~ 25 minutes to run)

pool_scalar_rubin <- function(qhat, uhat, conf.level = 0.95) {
  m <- length(qhat)
  
  qbar <- mean(qhat, na.rm = TRUE)
  ubar <- mean(uhat, na.rm = TRUE)
  b <- var(qhat, na.rm = TRUE)
  tvar <- ubar + (1 + 1/m) * b
  se <- sqrt(tvar)
  
  if (is.na(b) || b < .Machine$double.eps) {
    df <- Inf
  } else {
    df <- (m - 1) * (1 + ubar / ((1 + 1/m) * b))^2
  }
  
  alpha <- 1 - conf.level
  crit <- if (is.infinite(df)) qnorm(1 - alpha/2) else qt(1 - alpha/2, df)
  
  lci <- qbar - crit * se
  uci <- qbar + crit * se
  
  p <- if (is.infinite(df)) {
    2 * (1 - pnorm(abs(qbar / se)))
  } else {
    2 * (1 - pt(abs(qbar / se), df = df))
  }
  
  data.frame(
    estimate = qbar,
    se = se,
    lci = lci,
    uci = uci,
    p = p,
    stringsAsFactors = FALSE
  )
}

mediators <- c("BrainAge60", "HeartAge60",
               "LungAge60", "LiverAge60", "KidneyAge60",
               "ImmuneAge60", "ArteryAge60")

pooled_results <- lapply(mediators, function(med) {
  
  message("Running:", med)
  
  med_list <- lapply(imp_list, function(data) {
    
    fit_m <- lm(as.formula(paste(med, "~ protectivefactors_new + Sex_F + Age60")),
                data = data)
    
    fit_y <- glm(as.formula(paste("death ~", med,
                                  "+ protectivefactors_new + Sex_F + Age60")),
                 data = data, family = "binomial")
    
    mediate(fit_m, fit_y,
            treat = "protectivefactors_new",
            mediator = med,
            sims = 1000)
  })
  
  acme_est <- sapply(med_list, function(x) x$d.avg)
  ade_est  <- sapply(med_list, function(x) x$z.avg)
  te_est   <- sapply(med_list, function(x) x$tau.coef)
  
  acme_var <- sapply(med_list, function(x)
    var(as.numeric(unlist(x$d.avg.sims)), na.rm = TRUE))
  
  ade_var <- sapply(med_list, function(x)
    var(as.numeric(unlist(x$z.avg.sims)), na.rm = TRUE))
  
  te_var <- sapply(med_list, function(x)
    var(as.numeric(unlist(x$tau.sims)), na.rm = TRUE))
  
  acme_pool <- pool_scalar_rubin(acme_est, acme_var, conf.level = 0.95)
  ade_pool  <- pool_scalar_rubin(ade_est,  ade_var,  conf.level = 0.95)
  te_pool   <- pool_scalar_rubin(te_est,   te_var,   conf.level = 0.95)
  
  pm_est <- acme_pool$estimate / te_pool$estimate
  
  wide <- data.frame(
    organ = med,
    
    ACME_estimate = acme_pool$estimate,
    ACME_se = acme_pool$se,
    ACME_p = acme_pool$p,
    ACME_lci = acme_pool$lci,
    ACME_uci = acme_pool$uci,
    
    ADE_estimate = ade_pool$estimate,
    ADE_se = ade_pool$se,
    ADE_p = ade_pool$p,
    ADE_lci = ade_pool$lci,
    ADE_uci = ade_pool$uci,
    
    TE_estimate = te_pool$estimate,
    TE_se = te_pool$se,
    TE_p = te_pool$p,
    TE_lci = te_pool$lci,
    TE_uci = te_pool$uci,
    
    PM_estimate = pm_est
  )
  
  wide
})

pooled_results_df <- do.call(rbind, pooled_results)

# Joint mediation analysis

  dat_list <- complete(imputed_data, action = "all")  # list length = m
  
  dat_list <- lapply(dat_list, function(d) {
    d$protect <- as.numeric(as.character(d$protectivefactors_new))
    d
  })
  
  m <- length(dat_list)
  
  mods <- vector("list", m)
  
  for (i in seq_len(m)) {
    
    d <- dat_list[[i]]
    
    med_model <- glm(
      death ~ protect + LiverAge60 + LungAge60 + BrainAge60 +
        ImmuneAge60 + HeartAge60 + KidneyAge60 + ArteryAge60 +
        Age60 + Sex_F,
      family = binomial(),
      data = d
    )
    
    expData <- neImpute(med_model, nMed = 6, data = d)
    
    mods[[i]] <- neModel(
      death ~ protect0 + protect1 + Age60 + Sex_F,
      family = binomial(),
      expData = expData
    )
  }
  
  coef_mat <- do.call(rbind, lapply(mods, coef))
  var_mat  <- do.call(rbind, lapply(mods, function(x) diag(vcov(x))))
  
  Qbar <- colMeans(coef_mat)
  Ubar <- colMeans(var_mat)
  B    <- apply(coef_mat, 2, var)
  Tvar <- Ubar + (1 + 1/m) * B
  SE   <- sqrt(Tvar)
  
  joint_results_df <- data.frame(
    term = names(Qbar),
    estimate = Qbar,
    SE = SE,
    lower = Qbar - 1.96 * SE,
    upper = Qbar + 1.96 * SE,
    OR = exp(Qbar),
    OR_lower = exp(Qbar - 1.96 * SE),
    OR_upper = exp(Qbar + 1.96 * SE),
    row.names = NULL
  )
  
  # Leave-one-out mediation: Brain
  
  dat_list <- complete(imputed_data, action = "all")  # list length = m
  
  dat_list <- lapply(dat_list, function(d) {
    d$protect <- as.numeric(as.character(d$protectivefactors_new))
    d
  })
  
  m <- length(dat_list)
  
  mods <- vector("list", m)
  
  for (i in seq_len(m)) {
    
    d <- dat_list[[i]]
    
    med_model <- glm(
      death ~ protect + LiverAge60 + LungAge60 + HeartAge60 +
        ImmuneAge60 + KidneyAge60 + ArteryAge60 +
        Age60 + Sex_F,
      family = binomial(),
      data = d
    )
    
    expData <- neImpute(med_model, nMed = 6, data = d)
    
    mods[[i]] <- neModel(
      death ~ protect0 + protect1 + Age60 + Sex_F,
      family = binomial(),
      expData = expData
    )
  }
  
  coef_mat <- do.call(rbind, lapply(mods, coef))
  var_mat  <- do.call(rbind, lapply(mods, function(x) diag(vcov(x))))
  
  Qbar <- colMeans(coef_mat)
  Ubar <- colMeans(var_mat)
  B    <- apply(coef_mat, 2, var)
  Tvar <- Ubar + (1 + 1/m) * B
  SE   <- sqrt(Tvar)
  
  brain_results_df <- data.frame(
    term = names(Qbar),
    estimate = Qbar,
    SE = SE,
    lower = Qbar - 1.96 * SE,
    upper = Qbar + 1.96 * SE,
    OR = exp(Qbar),
    OR_lower = exp(Qbar - 1.96 * SE),
    OR_upper = exp(Qbar + 1.96 * SE),
    row.names = NULL
  )
  
# Leave-one-out mediation: Heart

  dat_list <- complete(imputed_data, action = "all")  # list length = m
  
  dat_list <- lapply(dat_list, function(d) {
    d$protect <- as.numeric(as.character(d$protectivefactors_new))
    d
  })
  
  m <- length(dat_list)
  
  mods <- vector("list", m)
  
  for (i in seq_len(m)) {
    
    d <- dat_list[[i]]
    
    med_model <- glm(
      death ~ protect + LiverAge60 + LungAge60 + BrainAge60 +
        ImmuneAge60 + KidneyAge60 + ArteryAge60 +
        Age60 + Sex_F,
      family = binomial(),
      data = d
    )
    
    expData <- neImpute(med_model, nMed = 6, data = d)
    
    mods[[i]] <- neModel(
      death ~ protect0 + protect1 + Age60 + Sex_F,
      family = binomial(),
      expData = expData
    )
  }
  
  coef_mat <- do.call(rbind, lapply(mods, coef))
  var_mat  <- do.call(rbind, lapply(mods, function(x) diag(vcov(x))))
  
  Qbar <- colMeans(coef_mat)
  Ubar <- colMeans(var_mat)
  B    <- apply(coef_mat, 2, var)
  Tvar <- Ubar + (1 + 1/m) * B
  SE   <- sqrt(Tvar)
  
  heart_results_df <- data.frame(
    term = names(Qbar),
    estimate = Qbar,
    SE = SE,
    lower = Qbar - 1.96 * SE,
    upper = Qbar + 1.96 * SE,
    OR = exp(Qbar),
    OR_lower = exp(Qbar - 1.96 * SE),
    OR_upper = exp(Qbar + 1.96 * SE),
    row.names = NULL
  )

  # Leave-one-out mediation: Lung
  
  dat_list <- complete(imputed_data, action = "all")  # list length = m
  
  dat_list <- lapply(dat_list, function(d) {
    d$protect <- as.numeric(as.character(d$protectivefactors_new))
    d
  })
  
  m <- length(dat_list)
  
  mods <- vector("list", m)
  
  for (i in seq_len(m)) {
    
    d <- dat_list[[i]]
    
    med_model <- glm(
      death ~ protect + LiverAge60 + HeartAge60 + BrainAge60 +
        ImmuneAge60 + KidneyAge60 + ArteryAge60 +
        Age60 + Sex_F,
      family = binomial(),
      data = d
    )
    
    expData <- neImpute(med_model, nMed = 6, data = d)
    
    mods[[i]] <- neModel(
      death ~ protect0 + protect1 + Age60 + Sex_F,
      family = binomial(),
      expData = expData
    )
  }
  
  coef_mat <- do.call(rbind, lapply(mods, coef))
  var_mat  <- do.call(rbind, lapply(mods, function(x) diag(vcov(x))))
  
  Qbar <- colMeans(coef_mat)
  Ubar <- colMeans(var_mat)
  B    <- apply(coef_mat, 2, var)
  Tvar <- Ubar + (1 + 1/m) * B
  SE   <- sqrt(Tvar)
  
  lung_results_df <- data.frame(
    term = names(Qbar),
    estimate = Qbar,
    SE = SE,
    lower = Qbar - 1.96 * SE,
    upper = Qbar + 1.96 * SE,
    OR = exp(Qbar),
    OR_lower = exp(Qbar - 1.96 * SE),
    OR_upper = exp(Qbar + 1.96 * SE),
    row.names = NULL
  )
  
  # Leave-one-out mediation: Liver
  
  dat_list <- complete(imputed_data, action = "all")  # list length = m
  
  dat_list <- lapply(dat_list, function(d) {
    d$protect <- as.numeric(as.character(d$protectivefactors_new))
    d
  })
  
  m <- length(dat_list)
  
  mods <- vector("list", m)
  
  for (i in seq_len(m)) {
    
    d <- dat_list[[i]]
    
    med_model <- glm(
      death ~ protect + LungAge60 + HeartAge60 + BrainAge60 +
        ImmuneAge60 + KidneyAge60 + ArteryAge60 +
        Age60 + Sex_F,
      family = binomial(),
      data = d
    )
    
    expData <- neImpute(med_model, nMed = 6, data = d)
    
    mods[[i]] <- neModel(
      death ~ protect0 + protect1 + Age60 + Sex_F,
      family = binomial(),
      expData = expData
    )
  }
  
  coef_mat <- do.call(rbind, lapply(mods, coef))
  var_mat  <- do.call(rbind, lapply(mods, function(x) diag(vcov(x))))
  
  Qbar <- colMeans(coef_mat)
  Ubar <- colMeans(var_mat)
  B    <- apply(coef_mat, 2, var)
  Tvar <- Ubar + (1 + 1/m) * B
  SE   <- sqrt(Tvar)
  
  liver_results_df <- data.frame(
    term = names(Qbar),
    estimate = Qbar,
    SE = SE,
    lower = Qbar - 1.96 * SE,
    upper = Qbar + 1.96 * SE,
    OR = exp(Qbar),
    OR_lower = exp(Qbar - 1.96 * SE),
    OR_upper = exp(Qbar + 1.96 * SE),
    row.names = NULL
  )
  
  # Leave-one-out mediation: Kidney
  
  dat_list <- complete(imputed_data, action = "all")  # list length = m
  
  dat_list <- lapply(dat_list, function(d) {
    d$protect <- as.numeric(as.character(d$protectivefactors_new))
    d
  })
  
  m <- length(dat_list)
  
  mods <- vector("list", m)
  
  for (i in seq_len(m)) {
    
    d <- dat_list[[i]]
    
    med_model <- glm(
      death ~ protect + LungAge60 + HeartAge60 + BrainAge60 +
        ImmuneAge60 + LiverAge60 + ArteryAge60 +
        Age60 + Sex_F,
      family = binomial(),
      data = d
    )
    
    expData <- neImpute(med_model, nMed = 6, data = d)
    
    mods[[i]] <- neModel(
      death ~ protect0 + protect1 + Age60 + Sex_F,
      family = binomial(),
      expData = expData
    )
  }
  
  coef_mat <- do.call(rbind, lapply(mods, coef))
  var_mat  <- do.call(rbind, lapply(mods, function(x) diag(vcov(x))))
  
  Qbar <- colMeans(coef_mat)
  Ubar <- colMeans(var_mat)
  B    <- apply(coef_mat, 2, var)
  Tvar <- Ubar + (1 + 1/m) * B
  SE   <- sqrt(Tvar)
  
  kidney_results_df <- data.frame(
    term = names(Qbar),
    estimate = Qbar,
    SE = SE,
    lower = Qbar - 1.96 * SE,
    upper = Qbar + 1.96 * SE,
    OR = exp(Qbar),
    OR_lower = exp(Qbar - 1.96 * SE),
    OR_upper = exp(Qbar + 1.96 * SE),
    row.names = NULL
  )
  
  # Leave-one-out mediation: Immune
  
  dat_list <- complete(imputed_data, action = "all")  # list length = m
  
  dat_list <- lapply(dat_list, function(d) {
    d$protect <- as.numeric(as.character(d$protectivefactors_new))
    d
  })
  
  m <- length(dat_list)
  
  mods <- vector("list", m)
  
  for (i in seq_len(m)) {
    
    d <- dat_list[[i]]
    
    med_model <- glm(
      death ~ protect + LungAge60 + HeartAge60 + BrainAge60 +
        KidneyAge60 + LiverAge60 + ArteryAge60 +
        Age60 + Sex_F,
      family = binomial(),
      data = d
    )
    
    expData <- neImpute(med_model, nMed = 6, data = d)
    
    mods[[i]] <- neModel(
      death ~ protect0 + protect1 + Age60 + Sex_F,
      family = binomial(),
      expData = expData
    )
  }
  
  coef_mat <- do.call(rbind, lapply(mods, coef))
  var_mat  <- do.call(rbind, lapply(mods, function(x) diag(vcov(x))))
  
  Qbar <- colMeans(coef_mat)
  Ubar <- colMeans(var_mat)
  B    <- apply(coef_mat, 2, var)
  Tvar <- Ubar + (1 + 1/m) * B
  SE   <- sqrt(Tvar)
  
  immune_results_df <- data.frame(
    term = names(Qbar),
    estimate = Qbar,
    SE = SE,
    lower = Qbar - 1.96 * SE,
    upper = Qbar + 1.96 * SE,
    OR = exp(Qbar),
    OR_lower = exp(Qbar - 1.96 * SE),
    OR_upper = exp(Qbar + 1.96 * SE),
    row.names = NULL
  )

  # Leave-one-out mediation: Artery
  
  dat_list <- complete(imputed_data, action = "all")  # list length = m
  
  dat_list <- lapply(dat_list, function(d) {
    d$protect <- as.numeric(as.character(d$protectivefactors_new))
    d
  })
  
  m <- length(dat_list)
  
  mods <- vector("list", m)
  
  for (i in seq_len(m)) {
    
    d <- dat_list[[i]]
    
    med_model <- glm(
      death ~ protect + LungAge60 + HeartAge60 + BrainAge60 +
        KidneyAge60 + LiverAge60 + ImmuneAge60 +
        Age60 + Sex_F,
      family = binomial(),
      data = d
    )
    
    expData <- neImpute(med_model, nMed = 6, data = d)
    
    mods[[i]] <- neModel(
      death ~ protect0 + protect1 + Age60 + Sex_F,
      family = binomial(),
      expData = expData
    )
  }
  
  coef_mat <- do.call(rbind, lapply(mods, coef))
  var_mat  <- do.call(rbind, lapply(mods, function(x) diag(vcov(x))))
  
  Qbar <- colMeans(coef_mat)
  Ubar <- colMeans(var_mat)
  B    <- apply(coef_mat, 2, var)
  Tvar <- Ubar + (1 + 1/m) * B
  SE   <- sqrt(Tvar)
  
  artery_results_df <- data.frame(
    term = names(Qbar),
    estimate = Qbar,
    SE = SE,
    lower = Qbar - 1.96 * SE,
    upper = Qbar + 1.96 * SE,
    OR = exp(Qbar),
    OR_lower = exp(Qbar - 1.96 * SE),
    OR_upper = exp(Qbar + 1.96 * SE),
    row.names = NULL
  )
  
med_joint <- joint_results_df[3, ] 
med_joint$term <- "joint"
  
med_brain <- brain_results_df[3, ] 
med_brain$term <- "brain"

med_heart <- heart_results_df[3, ] 
med_heart$term <- "heart"

med_lung <- lung_results_df[3, ] 
med_lung$term <- "lung"

med_liver <- liver_results_df[3, ] 
med_liver$term <- "liver"

med_kidney <- kidney_results_df[3, ] 
med_kidney$term <- "kidney"

med_immune <- immune_results_df[3, ] 
med_immune$term <- "immune"

med_artery <- artery_results_df[3, ] 
med_artery$term <- "artery"

med_cross <- rbind(med_joint, med_brain, med_heart, med_lung,
                   med_liver, med_kidney, med_immune, med_artery)

full_indirect <- med_joint$estimate

med_cross$prop_drop <- (full_indirect - med_cross$estimate) / full_indirect
  
# AVOS & mediation

  mediators <- c("avos")
  
  avos_results_df <- lapply(mediators, function(med) {
    
    message("Running:", med)
    
    med_list <- lapply(imp_list, function(data) {
      
      fit_m <- lm(as.formula(paste(med, "~ protectivefactors_new + Sex_F + Age600")), 
                  data = data)
      
      fit_y <- glm(as.formula(paste("death ~", med, 
                                    "+ protectivefactors_new + Sex_F + Age60")),
                   data = data, family = "binomial")
      
      mediate(fit_m, fit_y,
              treat    = "protectivefactors_new",
              mediator = med,
              sims     = 1000)
    })
    
    acme_est <- sapply(med_list, function(x) x$d.avg)
    ade_est  <- sapply(med_list, function(x) x$z.avg)
    te_est   <- sapply(med_list, function(x) x$tau.coef)
    pm_est <- sapply(med_list, function(x) {
      r <- as.numeric(unlist(x$d.avg.sims)) / as.numeric(unlist(x$tau.sims))
      mean(r)})
    
    m <- length(med_list)
    
    ests <- lapply(seq_len(m), function(i)
      c(ACME=acme_est[i], ADE=ade_est[i], TE=te_est[i], PM=pm_est[i]))
    
    vars <- lapply(seq_len(m), function(i){
      x <- med_list[[i]]
      ACME=as.numeric(unlist(x$d.avg.sims))
      ADE=as.numeric(unlist(x$z.avg.sims)) 
      TE=as.numeric(unlist(x$tau.sims))
      PM=ACME/TE
      cov(cbind(ACME=ACME, ADE=ADE, TE=TE, PM=PM), use="complete.obs")
    })
    
    out <- testEstimates(qhat=ests, uhat=vars, conf.level=0.95)
    
    all <- out$estimates %>%
      as.data.frame() %>%
      rownames_to_column("term") %>%
      mutate(term = sub("\\..*", "", term),
             lci = Estimate - qt(.975, df) * `Std.Error`,
             uci = Estimate + qt(.975, df) * `Std.Error`,
             p   = `P(>|t|)`) %>%
      dplyr::select(term, estimate = Estimate, se = `Std.Error`, p, lci, uci)
    
    wide <- all %>%
      pivot_wider(names_from = term, 
                  values_from = c(estimate, se, p, lci, uci),
                  names_glue = "{term}_{.value}") %>%
      mutate(organ=med, .before=1)
    
    wide
    
  })
  
  avos_results_df <- as.data.frame(avos_results_df)

#### PROTEIN LEVEL ANALYSIS ####

# Add protein level data

prot <- read.csv(file.path(inp,"proteomics_final.csv"))

prot <- prot %>% rename(id=ID)

prot_log = prot %>% mutate(across(-1, ~log10(.)))

prot_norm = prot_log %>% mutate(across(-1, ~scale(.)[,1]))

imp_prot <- lapply(imp_list, function(df) {
  merge(df, prot_norm, by="id")
})

imp_p <- as.mitml.list(imp_prot)

# Add protein metadata

prot_metadata <- read_xlsx(file.path(inp, "3.6 SL00000906_SomaScan_11K_v5.0_Plasma_Serum_Annotated_Menu.xlsx"))

colnames(prot_metadata) <- as.character(prot_metadata[4,])

prot_metadata <- prot_metadata[-(1:4),]

prot_metadata$SeqId <- paste0("X", gsub("-",".",prot_metadata$SeqId))

prot_metadata <- prot_metadata %>% 
  subset(select=c("SeqId", "SomaId", "Target Full Name", 
                  "UniProt ID", "Entrez Gene Name"
                  ))

coef <- read_xlsx(file.path(inp, "organ_clock_coef.xlsx"))

soma_seqid <- read_xlsx(file.path(inp, "Somamer_seqids_match.xlsx"))

clock_coef <- merge(soma_seqid, coef, by="Somamer")

clock_coef <- clock_coef %>% subset(select=-c(Somamer))

clock_coef$SeqId <- paste0("X", gsub("-",".",clock_coef$SeqId))

prot_meta_full <- merge(prot_metadata, clock_coef, by="SeqId", all=TRUE)

brain <- prot_meta_full %>% filter(organ=="Brain")
brain_proteins <- brain$SeqId

liver <- prot_meta_full %>% filter(organ=="Liver")
liver_proteins <- liver$SeqId

immune <- prot_meta_full %>% filter(organ=="Immune")
immune_proteins <- immune$SeqId

kidney <- prot_meta_full %>% filter(organ=="Kidney")
kidney_proteins <- kidney$SeqId

# Brain-specific proteins and alcohol

results <- list()

for (protein in brain_proteins) {

formula <- as.formula(
paste0(
protein, " ~ wt82wnav + Sex_F + 
chsc + obtained_gcse + bmi09 + 
adall + active + social63 + 
lostcontact63+ work63 + 
finance63 + peers + divorce63 + Age60"))

fit <- lapply(imp_p, function(d) lm(formula, data=d))

pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))

results[[protein]] <- summary(pooled)

}

pooled_df <- bind_rows(
lapply(results, function(df) rownames_to_column(df, "term")), .id="SeqId")

pooled_df <- pooled_df %>% filter(term=="wt82wnav")

pooled_df_82 <- merge(pooled_df, prot_metadata, by="SeqId")

pooled_df_82$padj <- p.adjust(pooled_df_82$p, method="BH")

pooled_df_82$sig <- ifelse(pooled_df_82$padj<0.05,1,0)

pooled_df_82 <- 
  pooled_df_82 %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

pooled_df_82 <- pooled_df_82 %>% subset(select=c(SeqId, estimate,
se, p, ci_lower, ci_upper, SomaId, `Target Full Name`,
`UniProt ID`, `Entrez Gene Name`))

pooled_df_82 <- pooled_df_82[, c("Entrez Gene Name", "Target Full Name", 
"SeqId", "SomaId", 
"UniProt ID", "estimate", "se", 
"ci_lower", "ci_upper", "p")]

results <- list()

for (protein in brain_proteins) {
  
  formula <- as.formula(
  paste0(protein, " ~ wt89wnav + Sex_F + chsc + 
  obtained_gcse + bmi09 + adall + active + social63 + 
  lostcontact63+ work63 + finance63 + peers + divorce63 + Age60"))
  
  fit <- lapply(imp_p, function(d) lm(formula, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  results[[protein]] <- summary(pooled)
}
  
pooled_df <- bind_rows(
lapply(results, function(df) rownames_to_column(df, "term")), .id="SeqId")

pooled_df <- pooled_df %>% filter(term=="wt89wnav")

pooled_df_89 <- merge(pooled_df, prot_metadata, by="SeqId")

pooled_df_89$padj <- p.adjust(pooled_df_89$p, method="BH")

pooled_df_89$sig <- ifelse(pooled_df_89$padj<0.05,1,0)

pooled_df_89 <- 
  pooled_df_89 %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

pooled_df_89 <- pooled_df_89 %>% subset(select=c(SeqId, estimate,
                                                 se, p, ci_lower, ci_upper, SomaId, `Target Full Name`,
                                                 `UniProt ID`, `Entrez Gene Name`))

pooled_df_89 <- pooled_df_89[, c("Entrez Gene Name", "Target Full Name", 
                                 "SeqId", "SomaId", 
                                 "UniProt ID", "estimate", "se", 
                                 "ci_lower", "ci_upper", "p")]

# Age 53

results <- list()

for (protein in brain_proteins) {

  formula <- as.formula(
  paste0(protein, " ~ wt99wnav + Sex_F + chsc +
  obtained_gcse + bmi09 + adall + active + 
  social63 + lostcontact63+ work63 + finance63 + peers + 
  divorce63 + Age60"))
  
  fit <- lapply(imp_p, function(d) lm(formula, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  results[[protein]] <- summary(pooled)
}
  
pooled_df <- bind_rows(
lapply(results, function(df) rownames_to_column(df, "term")), .id="SeqId")

pooled_df <- pooled_df %>% filter(term=="wt99wnav")

pooled_df_99 <- merge(pooled_df, prot_metadata, by="SeqId")

pooled_df_99$padj <- p.adjust(pooled_df_99$p, method="BH")

pooled_df_99$sig <- ifelse(pooled_df_99$padj<0.05,1,0)

pooled_df_99 <- 
  pooled_df_99 %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

pooled_df_99 <- pooled_df_99 %>% subset(select=c(SeqId, estimate,
                                                 se, p, ci_lower, ci_upper, SomaId, `Target Full Name`,
                                                 `UniProt ID`, `Entrez Gene Name`))

pooled_df_99 <- pooled_df_99[, c("Entrez Gene Name", "Target Full Name", 
                                 "SeqId", "SomaId", 
                                 "UniProt ID", "estimate", "se", 
                                 "ci_lower", "ci_upper", "p")]
# Age 63

results <- list()

for (protein in brain_proteins) {
  
  formula <- as.formula(
    paste0(protein, " ~ wt09wnav + Sex_F + chsc + 
    obtained_gcse + bmi09 + adall + active + social63 + 
    lostcontact63+ work63 + finance63 + peers +
    divorce63 + Age60"))
  
  fit <- lapply(imp_p, function(d) lm(formula, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  results[[protein]] <- summary(pooled)
}
  
pooled_df <- bind_rows(
lapply(results, function(df) rownames_to_column(df, "term")), .id="SeqId")

pooled_df <- pooled_df %>% filter(term=="wt09wnav")

pooled_df_09 <- merge(pooled_df, prot_metadata, by="SeqId")

pooled_df_09$padj <- p.adjust(pooled_df_09$p, method="BH")

pooled_df_09$sig <- ifelse(pooled_df_09$padj<0.05,1,0)

pooled_df_09 <- 
  pooled_df_09 %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

pooled_df_09 <- pooled_df_09 %>% subset(select=c(SeqId, estimate,
                                                 se, p, ci_lower, ci_upper, SomaId, `Target Full Name`,
                                                 `UniProt ID`, `Entrez Gene Name`))

pooled_df_09 <- pooled_df_09[, c("Entrez Gene Name", "Target Full Name", 
                                 "SeqId", "SomaId", 
                                 "UniProt ID", "estimate", "se", 
                                 "ci_lower", "ci_upper", "p")]

# Overall

results <- list()

for (protein in brain_proteins) {
 
   formula <- as.formula(
    paste0(protein, " ~ alcohol_intake + Sex_F + Age60 + chsc + 
    sc1553"))
  
   fit <- lapply(imp_p, function(d) lm(formula, data=d))
   
   pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
   
   results[[protein]] <- summary(pooled)
}
  
pooled_df <- bind_rows(
lapply(results, function(df) rownames_to_column(df, "term")), .id="SeqId")

pooled_df <- pooled_df %>% filter(term=="alcohol_intake")

pooled_df_ov <- merge(pooled_df, prot_metadata, by="SeqId")

pooled_df_ov$padj <- p.adjust(pooled_df_ov$p, method="BH")

pooled_df_ov$sig <- ifelse(pooled_df_ov$padj<0.05,1,0)

pooled_df_ov <- 
  pooled_df_ov %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

pooled_df_ov <- pooled_df_ov %>% subset(select=c(SeqId, estimate,
                                                 se, p, ci_lower, ci_upper, SomaId, `Target Full Name`,
                                                 `UniProt ID`, `Entrez Gene Name`))

pooled_df_ov <- pooled_df_ov[, c("Entrez Gene Name", "Target Full Name", 
                                 "SeqId", "SomaId", 
                                 "UniProt ID", "estimate", "se", 
                                 "ci_lower", "ci_upper", "p")]

# Liver & Adolescent Overweight 

results <- list()

for (protein in liver_proteins) {
  
  formula <- as.formula(paste0(protein, " ~ adolescent_overweight + Sex_F + chsc"))
  
  fit <- lapply(imp_p, function(d) lm(formula, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  results[[protein]] <- summary(pooled)
}
  
pooled_liver_ow <- bind_rows(
lapply(results, function(df) rownames_to_column(df, "term")), .id="SeqId")

pooled_liver_ow <- pooled_liver_ow %>% filter(term=="adolescent_overweight")

pooled_liver_ow <- merge(pooled_liver_ow, prot_metadata, by="SeqId")

pooled_liver_ow$padj <- p.adjust(pooled_liver_ow$p, method="BH")

pooled_liver_ow$sig <- ifelse(pooled_liver_ow$padj<0.05,1,0)

pooled_liver_ow <- 
  pooled_liver_ow %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

pooled_liver_ow <- pooled_liver_ow %>% subset(
select=c(SeqId, estimate, se, p, ci_lower, 
ci_upper, SomaId, `Target Full Name`, 
`UniProt ID`, `Entrez Gene Name`))

pooled_liver_ow <- pooled_liver_ow[, c(
"Entrez Gene Name", "Target Full Name", "SeqId", 
"SomaId", "UniProt ID", "estimate",
"se", "ci_lower", "ci_upper", "p")]

pooled_liver_ow <- pooled_liver_ow %>% arrange(p)

# Kidney & Smoking

results <- list()

for (protein in kidney_proteins) {
  
  formula <- as.formula(
  paste0(protein, " ~ packyrs + Sex_F + chsc + sc1553"))
  
  fit <- lapply(imp_p, function(d) lm(formula, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  results[[protein]] <- summary(pooled)
}
  
pooled_kidney_sm <- bind_rows(
lapply(results, function(df) rownames_to_column(df, "term")), .id="SeqId")

pooled_kidney_sm <- pooled_kidney_sm %>% filter(term=="packyrs")

pooled_kidney_sm <- merge(pooled_kidney_sm, prot_metadata, by="SeqId")

pooled_kidney_sm$padj <- p.adjust(pooled_kidney_sm$p, method="BH")

pooled_kidney_sm$sig <- ifelse(pooled_kidney_sm$padj<0.05,1,0)

pooled_kidney_sm <- 
  pooled_kidney_sm %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

pooled_kidney_sm <- pooled_kidney_sm %>% subset(select=c(SeqId, estimate, 
se, p, ci_lower, ci_upper, SomaId, `Target Full Name`, `UniProt ID`, `Entrez Gene Name`))

pooled_kidney_sm <- pooled_kidney_sm[, c("Entrez Gene Name", "Target Full Name",
"SeqId", "SomaId", "UniProt ID", "estimate", "se", "ci_lower", "ci_upper", "p")]

pooled_kidney_sm <- pooled_kidney_sm %>% arrange(p)

# Immune & Activity

results <- list()

for (protein in immune_proteins) {
  
  formula <- as.formula(
  paste0(protein, " ~ active + Sex_F + chsc + sc1553"))
  
  fit <- lapply(imp_p, function(d) lm(formula, data=d))
  
  pooled <- pool_mi(qhat=lapply(fit, coef), u=lapply(fit,vcov))
  
  results[[protein]] <- summary(pooled)
}
  
pooled_immune_act <- bind_rows(
  lapply(results, function(df) rownames_to_column(df, "term")), .id="SeqId")

pooled_immune_act <- pooled_immune_act %>% filter(term=="active")

pooled_immune_act <- merge(pooled_immune_act, prot_metadata, by="SeqId")

pooled_immune_act$padj <- p.adjust(pooled_immune_act$p, method="BH")

pooled_immune_act$sig <- ifelse(pooled_immune_act$padj<0.05,1,0)

pooled_immune_act <- 
  pooled_immune_act %>%
  rename(
    estimate=results,
    ci_lower=`(lower`,
    ci_upper=`upper)`
  )

pooled_immune_act <- pooled_immune_act %>% subset(select=c(SeqId, estimate,
se, p, ci_lower, ci_upper, SomaId, `Target Full Name`, 
`UniProt ID`, `Entrez Gene Name`))

pooled_immune_act <- pooled_immune_act[, c("Entrez Gene Name", "Target Full Name",
"SeqId", "SomaId",
"UniProt ID", "estimate", "se", "ci_lower", "ci_upper", "p")]

pooled_immune_act <- pooled_immune_act %>% arrange(p)

#### OUTPUT FILES ####

# Aim 3 Supplementary Tables

res <- createWorkbook()

# ST17.Organ ageing & life course exposures
addWorksheet(res, "ST17.Organs & life course")
writeData(res, "ST17.Organs & life course", bwt_res, startRow=2)
writeData(res, "ST17.Organs & life course", socio_res, startRow=13)
writeData(res, "ST17.Organs & life course", gcse_res, startRow=24)
writeData(res, "ST17.Organs & life course", cbmi_res, startRow=35)
writeData(res, "ST17.Organs & life course", smoking_res, startRow=47)
writeData(res, "ST17.Organs & life course", alc_res, startRow=59)
writeData(res, "ST17.Organs & life course", act_res, startRow=71)
writeData(res, "ST17.Organs & life course", adv_res, startRow=83)

# ST18. Sex interactions for life course exposures
addWorksheet(res, "ST18.Sex interactions")
writeData(res, "ST18.Sex interactions", bwt_sex, startRow=2)
writeData(res, "ST18.Sex interactions", socio_sex, startRow=13)
writeData(res, "ST18.Sex interactions", gcse_sex, startRow=24)
writeData(res, "ST18.Sex interactions", cbmi_sex, startRow=35)
writeData(res, "ST18.Sex interactions", smoking_sex, startRow=47)
writeData(res, "ST18.Sex interactions", alc_sex, startRow=59)
writeData(res, "ST18.Sex interactions", act_sex, startRow=71)
writeData(res, "ST18.Sex interactions", adv_sex, startRow=83)

# ST18. Education
addWorksheet(res, "ST18.Education")
writeData(res, "ST18.Education", edu_pooled)
writeData(res, "ST18.Education", edu_men, startRow = 10)
writeData(res, "ST18.Education", edu_women, startRow = 20)

# ST19. Non-linearity tests
addWorksheet(res, "ST19.Non-linearity")
writeData(res, "ST19.Non-linearity", non_lin)

# ST20. Organs & exposures sensitivity
addWorksheet(res, "ST20.Exposures sensitivity")
writeData(res, "ST20.Exposures sensitivity", bwt_sens, startRow=2)
writeData(res, "ST20.Exposures sensitivity", socio_sens, startRow=13)
writeData(res, "ST20.Exposures sensitivity", gcse_sens, startRow=24)
writeData(res, "ST20.Exposures sensitivity", cbmi_sens, startRow=35)
writeData(res, "ST20.Exposures sensitivity", smoking_sens, startRow=47)
writeData(res, "ST20.Exposures sensitivity", alc_sens, startRow=59)
writeData(res, "ST20.Exposures sensitivity", act_sens, startRow=71)
writeData(res, "ST20.Exposures sensitivity", adv_sens, startRow=83)

# ST22. Adolescent overweight & liver proteins
#addWorksheet(res, "ST22.Liver proteins - ad overweight")
#writeData(res, "ST22.Liver proteins - ad overweight", pooled_liver_ow)

# ST23: Smoking & kidney proteins
#addWorksheet(res, "ST23.Kidney proteins - smoking")
#writeData(res, "ST23.Kidney proteins - smoking", pooled_kidney_sm)

# ST24: Activity & immune proteins
#addWorksheet(res, "ST24.Immune proteins - activity")
#writeData(res, "ST24.Immune proteins - activity", pooled_immune_act)

# ST26: Alcohol & social advantage
addWorksheet(res, "ST26.Alcohol & social advantage")
writeData(res, "ST26.Alcohol & social advantage", alc_edu)
writeData(res, "ST26.Alcohol & social advantage", alc_prof, startRow = 20)
writeData(res, "ST26.Alcohol & social advantage", alc_cog, startRow = 40)

# ST27: Alcohol & selection
addWorksheet(res, "ST27.Alcohol & selection")
writeData(res, "ST27.Alcohol & selection", alc_sel)

# ST28: Alcohol & stopping
addWorksheet(res, "ST28.Alcohol & stopping")
writeData(res, "ST28.Alcohol & stopping", alc_stop_dis)

# ST30: Alcohol & brain proteins
#addWorksheet(res, "ST30.Brain proteins - alcohol")
#writeData(res, "ST30.Brain proteins - alcohol", pooled_df_82, startRow=2, startCol=1)
#writeData(res, "ST30.Brain proteins - alcohol", pooled_df_89, startRow=2, startCol=12)
#writeData(res, "ST30.Brain proteins - alcohol", pooled_df_99, startRow=2, startCol=17)
#writeData(res, "ST30.Brain proteins - alcohol", pooled_df_09, startRow=2, startCol=22)
#writeData(res, "ST30.Brain proteins - alcohol", pooled_df_ov, startRow=2, startCol=27)

# ST32: AVOS & life course exposures
addWorksheet(res, "ST32.AVOS & life course")
writeData(res, "ST32.AVOS & life course", lc_avos)

# ST33: PFC distributions
addWorksheet(res, "ST33.PFC distributions")
writeData(res, "ST33.PFC distributions", pf_averagedvalues)

# ST34: Extreme ageing & PFS
addWorksheet(res, "ST34.PFC risk for ageing")
writeData(res, "ST34.PFC risk for ageing", pfc_Conv)
writeData(res, "ST34.PFC risk for ageing", pfc_multi, startRow = 10)

# ST35: AVOS & PFC
addWorksheet(res, "ST35.AVOS & PFC")
writeData(res, "ST35.AVOS & PFC", pfc_avos)

# ST36: Separate organ mediation
addWorksheet(res, "Seperate organ mediation")
writeData(res, "Seperate organ mediation", pooled_results_df)

# ST37: Joint organ mediation
addWorksheet(res, "ST37.Joint organ mediation")
writeData(res, "ST37.Joint organ mediation", med_cross)

# ST39: AVOS mediation
addWorksheet(res, "ST39.AVOS mediation")
writeData(res, "ST39.AVOS mediation", avos_results_df)

# Save
saveWorkbook(
res,
file.path(out,"Aim_3_ST.xlsx"),
overwrite=TRUE)

# Source code files

sc <- createWorkbook()

# Fig 3a, 3b
addWorksheet(sc, "Fig 3a, 3b")
writeData(sc, "Fig 3a, 3b", bwt_res, startRow=2)
writeData(sc, "Fig 3a, 3b", socio_res, startRow=13)
writeData(sc, "Fig 3a, 3b", gcse_res, startRow=24)
writeData(sc, "Fig 3a, 3b", cbmi_res, startRow=35)
writeData(sc, "Fig 3a, 3b", smoking_res, startRow=47)
writeData(sc, "Fig 3a, 3b", alc_res, startRow=59)
writeData(sc, "Fig 3a, 3b", act_res, startRow=71)
writeData(sc, "Fig 3a, 3b", adv_res, startRow=83)

# Fig 4a
addWorksheet(sc, "Fig 4a")
writeData(sc, "Fig 4a", adolescent_overweight_63, startRow=2)
writeData(sc, "Fig 4a", adolescent_overweight_53, startRow=7)
writeData(sc, "Fig 4a", adolescent_overweight_43, startRow=12)
writeData(sc, "Fig 4a", adolescent_overweight_36, startRow=17)

# Fig 4b
addWorksheet(sc, "Fig 4b")
writeData(sc, "Fig 4b", activity_dose)

# Fig 4c
addWorksheet(sc, "Fig 4c")
writeData(sc, "Fig 4c", adversity_multivariable)

# Fig 4d
addWorksheet(sc, "Fig 4d")
writeData(sc, "Fig 4d", pooled_smok)

# Fig 4e
addWorksheet(sc, "Fig 4e")
writeData(sc, "Fig 4e", edu_pooled)
writeData(sc, "Fig 4e", edu_men, startRow = 10)
writeData(sc, "Fig 4e", edu_women, startRow = 20) 
writeData(sc, "Fig 4e", edu_n_men, startRow = 30)
writeData(sc, "Fig 4e", edu_n_women, startRow = 40)

# Fig 5b
addWorksheet(sc, "Fig 5b")
writeData(sc, "Fig 5b", pf_averagedvalues)

# Fig 5c, 5d
addWorksheet(sc, "Fig 5c, 5d")
writeData(sc, "Fig 5c, 5d", pfs_Conv)
writeData(sc, "Fig 5c, 5d", pfs_multi, startRow=10, startCol=1)

# Fig 5e, 5f
addWorksheet(sc, "Fig 5e, 5f")
writeData(sc, "Fig 5e, 5f", pooled_conv, startRow=2)
writeData(sc, "Fig 5e, 5f", pooled_multiorgan, startRow=7)

# Fig 6a
addWorksheet(sc, "Fig 6a")
writeData(sc, "Fig 6a", joint_results_df)

# Fig 6b
addWorksheet(sc, "Fig 6b")
writeData(res, "Fig 6b", med_cross)

# Ext data Fig 4d
addWorksheet(sc, "Ext data Fig 4d")
writeData(sc, "Ext data Fig 4d", lc_avos)

# Ext data Fig 4e
addWorksheet(sc, "Ext data Fig 4e")
writeData(sc, "Ext data Fig 4e", pfc_avos)

# Ext data Fig 7a
addWorksheet(sc, "Ext data Fig 3a")
writeData(sc, "Ext data Fig 3a", pooled_liver_ow)

# Ext data Fig 7b
addWorksheet(sc, "Ext data Fig 3b")
writeData(sc, "Ext data Fig 3b", pooled_kidney_sm)

# Ext data Fig 7c
addWorksheet(sc, "Ext data Fig 3c")
writeData(sc, "Ext data Fig 3c", pooled_immune_act)

# Ext data Fig 7a
addWorksheet(sc, "Ext data Fig 4a")
writeData(sc, "Ext data Fig 4a", brain_alcohol_controlled)

# Ext data Fig 8c
addWorksheet(sc, "Ext data Fig 8c")
writeData(sc, "Ext data Fig 8c", alc_edu)

# Ext data Fig 8d
addWorksheet(sc, "Ext data Fig 8d")
writeData(sc, "Ext data Fig 8d", alc_sel)

# Ext data Fig 8e
addWorksheet(sc, "Ext data Fig 8e")
writeData(sc, "Ext data Fig 8e", alc_stop_all)
writeData(sc, "Ext data Fig 8e", alc_stop_dis, startRow = 10)

# Ext data Fig 8g
addWorksheet(sc, "Ext data Fig 4c")
writeData(sc, "Ext data Fig 8g", pooled_df_82, startRow=2, startCol=1)
writeData(sc, "Ext data Fig 8g", pooled_df_89, startRow=2, startCol=12)
writeData(sc, "Ext data Fig 8g", pooled_df_99, startRow=2, startCol=17)
writeData(sc, "Ext data Fig 8g", pooled_df_09, startRow=2, startCol=22)
writeData(sc, "Ext data Fig 8g", pooled_df_ov, startRow=2, startCol=27)

# Save
saveWorkbook(
sc, 
file.path(out,"SC_Aim_3.xlsx"), 
overwrite=TRUE)

#### VISUALISATION ####

# Non-linearity plot for Alcohol & brain age: Age 36

lin <- lm(BrainAge60 ~ avalc82u + Age60 + Sex_F, data = dataset)

fp <- mfp(BrainAge60 ~ fp(avalc82u, df = 4) + Age60 + Sex_F,
          family = "gaussian",
          data = dataset)

grid <- data.frame(
  avalc82u = seq(min(dataset$avalc82u, na.rm=T), max(dataset$avalc82u, na.rm=T), length.out = 200),
  Age60 = mean(dataset$Age60),
  Sex_F = 0
)

grid$lin <- predict(lin, newdata = grid)

pred <- predict(fp, newdata = grid, se.fit = T)
grid$fit <- pred$fit
grid$lci <- grid$fit - 1.96*pred$se.fit
grid$uci <- grid$fit + 1.96*pred$se.fit

p1 <- ggplot(grid, aes(x = avalc82u, y = fit)) + 
  geom_line(linewidth = 1, color = "black") + 
  geom_ribbon(aes(ymin=lci, ymax=uci), alpha = 0.2, fill = "#4DBBD5FF") + 
  coord_cartesian(xlim = c(0, 20), ylim = c(-5, 5)) +
  theme_classic()

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/brain_36.pdf"), plot=p1, width = 4, height = 4)

# Non-linearity plot for Alcohol & brain age: Age 43

lin <- lm(BrainAge60 ~ avalc89u + Age60 + Sex_F, data = dataset)

fp <- mfp(BrainAge60 ~ fp(avalc89u, df = 4) + Age60 + Sex_F,
          family = "gaussian",
          data = dataset)

grid <- data.frame(
  avalc89u = seq(min(dataset$avalc89u, na.rm=T), max(dataset$avalc89u, na.rm=T), length.out = 200),
  Age60 = mean(dataset$Age60),
  Sex_F = 0
)

grid$lin <- predict(lin, newdata = grid)

pred <- predict(fp, newdata = grid, se.fit = T)
grid$fit <- pred$fit
grid$lci <- grid$fit - 1.96*pred$se.fit
grid$uci <- grid$fit + 1.96*pred$se.fit

p2 <- ggplot(grid, aes(x = avalc89u, y = fit)) + 
  geom_line(linewidth = 1, color = "black") + 
  geom_ribbon(aes(ymin=lci, ymax=uci), alpha = 0.2, fill = "#4DBBD5FF") + 
  coord_cartesian(xlim = c(0, 20), ylim = c(-5, 5)) +
  theme_classic()

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/brain_43.pdf"), plot=p2, width = 4, height = 4)

# Non-linearity plot for Alcohol & brain age: Age 53

lin <- lm(BrainAge60 ~ avalc99u + Age60 + Sex_F, data = dataset)

fp <- mfp(BrainAge60 ~ fp(avalc99u, df = 4) + Age60 + Sex_F,
          family = "gaussian",
          data = dataset)

grid <- data.frame(
  avalc99u = seq(min(dataset$avalc99u, na.rm=T), max(dataset$avalc99u, na.rm=T), length.out = 200),
  Age60 = mean(dataset$Age60),
  Sex_F = 0
)

grid$lin <- predict(lin, newdata = grid)

pred <- predict(fp, newdata = grid, se.fit = T)
grid$fit <- pred$fit
grid$lci <- grid$fit - 1.96*pred$se.fit
grid$uci <- grid$fit + 1.96*pred$se.fit

p1 <- ggplot(grid, aes(x = avalc99u, y = fit)) + 
  geom_line(linewidth = 1, color = "black") + 
  geom_ribbon(aes(ymin=lci, ymax=uci), alpha = 0.2, fill = "#4DBBD5FF") + 
  coord_cartesian(xlim = c(0, 20), ylim = c(-5, 5)) +
  theme_classic()

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/brain_53.pdf"), plot=p1, width = 4, height = 4)

# Non-linearity plot for Alcohol & brain age: Age 63

lin <- lm(BrainAge60 ~ avalc09u + Age60 + Sex_F, data = dataset)

fp <- mfp(BrainAge60 ~ fp(avalc09u, df = 4) + Age60 + Sex_F,
          family = "gaussian",
          data = dataset)

grid <- data.frame(
  avalc09u = seq(min(dataset$avalc09u, na.rm=T), max(dataset$avalc09u, na.rm=T), length.out = 200),
  Age60 = mean(dataset$Age60),
  Sex_F = 0
)

grid$lin <- predict(lin, newdata = grid)

pred <- predict(fp, newdata = grid, se.fit = T)
grid$fit <- pred$fit
grid$lci <- grid$fit - 1.96*pred$se.fit
grid$uci <- grid$fit + 1.96*pred$se.fit

p2 <- ggplot(grid, aes(x = avalc09u, y = fit)) + 
  geom_line(linewidth = 1, color = "black") + 
  geom_ribbon(aes(ymin=lci, ymax=uci), alpha = 0.2, fill = "#4DBBD5FF") + 
  coord_cartesian(xlim = c(0, 20), ylim = c(-5, 5)) +
  theme_classic()

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/brain_63.pdf"), plot=p2, width = 4, height = 4)

# Non-linearity plot for Smoking & Conv age: Age 36

lin <- lm(ConventionalAge60 ~ packyr3136 + Age60 + Sex_F, data = dataset)

fp <- mfp(ConventionalAge60 ~ fp(packyr3136, df = 4) + Age60 + Sex_F,
          family = "gaussian",
          data = dataset)

grid <- data.frame(
  packyr3136 = seq(min(dataset$packyr3136, na.rm=T), max(dataset$packyr3136, na.rm=T), length.out = 200),
  Age60 = mean(dataset$Age60),
  Sex_F = 0
)

grid$lin <- predict(lin, newdata = grid)

pred <- predict(fp, newdata = grid, se.fit = T)
grid$fit <- pred$fit
grid$lci <- grid$fit - 1.96*pred$se.fit
grid$uci <- grid$fit + 1.96*pred$se.fit

p1 <- ggplot(grid, aes(x = packyr3136, y = fit)) + 
  geom_line(linewidth = 1, color = "black") + 
  geom_ribbon(aes(ymin=lci, ymax=uci), alpha = 0.2, fill =  "#F39B7FFF") + 
  coord_cartesian(xlim = c(0, 15), ylim = c(-5, 5)) +
  theme_classic()

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/c_smoking_36.pdf"), plot=p1, width = 4, height = 4)

# Non-linearity plot for Smoking & Conv age: Age 43

lin <- lm(ConventionalAge60 ~ packyr3643 + Age60 + Sex_F, data = dataset)

fp <- mfp(ConventionalAge60 ~ fp(packyr3643, df = 4) + Age60 + Sex_F,
          family = "gaussian",
          data = dataset)

grid <- data.frame(
  packyr3643 = seq(min(dataset$packyr3643, na.rm=T), max(dataset$packyr3643, na.rm=T), length.out = 200),
  Age60 = mean(dataset$Age60),
  Sex_F = 0
)

grid$lin <- predict(lin, newdata = grid)

pred <- predict(fp, newdata = grid, se.fit = T)
grid$fit <- pred$fit
grid$lci <- grid$fit - 1.96*pred$se.fit
grid$uci <- grid$fit + 1.96*pred$se.fit

p1 <- ggplot(grid, aes(x = packyr3643, y = fit)) + 
  geom_line(linewidth = 1, color = "black") + 
  geom_ribbon(aes(ymin=lci, ymax=uci), alpha = 0.2, fill = "#F39B7FFF") + 
  coord_cartesian(xlim = c(0, 15), ylim = c(-5, 5)) +
  theme_classic()

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/c_smoking_43.pdf"), plot=p1, width = 4, height = 4)

# Non-linearity plot for Smoking & Conv age: Age 53

lin <- lm(ConventionalAge60 ~ packyr4353 + Age60 + Sex_F, data = dataset)

fp <- mfp(ConventionalAge60 ~ fp(packyr4353, df = 4) + Age60 + Sex_F,
          family = "gaussian",
          data = dataset)

grid <- data.frame(
  packyr4353 = seq(min(dataset$packyr4353, na.rm=T), max(dataset$packyr4353, na.rm=T), length.out = 200),
  Age60 = mean(dataset$Age60),
  Sex_F = 0
)

grid$lin <- predict(lin, newdata = grid)

pred <- predict(fp, newdata = grid, se.fit = T)
grid$fit <- pred$fit
grid$lci <- grid$fit - 1.96*pred$se.fit
grid$uci <- grid$fit + 1.96*pred$se.fit

p1 <- ggplot(grid, aes(x = packyr4353, y = fit)) + 
  geom_line(linewidth = 1, color = "black") + 
  geom_ribbon(aes(ymin=lci, ymax=uci), alpha = 0.2, fill = "#F39B7FFF") + 
  coord_cartesian(xlim = c(0, 15), ylim = c(-5, 5)) +
  theme_classic()

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/c_smoking_53.pdf"), plot=p1, width = 4, height = 4)

# Non-linearity plot for Smoking & Conv age: Age 63

lin <- lm(ConventionalAge60 ~ packyr5363 + Age60 + Sex_F, data = dataset)

fp <- mfp(ConventionalAge60 ~ fp(packyr5363, df = 4) + Age60 + Sex_F,
          family = "gaussian",
          data = dataset)

grid <- data.frame(
  packyr5363 = seq(min(dataset$packyr5363, na.rm=T), max(dataset$packyr5363, na.rm=T), length.out = 200),
  Age60 = mean(dataset$Age60),
  Sex_F = 0
)

grid$lin <- predict(lin, newdata = grid)

pred <- predict(fp, newdata = grid, se.fit = T)
grid$fit <- pred$fit
grid$lci <- grid$fit - 1.96*pred$se.fit
grid$uci <- grid$fit + 1.96*pred$se.fit

p1 <- ggplot(grid, aes(x = packyr5363, y = fit)) + 
  geom_line(linewidth = 1, color = "black") + 
  geom_ribbon(aes(ymin=lci, ymax=uci), alpha = 0.2, fill = "#F39B7FFF") + 
  coord_cartesian(xlim = c(0, 15), ylim = c(-5, 5)) +
  theme_classic()

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/c_smoking_63.pdf"), plot=p1, width = 4, height = 4)


