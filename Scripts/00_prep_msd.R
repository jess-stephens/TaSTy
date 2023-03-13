# AUTHOR:   K. Srikanth | USAID
# PURPOSE:  prepare PSNUxIM MSD for tableau
# REF ID:   8309dfcd 
# LICENSE:  MIT
# DATE:     2023-02-27
# UPDATED: 

# DEPENDENCIES ------------------------------------------------------------

library(glamr)
library(tidyverse)
library(glitr)
library(gophr)
library(extrafont)
library(scales)
library(tidytext)
library(patchwork)
library(ggtext)
library(glue)
library(readxl)
library(googlesheets4)
library(tameDP)
library(datapackr)

# GLOBAL VARIABLES --------------------------------------------------------

path <- si_path() %>% 
  return_latest("Target Setting Tool_South Africa_20230214202141 v02.16 11h52") 

data_folder <- "Data/"





# IMPORT -------------------------------------------------------------------

#pull in DP columns
dp_cols <- tame_dp(path) %>% 
  names() 

#READ IN MSD
df_msd <- si_path() %>% 
  return_latest("MER_Structured_Datasets_PSNU_IM_FY21-23_20230210_v1_1_South Africa") %>% 
  read_psd() %>% 
  resolve_knownissues()

#grab original PSNU map for fundign agency
psnu_map <- data_folder %>% 
  return_latest("psnu_agency_ref.xlsx") %>% 
  read_excel()


#PSNU UID crosswalk

psnu_crosswalk <- data_folder %>% 
  return_latest("PSNU ID_02032023.xlsx") %>% 
  read_excel() %>% 
  janitor::clean_names()

#DSP map
dsp_crosswalk <- data_folder %>% 
  return_latest("dsp_attributes_2022-05-17.xlsx") %>% 
  read_excel() %>% 
  janitor::clean_names()

msd_disagg_map <- data_folder %>% 
  return_latest("msd_disagg_mapping.xlsx") %>% 
  read_excel()


# MUNGE -------------------------------------------------------------------

# add agency look back

df_filtered <- df_msd %>% 
 # filter(fiscal_year %in% c(2022, 2023)) %>% #filter to 2022 and 2023
  select(any_of(dp_cols),funding_agency, mech_code) %>% #select columns in DP + mech_code
  left_join(psnu_crosswalk, by = c("psnu", "psnuuid")) %>% #add shortname to join DSP crosswalk
  mutate(dspid = str_c(mech_code, short_name)) %>% #create dspid 
  left_join(dsp_crosswalk %>% select(-c(mechanism_id)), by = c("dspid")) #join dsp crosswalk for lookback

#join agency lookmap and mutate FY
df_filtered <- df_filtered %>% 
  semi_join(msd_disagg_map, by = c("indicator", "numeratordenom", "standardizeddisaggregate")) %>% 
  clean_indicator() %>% 
  mutate(fiscal_year = as.character(fiscal_year)) %>% 
  mutate(fiscal_year = str_replace(fiscal_year, "20", "FY"))


#mutate age bands
  #gend_gbv does not have age bands for new targets

age_map <- data_folder %>% 
  return_latest("age_mapping.xlsx") %>% 
  read_excel()
  
df_age_adj <- df_filtered %>% 
  left_join(age_map, by = c("indicator", "ageasentered" = "age_msd")) %>% 
  mutate(age_dp = ifelse(is.na(age_dp), ageasentered, age_dp)) %>% 
  select(-ageasentered) %>% 
  # mutate(cumulative = ifelse(is.na(cumulative), 0, cumulative)) %>% 
  # mutate(targets = ifelse(is.na(cumulative), 0, cumulative)) %>% 
  group_by(across(-c(cumulative, targets))) %>% 
 # group_by_all() %>% 
 # group_by(indicator, fiscal_year, standardizeddisaggregate, age_dp) %>% 
  summarise(across(c(cumulative, targets), sum, na.rm = TRUE), .groups = "drop") 

df_msd_final <- df_age_adj %>% 
  select(-c(country)) %>% 
  relocate(age_dp, .after = 8) %>% 
  relocate(any_of(c("cumulative", "targets")), .after = 13) %>% 
  relocate(funding_agency, .after = 15) %>% 
  rename(ageasentered = age_dp) 


# df_msd_final %>% 
#   filter(indicator == "TX_NEW",
#          fiscal_year == "FY21",
#          snuprioritization != "5 - Centrally Supported") %>% 
#   group_by(fiscal_year, indicator) %>% 
#   summarise(across(c(cumulative, targets), sum, na.rm = TRUE), .groups = "drop") 


  

# EXPORT ---------------------------------------------------------------

today <- lubridate::today()

write_csv(df_msd_final, glue::glue("Dataout/cop-validation-msd_v2_{today}.csv"))



