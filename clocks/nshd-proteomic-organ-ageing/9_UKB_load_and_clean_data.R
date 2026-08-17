# ============================================================
# 10_UKB_load_and_clean_data.R
# UKB: Clean data
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

inp <- file.path(getwd(), "10. UKB_load_and_clean_data")
out <- file.path(getwd(), "10. UKB_load_and_clean_data")

#### LOAD & CLEAN DATA ####

gaps_ukb <- read.csv(file.path(inp, "norm_age_gaps_instance_0.csv"))

conv_ukb <- gaps_ukb %>% 
  filter(
    organ == "Conventional"
  ) %>%
  subset(
    select = c(
      eid, AgeGap
    )
  ) %>%
  rename(
    ConventionalAge60 = AgeGap
  )

brain_ukb <- gaps_ukb %>% 
  filter(
    organ == "Brain"
  ) %>%
  subset(
    select = c(
      eid, AgeGap
    )
  ) %>%
  rename(
    BrainAge60 = AgeGap
  )

sex_ukb <- read.csv(file.path(inp, "participant_p31_Sex.csv")) %>%
  rename(
    sex = p31
  )

age_ukb <- read.csv(file.path(inp, "participant_p21003_i0_Age_when_attended_assessment_centre__Instance_0.csv")) %>%
  rename(
    age = p21003_i0
  )

alc_ukb <- read.csv(file.path(inp, "participant_p1558_i0_Alcohol_intake_frequency__Instance_0.csv")) %>%
  rename(
    alc = p1558_i0
  ) %>%
  mutate(
    alc_cat = ifelse(alc == "Never", 0, 
                     ifelse(alc == "Special occasions only", 0 ,
                            ifelse(alc == "One to three times a month", 1 , 
                                   ifelse(alc == "Once or twice a week", 2 ,
                                          ifelse(alc == "Three or four times a week", 3,
                                                 ifelse(alc == "Daily or almost daily", 4,
                                                        ifelse(alc == "Prefer not to answer", NA, NA)))))))
  )

teny_ukb <- read.csv(file.path(inp, "participant_p1628_i0_Alcohol_intake_versus_10_years_previously__Instance_0.csv")) %>%
  rename(
    teny = p1628_i0
  ) %>%
  mutate(
    red = ifelse(teny == "Less nowadays", 1 , 
                 ifelse(teny == "More nowadays", 0 ,
                        ifelse(teny == "About the same", 0 , NA)))
  )

dis_ukb <- read.csv(file.path(inp, "participant_p2178_i0_Overall_health_rating__Instance_0.csv")) %>%
  rename(
    dis = p2178_i0
  ) %>%
  mutate(
    health = ifelse(dis == "Excellent", 4, 
                    ifelse(dis == "Good", 3,
                           ifelse(dis == "Fair", 2,
                                  ifelse(dis == "Poor", 1, NA))))
  )

edu_ukb <- read.csv(file.path(inp, "participant_p6138_i0_Qualifications__Instance_0.csv")) %>%
  rename(
    edu = p6138_i0
  ) %>%
  mutate(
    educat = case_when(
      str_detect(edu, "College or University degree|Other professional qualifications eg: nursing, teaching") ~ 3,
      str_detect(edu, "O levels|GCSEs or equivalent|A levels/AS levels|NVQ or HND or HNC or equivalent") ~ 2,
      str_detect(edu, "None of the above|CSEs or equivalent") ~ 1,
      TRUE ~ NA
    )
  )

olink <- read.csv("S:/LHA_Stanford/Organ_ageing_scripts/Disease, Prot. Subset & All Alch. Participant/OLINK_subset_brain_age_proteins copy.csv")

#### MERGE DATA ####

d <- merge(conv_ukb, brain_ukb, by = "eid")
d <- merge(d, sex_ukb, by = "eid")
d <- merge(d, age_ukb, by = "eid")
d <- merge(d, alc_ukb, by = "eid")
d <- merge(d, teny_ukb, by = "eid")
d <- merge(d, edu_ukb, by = "eid")
d <- merge(d, dis_ukb, by = "eid")
dataset <- merge(d, olink, by = "eid")

#### OUTPUT FILES ####

# Isolate dataset

rm(list=setdiff(ls(), "dataset"))

# Set locations

out1 <- file.path(getwd(), "11. UKB_analysis")

# Save dataset

save.image(
  file = file.path(out1, "dataset.RData")
  )
