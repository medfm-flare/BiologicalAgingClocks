# ============================================================
# 4_Load_variables_and_clean_data.R
# Purpose: Data cleaning for life course, organ age and mortality data
# Input: Raw NSHD life course, organ age and mortality data
# Output: Cleaned merged dataset for downstream analysis
# Author: James Groves
# Date: 2026-03-28
# ============================================================

#### SET-UP ####

# Packages

library(tidyverse)
library(readxl)
library(ggsci)
library(broom)
library(haven)
library(purrr)

# Directory

setwd("S:/LHA_JG0923/Revision/")

inp <- file.path(getwd(), "3. Load variables & clean data")

#### ORGAN AGES ####

# Load organ ages

ages_long <- read.csv(
  file.path(inp, "organages.csv"))

# Manage columns 

ages_long <- ages_long %>% 
  rename(
    id=ID
    ) 

ages_long <- ages_long %>% 
  subset(
  select=c(
    id, Sex_F, Age, AgeGap, Organ, Predicted_Age)
  ) 

ages_long <- ages_long %>% 
  filter(
    Organ=="Conventional" | 
    Organ=="Brain" | 
    Organ=="Heart" | 
    Organ=="Kidney" | 
    Organ=="Liver" | 
    Organ=="Immune" | 
    Organ=="Artery" | 
    Organ=="Lung")

ages_long <- ages_long %>%
  rename(
    AgeGap60 = AgeGap,
    Age60 = Age
  )

# Wide format

organs <- c("Conventional", "Brain", "Immune", "Artery", 
"Heart", "Kidney", "Liver", "Lung")

for (organ in organs) {
  
col1 <- paste(organ, "Age60", sep="")

ages_long[[col1]] <- 
ifelse(ages_long$Organ==organ, 
       ages_long$AgeGap60, 
       NA)

col2 <- paste(organ, "PredAge60", sep="")

ages_long[[col2]] <- 
  ifelse(ages_long$Organ==organ, 
         ages_long$Predicted_Age, 
         NA)

}

ages <- ages_long %>%
group_by(id) %>%
summarize_all(~first(na.omit(.))) %>%
  subset(select=-c(
    AgeGap60, Organ, Predicted_Age
  ))

# Classify extreme ageing

for (organ in organs) {

  col <- paste(organ, "Age60", sep="")
    
  threshold <- quantile(ages[[col]], 0.9)
  
  extreme <- ifelse(
    ages[[col]]>=threshold,
    1,
    0)
  
  ages[[paste0(col, "high")]] <- extreme
  
}

# Extreme ageing counts

ext_cols <- c("BrainAge60high", "ArteryAge60high", 
              "HeartAge60high", "ImmuneAge60high", 
              "KidneyAge60high", "LiverAge60high", 
              "LungAge60high")

ages$multiorgan60high <- rowSums(ages[ext_cols])

ages$multiorgan60high3max <- ages$multiorgan60high

ages$multiorgan60high3max[ages$multiorgan60high3max==6] <- 3
ages$multiorgan60high3max[ages$multiorgan60high3max==5] <- 3
ages$multiorgan60high3max[ages$multiorgan60high3max==4] <- 3

ages$multiorgan60high4max <- ages$multiorgan60high

ages$multiorgan60high4max[ages$multiorgan60high4max==6] <- 4
ages$multiorgan60high4max[ages$multiorgan60high4max==5] <- 4

ages$multiorganageing <- ifelse(ages$multiorgan60high>1,1,0)

# Set classes

ages$multiorgan60high <- as.factor(ages$multiorgan60high)

ages$multiorgan60high3max <- as.factor(ages$multiorgan60high3max)

ages$multiorgan60high4max <- as.factor(ages$multiorgan60high4max)

# Z-score variables

for (organ in organs) {
  
  age <- paste(organ, "Age60", sep="")
  
  col <- paste(age, "z", sep="_")
  
  ages[[col]] <- 
    as.numeric(scale(ages[[age]]))
}

# AVOS measure

org_spec <- c("BrainAge60_z", "ImmuneAge60_z", "ArteryAge60_z", 
          "HeartAge60_z", "KidneyAge60_z", "LiverAge60_z", "LungAge60_z")


ages$avos <- apply(ages[, org_spec], 1, sd)

# Any missing data?

anyNA(ages)

# Record included participants

inc <- ages$id

