# AUTHOR:   K. Srikanth | USAID
# PURPOSE:  prep dp output for Tableau
# REF ID:   7b1acb5c 
# LICENSE:  MIT
# DATE:     2023-02-27
# UPDATED: 

# DEPENDENCIES ------------------------------------------------------------

library(gagglr)
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

tst_folder <- "Data/draft_tst"

path <- tst_folder %>% 
  return_latest("MASTER TOOL_Target Setting Tool_South Africa_20230214202141")

df_msd <- si_path() %>% 
  return_latest("MER_Structured_Datasets_PSNU_IM_FY21-23_20230210_v1_1_South Africa") %>% 
  read_psd() %>% 
  resolve_knownissues()

data_folder <- "Data/"



# IMPORT  -------------------------------------------------------------------

#import all tabs
dp <- tame_dp(path)

#grab PLHIV tab for validations
dp_plhiv <- tame_dp(path, type = 'PLHIV')

#import psnu agency mapping
psnu_map <- data_folder %>% 
  return_latest("psnu_agency_ref.xlsx") %>% 
  read_excel()

# FILTER DP -------------------------------------------------------------


# check which psnus dont have agency mappings

# psnus_no_agency <- dp %>% 
#   left_join(psnu_map, by =c("psnu")) %>% 
#   filter(is.na(funding_agency)) %>% 
#   distinct(psnu) %>% pull()
# 
# 
# df_msd %>% 
#   filter(psnu %in% psnus_no_agency) %>% 
#   count(psnu, funding_agency)

# filter DP, join PSNU map and mutate FY
dp_filtered <- dp %>%
  clean_indicator() %>% 
  filter(fiscal_year == 2024) %>% 
  left_join(psnu_map, by =c("psnu")) %>% 
  relocate(funding_agency, .before = 17) %>% 
  select(-c(country)) %>% 
  mutate(fiscal_year = as.character(fiscal_year)) %>% 
  mutate(fiscal_year = str_replace(fiscal_year, "20", "FY"))

# filter PLHIV tab of dp and do the same munging
dp_plhiv_filtered <- dp_plhiv %>%
  clean_indicator() %>%
  left_join(psnu_map, by =c("psnu")) %>% 
  select(-c(country)) %>% 
  mutate(fiscal_year = as.character(fiscal_year)) %>% 
  mutate(fiscal_year = str_replace(fiscal_year, "20", "FY")) %>%
  mutate(standardizeddisaggregate = ifelse(indicator == "PLHIV_Residents", "Age/Sex/HIVStatus", standardizeddisaggregate)) %>% 
  mutate(indicator = ifelse(indicator == "PLHIV_Residents", "PLHIV", indicator))

#bind plhiv and all tabs for import into Tableau
dp_final <- bind_rows(dp_filtered, dp_plhiv_filtered) %>% 
    mutate(agency_lookback = funding_agency)

#recode snuprioritization

dp_final <- dp_final %>% 
  mutate(snuprioritization = recode(snuprioritization,
                                    "2 - Scale-up: Aggressive" = "2 - Scale-Up: Aggressive",
                                    "1 - Scale-up: Saturation" = "1 - Scale-Up: Saturation")) 

today <- lubridate::today()



# write_csv(dp_plhiv_filtered, "Dataout/cop-validation-plhiv.csv")  
# write_csv(dp_filtered, "Dataout/cop-validation-tameDP.csv")  

write_csv(dp_final, glue::glue("Dataout/cop-validation-dp-all_v3_{today}.csv"))







# # MUNGE -------------------------------------------------------------------
# 
# #check rollup - this looks good (need to bring in net_new as well as ART coverage)
# dp_casc %>% 
#   clean_indicator() %>% 
#   # str() %>% 
#   group_by(operatingunit, fiscal_year, indicator) %>% 
#   summarise(across(c(targets, cumulative), sum, na.rm = TRUE)) %>% 
#   ungroup()
#

