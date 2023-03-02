# AUTHOR:   K. Srikanth | USAID
# PURPOSE:  
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


# MUNGE -------------------------------------------------------------------

# add agency look back

df_filtered <- df_msd %>% 
  filter(fiscal_year %in% c(2022, 2023)) %>% #filter to 2022 and 2023
  select(any_of(cols), mech_code) %>% #select columns in DP + mech_code
  left_join(psnu_crosswalk, by = c("psnu", "psnuuid")) %>% #add shortname to join DSP crosswalk
  mutate(dspid = str_c(mech_code, short_name)) %>% #create dspid 
  left_join(dsp_crosswalk %>% select(-c(mechanism_id)), by = c("dspid")) #join dsp crosswalk for lookback



# EXPORT ---------------------------------------------------------------

write_csv(df_filtered, "Dataout/FY23Q1_PSNUxIM_SA_filtered.csv")