#### LIFE COURSE EXPOSURES ####

# Load data

lc1 <- read.csv("S:/LHA_JG0923/Skylark/jwgrovesZZhemqsv-SCRAMBLED.csv")
lc2 <- read.csv("S:/LHA_JG0923/Skylark/jwgrovesZZzxvchy-NTAG1-SCRAMBLED/jwgrovesZZzxvchy-SCRAMBLED.csv")
lc3 <- read.csv("S:/LHA_JG0923/Skylark/jwgrovesZZvvgtpa-SCRAMBLED.csv")
lc4 <- read.csv("S:/LHA_JG0923/Skylark/jwgrovesZZtpkusy-NTAG1-SCRAMBLED/jwgrovesZZtpkusy-SCRAMBLED.csv")
lc5 <- read.csv("S:/LHA_JG0923/jwgrovesZZoizxzz-NTAG1-SCRAMBLED/jwgrovesZZoizxzz-SCRAMBLED.csv")
lc6 <- read.csv("S:/LHA_JG0423/jwgrovesZZltnjxa-SCRAMBLED.csv")
lc7 <- read.csv("S:/LHA_JG0923/Other/Other Variables/jwgrovesZZsnsskl-SCRAMBLED.csv")
lc8 <- read.csv("S:/LHA_JG0923/jwgrovesZZqxtnfl-NTAG1-SCRAMBLED/jwgrovesZZqxtnfl-SCRAMBLED.csv")

# Remove duplicate columns

lc1 <- lc1 %>% subset(select=-c(inf))
lc2 <- lc2 %>% subset(select=-c(sex, inf, cmd6clas))
lc3 <- lc3 %>% subset(select=-c(sex, inf))
lc4 <- lc4 %>% subset(select=-c(sex, inf, cmd53or4, egfr09))
lc5 <- lc5 %>% subset(select=-c(sex, inf))
lc6 <- lc6 %>% subset(select=-c(sex, inf))
lc7 <- lc7 %>% subset(select=-c(sex, inf))
lc8 <- lc8 %>% subset(select=-c(sex, inf, bnf421, bnf422))

# Merge files

lc <- Reduce(function(x,y) merge(
x,y, by = "nshdid_NTAG1", all = TRUE), 
list(lc1, lc2, lc3, lc4, lc5, lc6, lc7, lc8))

# Subset data

lc <- lc %>% 
  dplyr::rename(
    id = nshdid_NTAG1
    )

vars <- c(
  "id", "lowbwt", "chsc", "lhqr", "bmi61u",
  "packyr20", "packyr2025", "packyr2531", "packyr3136", 
  "packyr3643", "packyr4353", "packyr5363", "avalc82u", 
  "avalc89u", "avalc99u", "avalc09u","exer82", 
  "exer89x", "exer99x", "exer09x", "sc1553", "wt82bciav",
  "wt82wnav", "wt82spiav", "wt89bciav", "wt89wnav", 
  "wt89spiav", "wt99bciav", "wt99wnav", "wt99spiav",
  "wt09bciav", "wt09wnav", "wt09spiav")

exp <- lc %>% subset(select=c(vars))

# Remove NAs

exp[exp<0] <- NA

exp$chsc[exp$chsc == 9] <- NA

exp$sc1553[exp$sc1553 == 999] <- NA

exp$lhqr[exp$lhqr == 10] <- NA
exp$lhqr[exp$lhqr == 9] <- NA

exp$bmi61u[exp$bmi61u == 9999] <- NA
exp$bmi61u[exp$bmi61u == 7777] <- NA

exp$exer82[exp$exer82 == 9] <- NA

exp$exer89x[exp$exer89x == 9] <- NA

exp$exer99x[exp$exer99x == 88] <- NA
exp$exer99x[exp$exer99x == 7] <- NA

exp$exer09x[exp$exer09x == 999] <- NA
exp$exer09x[exp$exer09x == 998] <- NA
exp$exer09x[exp$exer09x == 777] <- NA

# Check plausible max/mins

maxs <- sapply(exp, max, na.rm=TRUE)

mins <- sapply(exp, min, na.rm=TRUE)

maxmins <- data.frame(
  Var=names(exp), 
  min=mins, 
  max=maxs)

# Add adversity measures

adv <- read.csv(
  "S:/LHA_JG0923/Proteomic Ageing Project/Final Scripts & Data/3. Load variables & clean data/adversity_data.csv")

