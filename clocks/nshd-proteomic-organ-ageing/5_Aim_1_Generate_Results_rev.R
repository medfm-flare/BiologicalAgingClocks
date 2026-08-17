# ============================================================
# 6_Aim_1_Generate_Results.R
# Purpose: Aim 1 analysis - Explore proteomic organ ageing heterogeneity
# Input: Cleaned merged dataset
# Author: James Groves
# Date: 2026-03-28
# ============================================================

#### SET-UP ####

# Packages

library(tidyverse)
library(readxl)
library(broom)
library(haven)
library(openxlsx)
library(ggridges)

# Directory

inp <- file.path(getwd(), "6. Aim 1 - Organ age distributions")
out <- file.path(getwd(), "6. Aim 1 - Organ age distributions")

#### LOAD DATA ####

# Load data 

load(file.path(inp,"dataset_inc.RData"))

# Adjust columns for display

organs <- c(
  "Conventional", "Brain", "Heart", "Lung",
  "Liver", "Kidney", "Immune", "Artery"
  )

dataset <- dataset %>% 
  rename(Conventional=ConventionalAge60,
  Brain=BrainAge60,
  Heart=HeartAge60,
  Lung=LungAge60,
  Liver=LiverAge60,
  Kidney=KidneyAge60,
  Immune=ImmuneAge60,
  Artery=ArteryAge60)

#### DESCRIPTIVES ####

# Organ age descriptive statistics 

organs_dist <- dataset %>%
  select(all_of(organs)) %>%
  pivot_longer(cols=everything(), 
  names_to="variable", values_to="value") %>%
  mutate(variable=factor(variable, levels=organs)) %>%
  group_by(variable) %>%
  summarise(mean=mean(value),
  sd=sd(value),min=min(value),max=max(value),
  .groups="drop")

organs_dist <- organs_dist %>% 
  rename(
    Organ=variable,
    "Age gap, mean" = mean,
    "Age gap, sd" = sd, 
    "Age gap, minimum" = min,
    "Age gap, maximum" = max
    )

#### MODEL PERFORMANCE ####

organ_names <- c("Conventional", "Brain", "Heart", "Lung", 
                 "Liver", "Kidney", "Immune", "Artery")

perf <- do.call(rbind, lapply(organ_names, function(org) {
  
  pred_var <- paste0(org, "PredAge60")
  
  temp <- dataset[complete.cases(dataset[, c("Age60", pred_var)]), c("Age60", pred_var)]
  
  data.frame(
    Organ = org,
    Pearson_r = cor(temp[[pred_var]], temp$Age60, method = "pearson"),
    MAE = mean(abs(temp[[pred_var]] - temp$Age60)),
    RMSE = sqrt(mean((temp[[pred_var]] - temp$Age60)^2))
  )
}))

rownames(perf) <- NULL

#### CORRELATION & COMBINATIONS ####

# Correlation matrix

organ_cor_matrix <- as.data.frame(
  cor(
  dataset[, organs], 
  use="complete.obs", 
  method="pearson"))

# Extreme ageing combinations: 2 organs

comb_2 <- dataset %>% 
  filter(as.numeric(multiorgan60high)>2)

comb_2 <- comb_2 %>% 
  subset(select=c(
  id, BrainAge60high, ImmuneAge60high, ArteryAge60high,
  HeartAge60high, KidneyAge60high, LiverAge60high, 
  LungAge60high))

comb_2 <- comb_2 %>% rename(
  Brain = BrainAge60high, 
  Immune = ImmuneAge60high, 
  Artery = ArteryAge60high,
  Heart = HeartAge60high, 
  Kidney = KidneyAge60high, 
  Liver = LiverAge60high,
  Lung = LungAge60high)

ext_org <- c(
  "Brain", "Heart", "Lung", "Liver", 
  "Kidney", "Immune", "Artery"
  )

c_2 <- combn(ext_org, 2, simplify=FALSE)

for (c in c_2) {
  
  col <- paste(c, collapse="_")
  
  comb_2[[col]] <- ifelse(
  rowSums(comb_2[, c]==1)==2,1,0)

  }

sums_2 <- colSums(
  comb_2[ , !names(comb_2) %in% ext_org])

sums2_df <- data.frame(
  Combination = names(sums_2),
  Individuals = sums_2
)

sums2_df <- sums2_df[-1, ]

rownames(sums2_df) <- NULL

sums2_df <- sums2_df %>%
  arrange(desc(Individuals))

# Extreme ageing combinations: 2 organs

comb_3 <- dataset %>% filter(as.numeric(multiorgan60high)>3)

comb_3 <- comb_3 %>% subset(
  select=c(id, BrainAge60high, ImmuneAge60high, ArteryAge60high,
  HeartAge60high, KidneyAge60high, LiverAge60high, LungAge60high))

comb_3 <- comb_3 %>% rename(
  Brain = BrainAge60high, 
  Immune = ImmuneAge60high, 
  Artery = ArteryAge60high,
  Heart = HeartAge60high, 
  Kidney = KidneyAge60high, 
  Liver = LiverAge60high,
  Lung = LungAge60high)

