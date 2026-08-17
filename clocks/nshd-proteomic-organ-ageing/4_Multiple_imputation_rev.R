# ============================================================
# 5_Multiple_imputation.R
# Purpose: MICE imputation of missing life course and covariate data
# Input: Cleaned merged dataset
# Output: Imputed datasets with complete data for life course,
# organ ages and outcomes
# Author: James Groves
# Date: 2026-03-28
# ============================================================

#### SET-UP ####

# Packages

library(mice)
library(tidyverse)

# Directory

setwd("S:/LHA_JG0923/Revision/")

inp <- file.path(getwd(), "5. Multiple Imputation")

#### LOAD DATA ####

# Load data

load(file.path(inp,"dataset_inc.RData"))

timevars <- names(dataset)[grepl("_time$", names(dataset))]

prevvars <- names(dataset)[grepl("_prev$", names(dataset))]

#### PRE-IMPUTATION STEPS ####

# Passive imputation columns

dataset$packyrs <- NA
dataset$alcohol_intake <- NA
dataset$beer <- NA
dataset$wine <- NA
dataset$spirits <- NA
dataset$high_ses <- NA
dataset$obtained_gcse <- NA
dataset$adolescent_overweight <- NA
dataset$active <- NA
dataset$smoker <- NA
dataset$mod_alcohol <- NA
dataset$eco16 <- NA
dataset$eco36 <- NA
dataset$eco4353 <- NA
dataset$eco63 <- NA
dataset$psyc16 <- NA
dataset$psyc36 <- NA
dataset$psyc4353 <- NA
dataset$psyc63 <- NA
dataset$phy <- NA
dataset$childad <- NA
dataset$childad_sum <- NA
dataset$yadult36 <- NA
dataset$yadult36_sum <- NA
dataset$midadult4353 <- NA
dataset$midadult4353_sum <- NA
dataset$lateadult63 <- NA
dataset$lateadult63_sum <- NA
dataset$adall <- NA
dataset$adversity <- NA
dataset$alcoholcategory <- NA
dataset$activecategory <- NA
dataset$stopstatus <- NA
dataset$fifteenpackyrs <- NA
dataset$educat <- NA
dataset$cars01_z <- NA
dataset$chol_hdl <- NA
dataset$sbp_sd <- NA
dataset$egfr09_adj <- NA
dataset$qrisk_smok <- NA
dataset$ckd345 <- NA
dataset$normal_birthweight <- NA
dataset$normal_adolescent_bmi <- NA
dataset$non_smoker <- NA
dataset$no_adversity <- NA
dataset$prof <- NA
dataset$protectivefactors_new <- NA
dataset$protectivefactors_grouped_new <- NA

# Set up terms

init = mice(dataset, method="pmm", maxit=0)
meth = init$method
predM = init$predictorMatrix

# Imputation methods

meth[c("lowbwt")]="logreg"
meth[c("chsc")]="polyreg"
meth[c("lhqr")]="polyreg"
meth[c("exer82")]="polyreg"
meth[c("exer89x")]="polyreg"
meth[c("exer99x")]="polyreg"
meth[c("exer09x")]="polyreg"
meth[c("sc1553")]="polyreg"
meth[c("disa15x")]="logreg"
meth[c("chron19tot15x")]="polyreg"
meth[c("summhealth15x")]="polyreg"
meth[c("fried")]="polyreg"
meth[c("b2_5_09")]="cart"
meth[c("bnf421")]="cart"
meth[c("bnf634")]="cart"

adv_var <- c("CROW15y", "amenities", "childSES", 
"matsep", "divorce16", "peers", "phy16",
"finance36", "employed36", "amenities26", "crow26", 
"social36", "divorce36", "work36", 
"work4353", "finance4353", "housecondition43", 
"support4353", "lostcontact4353","chdconflict4353", 
"divorce4353", "social4353", "finance63", 
"support63", "lostcontact63", "chdconflict63", 
"divorce63", "social63", "work63")

meth[adv_var]="logreg"

# Passive imputation 

meth[c("packyrs")]="~I(packyr20 + packyr2025 + packyr2531 + 
packyr3136 + packyr3643 + packyr4353 + packyr5363)"

meth[c("alcohol_intake")]="~I(((avalc82u + avalc89u + 
avalc99u + avalc09u)/4)*7)"

