# DHS- and LSMS-based datasets

This folder contains code for creating the DHS- and LSMS-based poverty, health, education, and infrastructure datasets. This includes generating the labels as well as downloading the input satellite images.

This README file describes the following procedures:

1. Setup
2. Download and process DHS data
2. TODO

## Setup

The recommended way to run these scripts is to set up and activate the conda environment described by the `env_create.yml` file in the root folder of this git repo:

```bash
conda env update -f env_create.yml --prune
conda activate sustainbench_create
```

Importantly, we use both Python 3.9 and R 4.1.

Note that in the R scripts, we use the following coding convention:
- Functions in default packages (e.g., base, utils) as well as the 8 core [tidyverse](https://www.tidyverse.org/) packages are not prefixed.
- Functions from all other packages (e.g., foreign, jsonlite, readstata13), including non-core tidyverse packages, are prefixed for clarity.


## Download and process DHS data

**Downloading DHS data**

Before downloading survey data, you must first register as a user on the [DHS Program data website](https://dhsprogram.com/data/dataset_admin) and request for dataset access ([instructions here](https://dhsprogram.com/data/Access-Instructions.cfm)). Replace the placeholders in the `dhs_utils/pat.R` file with your actual username and password. ("pat" is short for "personal access token.")

The main script for downloading and cleaning survey data is `1_create_dhs_labels.R`. It assumes the following data folder structure:

```
dhs_data/
  clean/
    [CC][DD][VV][FF]_YYYY-MM-DD.RDS
    log.csv
  output/
  raw/         # unmodified survey data downloaded from DHS website
    [CC][DD][VV][FF].DTA
    [CC][DD][VV][FF].DBF
    log.csv
```

For v1 of the SustainBench dataset, we downloaded data from all surveys that satisfied the following criteria:
- survey year: >= 1996
  - We chose 1996 as the start year because that is the first year that calibrated DMSP-OLS nighttime lights are available.
  - As of August 6, 2021, the most recent survey year available is 2019.
  - By "survey year," we mean the value of the `SurveyYear` attribute in the [DHS Program API](https://api.dhsprogram.com/rest/dhs/surveys), even if fieldwork for that survey was conducted across more than 1 calendar year.
- survey type: one of "Standard", "Special", "Continuous", "MIS", or "Interim"
  - See the [DHS Methodology website](https://dhsprogram.com/Methodology/Survey-Types/) for more information on DHS survey types

For each survey matching the above criteria, we downloaded Household Recode (HR) and Individual Recode (IR) data in Stata format as ZIP files, from which we extracted the Stata Dataset (.DTA) file. We downloaded Geographic Data (GE) in "flat file" format as ZIP files, from which we extracted the DBF file. These extracted files are saved to the "dhs_data/raw" folder.

For example, for the [Albania 2017 Standard DHS survey](https://dhsprogram.com/data/dataset/Albania_Standard-DHS_2017.cfm), we downloaded
```
ALGE71FL.ZIP  # geographic data
ALHR71DT.ZIP  # household recode, Stata format
ALIR71DT.ZIP  # individual recode, Stata format
```
from which we extracted the following files:
```
ALGE71FL.DBF  # geographic data
ALHR71FL.DTA  # household recode, Stata format
ALIR71FL.DTA  # individual recode, Stata format
```

The `dhs_data/raw/log.csv` file tracks the complete list of files downloaded and extracted; this CSV contains 3 columns:
- "filename": name of file extracted from ZIP file downloaded from DHS website
- "download_date": in `YYYY-MM-DD` format, date when file was downloaded and extracted from ZIP file
- "year": survey year

**Cleaning DHS data**

Once the data files are downloaded, we process the data files and save a "clean" version in the "dhs_data/clean" folder. The processed data files are tracked in `dhs_data/clean/log.csv`, which contains 4 columns:
- "clean_file": name of "cleaned" data file
- "orig_file": matches "filename" column from `raw/log.csv`
- "year": survey year
- "date": in `YYYY-MM-DD` format, date when the file was "cleaned"

For all data, we create a new column "DHSID_EA" which gives each surveyed cluster an ID which is unique across the entire SustainBench dataset. This "DHSID_EA" column has the format `[CC]-[YYYY]-[V]-[cluster_id]`, where `[CC][YYYY]` is the two-letter country code followed by the survey year, `[V]` indicates the survey round and what version (as uploaded by DHS) the data is, and `[cluster_id]` is the cluster unique only within that survey. Additionally, we create a household id "DHSID_HH" (the cluster id, with the household id appended) and a mother id for the individual recode (the household id with mother identifier appended).

For geographic (GE) data, clusters whose latitude and longitude are `(0,0)`, [which indicates a missing value](https://dhsprogram.com/Methodology/upload/MEASURE-DHS-GPS-Data-Format.pdf), are set to `(lat,lon) = NA` instead. This "cleaned" geographic data is saved as a `.RDS` file in the "dhs_data/clean" folder.

For the household (HR) and individual (IR) data,


TODO: make a note about surveys for which geo data is not provided.


**Creating labels**

After the DHS survey data is downloaded and "cleaned," we remove clusters whose geocoordinates (lat,lon) are unknown. Then we create the following labels:
- **asset_index**: first principal component of asset variables, computed for each household, then averaged within each DHS cluster
  - the asset variables are: "rooms", "electric", "phone", "radio", "tv", "car", "fridge", "motorcycle", "floor_qual", "toilet_qual", "water_qual"
- **infrastructure_index**: first principal component of infrastructure, computed for each household, then averaged within each DHS cluster
  - the infrastructure variables are: "electric", "toilet_qual", "water_qual"
  - note that these variables are a subset of the asset variables
- **under5_mort**: TODO
- **mother_edu**: TODO
- **mother_bmi**: TODO, mention excluding pregnant women

After computing the labels, we then exclude clusters that have fewer than 5 household observations. This helps reduce the number of outlier values.

In the asset index, the floor, toilet, and water variables are originally provided via categorical codes. See variables HV213 (floor), HV205 (toilet), and HV201 (water) in the [DHS Recode Manuals and Maps](https://dhsprogram.com/publications/publication-dhsg4-dhs-questionnaires-and-manuals.cfm). We first convert these codes to a categorical number between 1 and 5 (inclusive), where 1 indicates least expensive, and 5 indicates most expensive. The conversion tables between the original codes and the 1-5 scale are provided in the recode CSVs in the `DHS/recode` folder.

TODO(anne): how was the 1-5 scale determined? The DHS Recode Maps don't actually list all of the possible values listed in the recode CSVs.


## Download and process LSMS data

Download files from the LSMS Microdata website. We downloaded CSV files when available, and Stata files otherwise. The folder structure under `lsms_data/raw` should look as follows:

```
Uganda/
    recode/
        ...
    UGA_2005_2009_UNPS_v01_M_Stata8.zip
    UGA_2013_UNPS_v01_M_STATA8.zip
```

TODO: check that recode folders have been added to Git.

## Download Landsat and nightlights imagery

TODO