adv <- adv[ , -1]

# Merge 

exp_final <- merge(exp, adv, by="id")

# Set classes

adv_var <- c("CROW15y", "amenities", "childSES", 
  "matsep", "divorce16", "peers", "phy16",
  "finance36", "employed36", "amenities26", 
  "crow26", "social36", "divorce36", "work36", 
  "work4353", "finance4353", "housecondition43", 
  "support4353", "lostcontact4353","chdconflict4353", 
  "divorce4353", "social4353","finance63", 
  "support63", "lostcontact63", "chdconflict63", 
  "divorce63", "social63", "work63")

cont <- c(
  "bmi61u", "packyr20", "packyr2025", 
  "packyr2531", "packyr3136", "packyr3643", 
  "packyr4353", "packyr5363", "avalc82u", 
  "avalc89u", "avalc99u", "avalc09u") 

cat <- c(
  "lowbwt", "chsc", "lhqr", 
  "exer82", "exer89x", "exer99x", 
  "exer09x", "sc1553", 
  adv_var)

exp_final[cat] <- lapply(
  exp_final[cat], 
  as.factor)

# Remove excluded

exp_final <- exp_final %>%
  filter(id %in% inc)

#### MORTALITY & DISEASES ####

# Load mortality

mort <- read.csv("S:/LHA_JG0923/NHS_Digital/Mortality/mortality_derived_130824-DSH_sharing.csv", fileEncoding = "UTF-8-BOM")

# Manage columns

mort <- mort %>% 
  rename(
  death=DTH2CEN2, 
  months=DTH2DTM2)

mort$covid_dth <- ifelse(mort$DTHU10XX=="U07", 1, 0)

mort <- mort %>% 
  subset(
    select=c(id, death, months, covid_dth))

# Set classes

mort$months <- as.numeric(mort$months)

# Reset max months

mort$months[mort$months==995] <- 940

# Remove excluded

mort_final <- mort %>%
  filter(id %in% inc)

# Add disease information

ip = read.csv("S:/LHA_JG0923/NHS_Digital/HES/APC/HES_APC_20240515-153101_ntag1.csv")

op = read.csv("S:/LHA_JG0923/NHS_Digital/HES/OP/HES_OP_20240516-180657_ntag1.csv")

ip <- ip %>% 
  subset(select=c(
    ntag1, apc_admidate_year, apc_admidate_month,
    apc_diag_01x3, apc_diag_02x3, apc_diag_03x3, apc_diag_04x3, apc_diag_05x3,
    apc_diag_06x3, apc_diag_07x3, apc_diag_08x3, apc_diag_09x3, apc_diag_10x3,
    apc_diag_11x3, apc_diag_12x3, apc_diag_13x3, apc_diag_14x3, apc_diag_15x3,
    apc_diag_16x3, apc_diag_17x3, apc_diag_18x3, apc_diag_19x3, apc_diag_20x3
  )) %>%
  rename(
    id = ntag1
  ) %>%
  pivot_longer(
    starts_with("apc_diag"), names_to="diag_var", values_to="icd10"
  ) %>%
  filter(!(icd10=="")) %>% 
  rename(
    month=apc_admidate_month, year=apc_admidate_year
  ) %>%
  mutate(
    event_date = year + (month - 1)/12
  ) 

op <- op %>%
  pivot_longer(
    cols = starts_with("op_diag_"),  
    names_to = "diag_var",
    values_to = "icd10"
  ) %>%
  mutate(
    year = op_apptdate_year,
    month = op_apptdate_month,
    event_date = year + (month - 1) / 12  
  ) %>%
  rename(
    id = ntag1
  ) %>%
  subset(select=c(id, year, month, diag_var, icd10, event_date)) %>%
  filter(!(icd10==""))

ehr = rbind(ip, op)