meth[c("beer")]="~I((wt82bciav + wt89bciav + 
wt99bciav + wt09bciav)/4)"

meth[c("wine")]="~I((wt82wnav + wt89wnav + 
wt99wnav + wt09wnav)/4)"

meth[c("spirits")]="~I((wt82spiav + wt89spiav + 
wt99spiav + wt09spiav)/4)"

meth[c("high_ses")]="~I(ifelse(chsc %in% c(0,1,2,3), 1,
ifelse(chsc %in% c(4,5,6),0,NA)))"

meth[c("obtained_gcse")]="~I(ifelse(lhqr %in% c(0,1,2), 0,
ifelse(lhqr %in% c(3,4,5,6,7,8,9),1,NA)))"

meth[c("adolescent_overweight")]="~I(
ifelse((Sex_F==1 & bmi61u>23.5) | (Sex_F==0 & bmi61u>22.7),1,0))"

meth[c("smoker")]="~I(ifelse(packyrs>0,1,0))"

meth[c("mod_alcohol")]="~I(
ifelse(alcohol_intake>=7 & alcohol_intake<=21,1,0))"

meth[c("active")]="~I(ifelse(
((exer82 %in% c(1,2)) + (exer89x %in% c(1,2)) + 
(exer99x %in% c(1,2)) + (exer09x %in% c(1,2))) >=2, 1,0))"

meth["eco16"] <- "~ ifelse(
CROW15y == 1 | amenities == 1 | childSES == 1 , 1, 0)"

meth["eco36"] <- "~ ifelse(
finance36 == 1 | employed36 == 1 | amenities26 == 1 | 
crow26 == 1 | work36==1, 1, 0)"

meth["eco4353"] <- "~ ifelse(
work4353 == 1 | finance4353 == 1 | housecondition43 == 1, 1, 0)"

meth["eco63"] <- "~ ifelse(work63 == 1 | finance63 == 1, 1, 0)"

meth["phy"] <- "~ ifelse(phy16 == 1, 1, 0)"

meth["psyc16"] <- "~ ifelse(
matsep == 1 | divorce16 == 1 | peers == 1, 1, 0)" 

meth["psyc36"] <- "~ ifelse(social36 == 1 | divorce36 == 1, 1, 0)"

meth["psyc4353"] <- "~ ifelse(
support4353 == 1 | lostcontact4353 == 1 | 
chdconflict4353 == 1 | divorce4353 == 1 | social4353 == 1, 1, 0)"

meth["psyc63"] <- "~ ifelse(
support63 == 1 | lostcontact63 == 1 | 
chdconflict63 == 1 | divorce63 == 1 | social63 == 1, 1, 0)"

meth["childad_sum"] <- "~ rowSums(cbind(`eco16`, `psyc16`, `phy`))"

meth["childad"] <- "~ ifelse(childad_sum == 0, 0, 1)"

meth["yadult36_sum"] <- "~ rowSums(cbind(eco36, psyc36))"

meth["yadult36"] <- "~ ifelse(yadult36_sum == 0, 0, 1)"

meth["midadult4353_sum"] <- "~ rowSums(cbind(eco4353, psyc4353))"

meth["midadult4353"] <- "~ ifelse(midadult4353_sum == 0, 0, 1)"

meth["lateadult63_sum"] <- "~  rowSums(cbind(eco63, psyc63))"

meth["lateadult63"] <- "~ ifelse(lateadult63_sum == 0, 0, 1)"

meth["adall"] <- "~ rowSums(cbind(
childad, yadult36, midadult4353, lateadult63))"

meth[c("adversity")]="~I(ifelse(adall>2,1,0))"

meth[c("alcoholcategory")]="~I(ifelse(alcohol_intake<7,1,
ifelse(alcohol_intake >= 7 & alcohol_intake < 14, 2,
ifelse(alcohol_intake >= 14 & alcohol_intake < 21, 3,4))))"

meth[c("activecategory")]="~I(ifelse(
rowSums(cbind(exer82, exer89x, exer99x, exer09x) == 1) == 4,1,
ifelse(rowSums(cbind(exer82, exer89x, exer99x, exer09x) == 1) == 3,2,
ifelse(rowSums(cbind(exer82, exer89x, exer99x, exer09x) == 1) == 2,3,
ifelse(rowSums(cbind(exer82, exer89x, exer99x, exer09x) == 1) == 1,4,
ifelse(rowSums(cbind(exer82, exer89x, exer99x, exer09x) == 1) == 0,5,NA))))))"

