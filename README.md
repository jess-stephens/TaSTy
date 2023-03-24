# TaSTy
COP23 TaST Analytics

The purpose of this project is to process the TaST and historic results/targets from the MER Structured Dataset to leverage during the COP23 Target setting process. The outputs from this project will be added to a Tableau workbook, that allows the user to explore the targets and validations easily.

There are 2 primary scripts into this repo.

The **first** script, `00_prep_msd.R` will process the historic results and targets from the most recent PSNUxIM MSD, into a tidy and cleaned up file for import into the Tableau tool. This step will only need to be run **once**, as this data will not change with the updates to the TaST.

The **second** script, `01_prep_dp.R` will process the Target Setting Tool using the `tameDP` package to get a tidy extract of the TaST to pull into the Tableau tool. As such, whenever you have a new version of the TaST ready to explore, simply run this script over the new version of the TaST and swap out the TaST file in the Tableau tool.

## Setting up

To get started, you will want to make sure all of the required R packages are installed on your machine. If you do not have these packages installed, run the following code:

``` r

#install OHA packages
  remotes::install_github("USAID-OHA-SI/gagglr", build_vignettes = TRUE)
  remotes::install_github("USAID-OHA-SI/glamr", build_vignettes = TRUE)
  remotes::install_github("USAID-OHA-SI/gophr", build_vignettes = TRUE)
  remotes::install_github("USAID-OHA-SI/tameDP", build_vignettes = TRUE)
  
#install packages from CRAN
  install.packages("tidyverse")
  install.packages("glue")
  install.packages("googlesheets4")
  install.packages("readxl")
  install.packages("janitor")

```
Please also ensure that you have your `si_paths` set up, as the R scripts rely on this logic. If you do not have these set up, please follow the following steps:

1. Open the `TaSTy` project in an RProject
2. Load the `glamr` package and run the function `si_setup()`. Documentation can be found [here](https://usaid-oha-si.github.io/glamr/articles/project-workflow.html).
3. Load the `glamr` package and follow the steps outlined [here](https://usaid-oha-si.github.io/glamr/articles/project-workflow.html) to set up your `si_path()` using `glamr::set_paths()`
 
## R and Tableau Workflow

Once all your packages and folders are set up, you are good to go and should not need to repeat these steps.

Using `si_setup()`, there will be series of folders created in your R Project folder. For the South Africa team, please save the following files in the `Data` folder in your R Project as resources for the scripts to call on:

1. `dsp_attributes_2022-05-17.xlsx`
2. `PSNU ID_02032023.xlsx`
3. `psnu_agency_ref.xlsx`
4. `age_mapping.xlsx`
5. `msd_disagg_mapping.xlsx`


Now, you can begin to run the `00_prep_msd.R` and `01_prep_dp.R` scripts. Once these data are processed, the tidy files will be saved to the `Dataout` folder. As a reminder, you will only need to run the MSD processing script **once**.

From here, open up the Tableau tool and click on the `Data Source` tab. The data source will open with a prompt to update the union. Simply, switch out the new TaST file for the old version (or add both files into Tableau and convert to union if this is the first time). Refresh the union and the dashboard should be updated with the new data.

*Note*: The outputs from the scripts are in `.csv` format and sometimes are ingested into Tableau with the incorrect data types. Please ensure that the `cumulative` and `targets` columns are both `numeric` columns.


---

*Disclaimer: The findings, interpretation, and conclusions expressed herein are those of the authors and do not necessarily reflect the views of United States Agency for International Development. All errors remain our own.*