c_3 <- combn(ext_org, 3, simplify=FALSE)

for (c in c_3) {
  
  col <- paste(c, collapse="_")
  
  comb_3[[col]] <- ifelse(
rowSums(comb_3[, c]==1)==3,1,0)
  
}

sums_3 <- colSums(
  comb_3[,!names(comb_3) %in% ext_org])

sums3_df <- data.frame(
  Combination = names(sums_3),
  Individuals = sums_3)

sums3_df <- sums3_df[-1, ]

rownames(sums3_df) <- NULL

sums3_df <- sums3_df %>%
  arrange(desc(Individuals))

#### OUTPUTS ####

res <- createWorkbook()

# ST3: Distributions
addWorksheet(res, "ST3.Organ age stats")
writeData(res, "ST3.Organ age stats", organs_dist)

# ST4: Model performance
addWorksheet(res, "ST4.Model performance")
writeData(res, "ST4.Model performance", perf)

# ST5: Correlation
addWorksheet(res, "ST5.Organ age correlations")
writeData(res, "ST5.Organ age correlations", organ_cor_matrix)

# ST6: Extreme ageing combinations
addWorksheet(res, "ST6.Extreme ageing combinations")
writeData(res, "ST6.Extreme ageing combinations", sums2_df)
writeData(res, "ST6.Extreme ageing combinations", 
sums3_df, startRow=25, startCol=1)

# Save
saveWorkbook(res, file.path(out, "Aim_1_ST.xlsx"), overwrite = T)

# Source code files

sc <- createWorkbook()

# Ext Data Fig 2a
addWorksheet(sc, "Ext Data Fig 2a")
writeData(sc, "Ext Data Fig 2a", organ_cor_matrix)

# Ext Data Fig 2b
addWorksheet(sc, "Ext Data Fig 2b")
writeData(sc, "Ext Data Fig 2b", sums2_df)
writeData(sc, "Ext Data Fig 2b", 
sums3_df, startRow=25, startCol=1)

saveWorkbook(sc,"SC_Aim_1.xlsx", overwrite=TRUE)

#### VISUALISATION ####

colors <- list(Conventional = "#F39B7FFF", Brain = "#4DBBD5FF", Heart = "#DC0000FF", Lung = "#3C5488FF", Liver = "#7E6148FF", Kidney = "#8491B4", Immune = "#00A087FF", Artery = "#B09C85FF")

# Organ age distributions

for (organ in organs) {
  
  age60_col <- paste0(organ, "Age60")
  
  plot60 <- ggplot(dataset, aes_string(x=age60_col)) + 
    geom_density(alpha = 0.5, fill = colors[[organ]], color = "black") +
    geom_vline(xintercept=0, color="black", lty=2, lwd=.3) + 
    labs(title= "", x="", y="") + 
    theme_classic() +
    scale_x_continuous(expand = c(0,0), limits=c(-20,20)) +
    scale_y_continuous(expand = c(0,0), limits=c(0,0.25))
  
  ggsave(filename=paste0("Fig2",organ,".pdf"), plot=plot60, width = 3.6, height = 2.5)
  
}

# AVOS distribution

plot60 <- ggplot(dataset, aes(x = scale(avos))) + 
  geom_density(alpha = 0.5, fill = "purple", color = "black") +
  geom_vline(xintercept=0, color="black", lty=2, lwd=.3) + 
  labs(title= "", x="", y="") + 
  theme_classic() +
  scale_x_continuous(expand = c(0,0), limits=c(-3,3)) + 
  scale_y_continuous(expand = c(0,0))

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/Fig2avos.pdf"), plot=plot60, width = 3.6, height = 2.5)

# Chronological age distribution

p <- ggplot(dataset, aes(x = Age60)) + 
  geom_histogram(binwidth = 1, fill = "#7F7F7F", color = "black") + 
  scale_x_continuous(expand = c(0, 0), limits = c(60, 66)) + #, breaks = seq(2006, 2024, by = 2)) + 
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1000)) + 
#  geom_v_line(xintercept=2020, color="red") +
  theme_classic() 

p

ggsave(filename=paste0("FigX3a.pdf"), plot=p, width = 6, height = 3)

# Predicted age scatter plots

# Conventional

fit <- lm(ConventionalPredAge60 ~ Age60, data = dataset)
dataset$resid_conv <- resid(fit)

p <- ggplot(dataset, aes(x=Age60, y=ConventionalPredAge60)) + 
  geom_point(alpha = 0.5, size = 1.2, color = "#F39B7FFF") + 
  coord_fixed(
    ratio = 1,
    xlim = c(60, 65), 
    ylim = c(55, 85)
  ) + 
  geom_smooth(method = "lm", color = "black", se = F) +
  theme_classic()

p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX3b_conv.pdf"), plot=p, width = 2, height = 6)

# Brain