meth[c("stopstatus")]="~I(ifelse(packyrs==0,0,
ifelse((packyr20>0 | packyr2025>0 | packyr2531>0 | 
packyr3136>0 | packyr3643>0) & (packyr4353==0 & packyr5363==0),1,
ifelse((packyr20>0 | packyr2025>0 | packyr2531>0 | 
packyr3136>0 | packyr3643>0) &  (packyr4353>0 | packyr5363>0),3,
ifelse((packyr20==0 & packyr2025==0 & 
packyr2531==0 & packyr3136==0 & packyr3643==0) & 
(packyr4353>0 | packyr5363>0),2,4))))
)"

meth[c("fifteenpackyrs")]="~I(ifelse(packyrs>=15,1,
ifelse(packyrs==0,0,2)))"

meth[c("educat")] <- "~I(ifelse(lhqr%in% c(0,1,2),0,
ifelse(lhqr %in% c(3,4,5),1,
ifelse(lhqr %in% c(6,7,8),2,NA))))"

meth[c("normal_birthweight")]="~I(ifelse(lowbwt==0,1,0))"

meth[c("normal_adolescent_bmi")]="~I(
ifelse(adolescent_overweight==0,1,0))"

meth[c("non_smoker")]="~I(ifelse(smoker==0,1,0))"

meth[c("no_adversity")]="~I(ifelse(adversity==0,1,0))"

meth[c("prof")]="~I(ifelse(sc1553==1,1,0))"

meth[c("cars01_z")]="~I(scale(cars01))"

meth[c("chol_hdl")]="~I(cholestr09 / hdl09)"

meth[c("sbp_sd")]="~I(apply(cbind(sbp109, sbp209), 1, sd))"

meth[c("egfr09_adj")]="~I(ifelse(egfr09 > 90, 90, egfr09))"

meth[c("qrisk_smok")]="~I(ifelse(packyrs == 0, 1,
    ifelse(packyr5363 == 0 & packyrs > 0, 2,
    ifelse(packyrs > 0 & packyr5363 <= 5, 3,
    ifelse(packyr5363 > 5 & packyr5363 <= 10, 4, 
    ifelse(packyr5363 > 10, 5, NA))))
)
)"

meth[c("ckd345")]="~I(ifelse(CKD_prev == 1 & egfr09 < 60, 1, 0))"

meth[c("protectivefactors_new")]="~I(
normal_birthweight + high_ses + obtained_gcse + 
normal_adolescent_bmi + non_smoker + 
active + no_adversity)"

meth[c("protectivefactors_grouped_new")]="~I(ifelse(protectivefactors_new<2, 
3, protectivefactors_new))"

# Set variables which are not predictors

predM["id",] <- 0
predM[ , "id"] <- 0

predM["ConventionalAge60high",] <- 0
predM[ , "ConventionalAge60high"] <- 0
predM["BrainAge60high",] <- 0
predM[ , "BrainAge60high"] <- 0
predM["HeartAge60high",] <- 0
predM[ , "HeartAge60high"] <- 0
predM["LungAge60high",] <- 0
predM[ , "LungAge60high"] <- 0
predM["LiverAge60high",] <- 0
predM[ , "LiverAge60high"] <- 0
predM["KidneyAge60high",] <- 0
predM[ , "KidneyAge60high"] <- 0
predM["ImmuneAge60high",] <- 0
predM[ , "ImmuneAge60high"] <- 0
predM["ArteryAge60high",] <- 0
predM[ , "ArteryAge60high"] <- 0

predM["ConventionalPredAge60",] <- 0
predM[ , "ConventionalPredAge60"] <- 0
predM["BrainPredAge60",] <- 0
predM[ , "BrainPredAge60"] <- 0
predM["HeartPredAge60",] <- 0
predM[ , "HeartPredAge60"] <- 0
predM["LungPredAge60",] <- 0
predM[ , "LungPredAge60"] <- 0
predM["LiverPredAge60",] <- 0
predM[ , "LiverPredAge60"] <- 0
predM["KidneyPredAge60",] <- 0
predM[ , "KidneyPredAge60"] <- 0
predM["ImmunePredAge60",] <- 0
predM[ , "ImmunePredAge60"] <- 0
predM["ArteryPredAge60",] <- 0
predM[ , "ArteryPredAge60"] <- 0