conditions <- list(
  HF = "^I50",
  IHD = "^I2[0-5]",
  COPD = "^J4[3-4]",
  CKD = "^(N1[8-9]|I12|I13|Z49)",
  AF = "^I48",
  COVID = "^U07",
  Stroke_TIA = "^(I6[0-9]|G45)",
  Cardiomyopathy = "^I42",
  PVD = "^(I70|I71|I73|I74)",
  Diabetes = "^E1[0-4]",
  HPB = "^(K7(0|2|3|4|5)|C22|C23|C24|K83)",
  Other_liver = "^(K71|B18)",
  Canc = "^C[0-9]",
  ILD = "^(J84|J6[0-9]|J70)",
  Neuro = "^(F0[0-3]|G30|G31|G20|G23|G10|G12)",
  Autoimmune = "^(M0[5-6]|M3[0-6]|D86)",
  Other_autoimmune = "^(K50|K51)",
  Other_neuro = "^(G35|G40)",
  HIV = "^(B2[0-4])",
  RA =  "^(M05|M06)",
  Migraine = "^G43",
  SLE = "^M32",
  Severe_mental = "^(F20|F21|F22|F23|F24|F25|F28|F29|F31)",
  ED = "^N52",
  T1DM = "^E10",
  T2DM = "^E11"
)

events <- lapply(names(conditions), function(cond) {
  
  ehr %>%
    
    filter(str_detect(icd10, conditions[[cond]])) %>%
    
    group_by(id) %>%
    
    summarize(first_evt = min(event_date, na.rm=TRUE)) %>%
    
    rename(!!paste0(cond, "_evt") := first_evt)
  
}
) %>% 
  reduce(full_join, by="id")

# Join with mortality

mort_final <- merge(mort_final, events, by = "id", all.x=T)

# Combine COVID events

mort_final$COVID_evt <- ifelse(mort_final$covid_dth==1, 
                               ifelse(is.na(mort_final$COVID_evt), 1946.167 + (mort_final$months/12), 
                                      pmin(mort_final$COVID_evt, 1946.167 + (mort_final$months/12))), 
                               mort_final$COVID_evt)

# Remove COVID death variable

mort_final <- mort_final %>%
  dplyr::select(-covid_dth)

#### OTHER VARIABLES ####

oth_vars <- c(
  "id", "disa15x", "chron19tot15x", 
  "summhealth15x", "bmi66u", "bmi72u", 
  "bmi82u", "bmi89u", "bmi99u", 
  "bmi09", "cogchild", "egfr09",
  "hdl09", "cholestr09", "hba1c209", 
  "fried", "acetotfin15x", 
  "chrst09", "vsp09", "wlt09", 
  "b2_5_09", "bnf421", "bnf422",
  "bnf634", "sbp109", "sbp209",
  "wtn09", "htn09_v2", "cars01"
  )

oth_exp <- lc %>% 
  subset(select=oth_vars)

# Remove NAs

not_childcog <- setdiff(names(oth_exp), "cogchild")

oth_exp[not_childcog][oth_exp[not_childcog] < 0] <- NA

oth_exp[oth_exp==9999] <- NA
oth_exp[oth_exp==8888] <- NA
oth_exp[oth_exp==7777] <- NA

oth_exp[oth_exp==999] <- NA
oth_exp[oth_exp==888] <- NA
oth_exp[oth_exp==777] <- NA

oth_exp$hba1c209[oth_exp$hba1c209==77] <- NA
oth_exp$hba1c209[oth_exp$hba1c209==99] <- NA

oth_exp$hdl09[oth_exp$hdl09==9] <- NA
oth_exp$hdl09[oth_exp$hdl09==7] <- NA

oth_exp$cholestr09[oth_exp$cholestr09==99] <- NA
oth_exp$cholestr09[oth_exp$cholestr09==77] <- NA

oth_exp$fried[oth_exp$fried==7] <- NA
oth_exp$fried[oth_exp$fried==9] <- NA

oth_exp$b2_5_09[oth_exp$b2_5_09==7] <- NA

oth_exp$bnf421[oth_exp$bnf421==7] <- NA

oth_exp$bnf422[oth_exp$bnf422==7] <- NA

oth_exp$bnf634[oth_exp$bnf634==7] <- NA

# Verify max and mins

mins <- sapply(oth_exp, min, na.rm=TRUE)

maxs <- sapply(oth_exp, max, na.rm=TRUE)

maxmins <- data.frame(
Var=names(oth_exp),
min=mins, 
max=maxs)

# Antipsych

oth_exp$bnf421 <- ifelse(oth_exp$bnf422 == 1, 1, oth_exp$bnf421)

oth_exp <- oth_exp %>% dplyr::select(-bnf422)

# Set classes

cat <- c("disa15x", "chron19tot15x", "summhealth15x",  
         "fried", "b2_5_09", "bnf421",
         "bnf634")