p <- ggplot(dataset, aes(x=Age60, y=BrainPredAge60)) + 
  geom_point(alpha = 0.5, size = 1.2, color = "#4DBBD5FF") + 
  coord_fixed(
    ratio = 1,
    xlim = c(60, 65), 
    ylim = c(55, 85)
  ) + 
  geom_smooth(method = "lm", color = "black", se = F) +
  theme_classic()

p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX3b_brain.pdf"), plot=p, width = 2, height = 6)

# Heart

p <- ggplot(dataset, aes(x=Age60, y=HeartPredAge60)) + 
  geom_point(alpha = 0.5, size = 1.2, color = "#DC0000FF") + 
  coord_fixed(
    ratio = 1,
    xlim = c(60, 65), 
    ylim = c(55, 85)
  ) + 
  geom_smooth(method = "lm", color = "black", se = F) +
  theme_classic()

p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX3b_heart.pdf"), plot=p, width = 2, height = 6)

# Lung

p <- ggplot(dataset, aes(x=Age60, y=LungPredAge60)) + 
  geom_point(alpha = 0.5, size = 1.2, color = "#3C5488FF") + 
  coord_fixed(
    ratio = 1,
    xlim = c(60, 65), 
    ylim = c(55, 85)
  ) + 
  geom_smooth(method = "lm", color = "black", se = F) +
  theme_classic()

p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX3b_lung.pdf"), plot=p, width = 2, height = 6)


# Liver

p <- ggplot(dataset, aes(x=Age60, y=LiverPredAge60)) + 
  geom_point(alpha = 0.5, size = 1.2, color = "#7E6148FF") + 
  coord_fixed(
    ratio = 1,
    xlim = c(60, 65), 
    ylim = c(55, 85)
  ) + 
  geom_smooth(method = "lm", color = "black", se = F) +
  theme_classic()

p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX3b_liver.pdf"), plot=p, width = 2, height = 6)

# Kidney

p <- ggplot(dataset, aes(x=Age60, y=KidneyPredAge60)) + 
  geom_point(alpha = 0.5, size = 1.2, color = "#8491B4") + 
  coord_fixed(
    ratio = 1,
    xlim = c(60, 65), 
    ylim = c(55, 85)
  ) + 
  geom_smooth(method = "lm", color = "black", se = F) +
  theme_classic()

p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX3b_kidney.pdf"), plot=p, width = 2, height = 6)

# Immune

p <- ggplot(dataset, aes(x=Age60, y=ImmunePredAge60)) + 
  geom_point(alpha = 0.5, size = 1.2, color = "#00A087FF") + 
  coord_fixed(
    ratio = 1,
    xlim = c(60, 65), 
    ylim = c(55, 85)
  ) + 
  geom_smooth(method = "lm", color = "black", se = F) +
  theme_classic()

p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX3b_immune.pdf"), plot=p, width = 2, height = 6)

# Artery

p <- ggplot(dataset, aes(x=Age60, y=ArteryPredAge60)) + 
  geom_point(alpha = 0.5, size = 1.2, color = "#B09C85FF") + 
  coord_fixed(
    ratio = 1,
    xlim = c(60, 65), 
    ylim = c(55, 85)
  ) + 
  geom_smooth(method = "lm", color = "black", se = F) +
  theme_classic()

p

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX3b_artery.pdf"), plot=p, width = 2, height = 6)

# Biological heterogeneity at same chronological age

order <- c("Conventional", "Brain", "Heart", "Lung",
           "Liver", "Kidney", "Immune", "Artery")

long_data <- dataset %>%
  select(
    Age60,
    Conventional,
    Brain,
    Heart,
    Lung,
    Liver,
    Kidney,
    Immune,
    Artery
  ) %>%
  pivot_longer(
    cols = -Age60,
    names_to = "Clock",
    values_to = "PredictedAge"
  ) %>%
  mutate(
    age_floor = floor(Age60)
  ) %>%
  mutate(
    age_floor = factor(age_floor)
  ) %>%
  filter(!(age_floor == 65)) %>%
  mutate(
    Clock = factor(Clock, levels = order)
  ) %>%
  mutate(
    age_floor = factor(age_floor, levels = rev(60:64))
  )

ridge <- ggplot(long_data,
       aes(x = PredictedAge,
           y = age_floor,
           fill = Clock)) +
  geom_density_ridges(
    alpha = 0.8,
    scale = 1.05,
    color = "black",      # black outline
    size = 0.4            # outline thickness
  ) +
  facet_wrap(~ Clock, nrow = 2) +
  scale_fill_manual(values = colors, guide = "none") +
  coord_cartesian(xlim = range(long_data$PredictedAge, na.rm = TRUE)) +
  geom_hline(yintercept = 1:length(unique(long_data$age_floor)),
             color = "black", linewidth = 0.3) +
  geom_vline(xintercept=0, color="black", lty=2, lwd=.3) + 
  theme_classic() +
  labs(
    x = "Predicted age",
    y = "Chronological age"
  )

ggsave(filename=paste0("S:/LHA_JG0923/Revision/Final_export/FigX3c.pdf"), plot = ridge, width = 8, height = 6)