predM["multiorgan60high",] <- 0
predM[ , "multiorgan60high"] <- 0
predM["multiorgan60high3max",] <- 0
predM[ , "multiorgan60high3max"] <- 0
predM["multiorgan60high4max",] <- 0
predM[ , "multiorgan60high4max"] <- 0
predM["multiorgan60high4max",] <- 0
predM[ , "multiorgan60high4max"] <- 0
predM["multiorganageing",] <- 0
predM[ , "multiorganageing"] <- 0

predM["months",] <- 0
predM[ , "months"] <- 0
predM[timevars,] <- 0
predM[ , timevars] <- 0
predM[prevvars,] <- 0
predM[ , prevvars] <- 0
predM["proteomicsampleage_months",] <- 0
predM[ , "proteomicsampleage_months"] <- 0
predM["death_monthssincesample",] <- 0
predM[ , "death_monthssincesample"] <- 0
predM["death_yearssincesample",] <- 0
predM[ , "death_yearssincesample"] <- 0
predM["packyrs",] <- 0
predM[ , "packyrs"] <- 0
predM["alcohol_intake",] <- 0
predM[ , "alcohol_intake"] <- 0
predM["high_ses",] <- 0
predM[ , "high_ses"] <- 0
predM["obtained_gcse",] <- 0
predM[ , "obtained_gcse"] <- 0
predM["adolescent_overweight",] <- 0
predM[ , "adolescent_overweight"] <- 0
predM["smoker",] <- 0
predM[ , "smoker"] <- 0
predM["mod_alcohol",] <- 0
predM[ , "mod_alcohol"] <- 0
predM["active",] <- 0
predM[ , "active"] <- 0
predM["adversity",] <- 0
predM[ , "adversity"] <- 0
predM["alcoholcategory",] <- 0
predM[ , "alcoholcategory"] <- 0
predM["activecategory",] <- 0
predM[ , "activecategory"] <- 0
predM["normal_birthweight",] <- 0
predM[ , "normal_birthweight"] <- 0
predM["normal_adolescent_bmi",] <- 0
predM[ , "normal_adolescent_bmi"] <- 0
predM["non_smoker",] <- 0
predM[ , "non_smoker"] <- 0
predM["no_adversity",] <- 0
predM[ , "no_adversity"] <- 0
predM["prof",] <- 0
predM[ , "prof"] <- 0
predM["cars01", c("lhqr", "bnf421", "bnf634", "wtn09", "Diabetes_event", "T2DM_event", "SLE_event")] <- 0
predM["cars01_z",] <- 0
predM[ , "cars01_z"] <- 0
predM["chol_hdl",] <- 0
predM[ , "chol_hdl"] <- 0
predM["sbp_sd",] <- 0
predM[ , "sbp_sd"] <- 0
predM["egfr09_adj",] <- 0
predM[ , "egfr09_adj"] <- 0
predM["qrisk_smok",] <- 0
predM[ , "qrisk_smok"] <- 0
predM["protectivefactors_new",] <- 0
predM[ , "protectivefactors_new"] <- 0
predM["protectivefactors_grouped_new",] <- 0
predM[ , "protectivefactors_grouped_new"] <- 0

# Check method and sequence

init = mice(dataset,method=meth,predictorMatrix=predM, 
maxit=0, seed=500)

init$method
init$visitSequence

#### IMPUTATION ####

# Impute (~ 562 minutes to run -> 9 hrs 23 mins)

set.seed(123)

imputed_data <- mice(dataset, 
predictorMatrix=predM, m=30, 
method=meth, maxit=50, printFlag=TRUE)

#### OUTPUT FILES ####

# Save imputed datasets

rm(list=setdiff(ls(), "imputed_data"))

out1 <- file.path(getwd(), "8. Aim 3 - Modifiable risk factor associations")
out2 <- file.path(getwd(), "9. Aim 4 - Specific proteins connected to mortality & modifiable risk")

save.image(file = file.path(out1,"imp_data.RData"))