oth_exp[cat] <- lapply(
oth_exp[cat], as.factor)

oth_exp$bnf421 <- as.numeric(as.character(oth_exp$bnf421))
oth_exp$bnf634 <- as.numeric(as.character(oth_exp$bnf634))
oth_exp$b2_5_09  <- as.numeric(as.character(oth_exp$b2_5_09))

# Set constants

oth_exp$ethrisk <- 1
oth_exp$fh_cvd  <- 0

# Remove excluded

oth_exp_final <- oth_exp %>%
  filter(id %in% inc)

#### CREATE DATASET ####

# Merge

dataset <- Reduce(function(x,y) merge(x,y, by = "id", all=T), 
list(ages, exp_final, mort_final, oth_exp_final))

# Add follow-up length

dataset$proteomicsampleage_months <- dataset$Age60*12

dataset$death_monthssincesample <- 
  dataset$months - dataset$proteomicsampleage_months

dataset$death_yearssincesample <- 
  dataset$death_monthssincesample/12

# Add event columns

dataset$deathdate = 1946.167 + (dataset$months/12)
dataset$protdate = 1946.167 + dataset$Age60

# Disease columns

for(condition in names(conditions)) {
  
  evt_col  <- paste0(condition, "_evt")
  
  time_col <- paste0(condition, "_time")
  
  ev_col   <- paste0(condition, "_event")
  
  prev_col <- paste0(condition, "_prev")
  
  dataset[[time_col]]  <- pmin(dataset[[evt_col]], dataset$deathdate, na.rm=TRUE)
  
  dataset[[ev_col]]    <- as.integer(
    !is.na(dataset[[evt_col]]) &
      dataset[[evt_col]] <= dataset$deathdate)
  
  dataset[[prev_col]] <- ifelse(dataset[[ev_col]]==1  & dataset[[time_col]] <= dataset$protdate, 1, 0)
  
}

# Add major disease indicator

dataset <- dataset %>%
  mutate(
    disease = ifelse((HF_prev == 1 | IHD_prev == 1 |
       COPD_prev == 1 | CKD_prev == 1 | AF_prev == 1 |
      Stroke_TIA_prev == 1 | Cardiomyopathy_prev == 1 | PVD_prev == 1 |
        Diabetes_prev == 1 | HPB_prev == 1 | Other_liver_prev == 1 |
        Canc_prev == 1 | ILD_prev == 1 | Neuro_prev == 1 | 
        Autoimmune_prev == 1 | Other_autoimmune_prev == 1 |
        Other_neuro_prev == 1 | HIV_prev == 1), 1, 0)
  )

# Remove raw EHR data

ehrvars <- names(dataset)[grepl("_evt$", names(dataset))]

dataset <- subset(dataset, select = !(names(dataset) %in% ehrvars))

# Remove other liver category

dataset <- dataset %>% dplyr::select(-c(Other_liver_event, Other_liver_prev, Other_liver_time,
                                 Other_autoimmune_event, Other_autoimmune_prev, Other_autoimmune_time,
                                 Other_neuro_event, Other_neuro_prev, Other_neuro_time,
                                 ILD_event, ILD_prev, ILD_time))

#### OUTPUT FILES ####

# Save dataset
rm(list=setdiff(ls(), "dataset"))

# Set locations

out1 <- file.path(getwd(), "4. Sample description & missing data")
out2 <- file.path(getwd(), "5. Multiple Imputation")
out3 <- file.path(getwd(), "6. Aim 1 - Organ age distributions")
out4 <- file.path(getwd(), "7. Aim 2 - Mortality prediction")
out5 <- file.path(getwd(), "8. Aim 3 - Modifiable risk factor associations")
out6 <- file.path(getwd(), "9. Aim 4 - Specific proteins connected to mortality & modifiable risk")

# All participants

save.image(
  file = file.path(out1, "dataset_all.RData"))

save.image(
  file = file.path(out5, "dataset_all.RData"))

# Included participants

save.image(file = file.path(out1,"dataset_inc.RData"))

save.image(file = file.path(out2,"dataset_inc.RData"))

save.image(file =  file.path(out3,"dataset_inc.RData"))

save.image(file =  file.path(out4,"dataset_inc.RData"))

save.image(file =  file.path(out5,"dataset_inc.RData"))