save.image(file = file.path(out2,"imp_data.RData"))

#### POST-IMPUTATION CHECKS ####

# Logged events

imputed_data$loggedEvents

# Inspect dataset

dataset1 <- complete(imputed_data, 1)

# Visual plots

bwt <- plot(imputed_data, lowbwt~ .it | .ms, layout=c(2,1))

ses_edu <- plot(imputed_data, chsc + lhqr ~ .it | .ms, layout=c(2,2))

bmi <- plot(
  imputed_data, bmi61u + bmi66u + bmi72u + 
    bmi82u + bmi89u + bmi99u + bmi09 ~ .it | .ms, layout=c(4,4))

smoking <- plot(
  imputed_data, packyr20 + packyr2025 + packyr3136 + 
    packyr3643 + packyr4353 +packyr5363 + packyrs ~ .it | .ms, layout=c(4,4))

alcohol  <- plot(
  imputed_data, avalc82u + avalc89u + avalc99u + 
    avalc09u + alcohol_intake~ .it | .ms, layout=c(5,5))

exercise <- plot(
  imputed_data, exer82 + exer89x + exer99x + 
    exer09x ~ .it | .ms,  layout=c(3,3))

adversity <- plot(imputed_data, 
                  CROW15y + amenities + housecondition + 
                    childSES  + phy16 + finance36 + employed36 +     
                    amenities26 + crow26  + work36 + work4353 +       
                    finance4353 + housecondition43 + work63 +          
                    finance63  + matsep +       
                    peers + social36  + divorce36 +       
                    support4353 + lostcontact4353 + chdconflict4353 +  
                    divorce4353 + social4353 + support63 +       
                    lostcontact63 + chdconflict63 + divorce63 + social63
                  ~ .it | .ms,  layout=c(8,8))

other_variables <- plot(
  imputed_data, disa15x + chron19tot15x +
    summhealth15x ~ .it | .ms,  layout=c(3,3))

# Summary table comparing original and imputed values

# Convert mids object to long format 
long_data <- complete(imputed_data, "long", include = TRUE)

# Split observed and imputed
observed <- long_data %>% filter(.imp == 0)
imputed  <- long_data %>% filter(.imp > 0)

# Variables
cont_vars <- c("bmi61u",
               "packyr20","packyr2025","packyr2531","packyr3136",
               "packyr3643","packyr4353","packyr5363",
               "avalc82u","avalc89u","avalc99u","avalc09u")
cat_vars  <- c("lowbwt", "chsc","lhqr",
               "exer82","exer89x","exer99x","exer09x")


# Summary for continuous variables 
summarise_cont <- function(data, var) {
  x <- data[[var]]
  m <- mean(x, na.rm=TRUE)
  s <- sd(x, na.rm=TRUE)
  sprintf("%.2f (%.2f)", m, s)
}

# Summary for categorical/binary variables
summarise_cat <- function(data, var) {
  tbl <- prop.table(table(data[[var]]))
  paste0(names(tbl), "=", sprintf("%.1f%%", 100*tbl), collapse=", ")
}

# Build table 

# Continuous rows
cont_rows <- lapply(cont_vars, function(v) {
  data.frame(
    Variable = v,
    Type = "Continuous",
    Observed = summarise_cont(observed, v),
    Imputed = summarise_cont(imputed, v)
  )
}) %>% bind_rows()

# Categorical rows
cat_rows <- lapply(cat_vars, function(v) {
  data.frame(
    Variable = v,
    Type = "Categorical",
    Observed = summarise_cat(observed, v),
    Imputed = summarise_cat(imputed, v)
  )
}) %>% bind_rows()

# Combine
summary_table <- bind_rows(cont_rows, cat_rows)

# View table
write.csv(summary_table, 
          "imputed_observed_table.csv",row.names=FALSE)

# Save Data

rm(list=setdiff(ls(), "imputed_data"))

save.image(file="S:/LHA_JG0923/Proteomic Ageing Project/Final Scripts & Data/8. Aim 3 - Modifiable risk factor associations/imp_data.RData")

save.image(file="S:/LHA_JG0923/Proteomic Ageing Project/Final Scripts & Data/9. Aim 4 - Specific proteins connected to mortality & modifiable risk/imp_data.RData")

