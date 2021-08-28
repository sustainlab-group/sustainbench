# personal access tokens
# - includes two variables: dhs_account, dhs_password
source("dhs_utils/pat.R")
source("dhs_utils/cleaning_utils.R")
source("dhs_utils/scraping_utils.R")

library(haven)
library(RCurl)
library(data.table)
library(jsonlite)
library(curl)
library(rvest)
library(readstata13)
library(foreign)
library(tidyverse)
library(magrittr)


###############################################################################
# Written by: Anne Driscoll
# Download the DHS data, clean it, pull the relevant columns etc
###############################################################################

data_dir = "dhs_data"


###############################################################
# Download survey data
###############################################################

surveys = get_dhs_surveys_df() %>% filter(SurveyYear >= 1996)

download_from_dhs(surveys, username = dhs_account, password = dhs_password,
                  download_dir = file.path(data_dir, "raw"))


###############################################################
# Clean the location data
###############################################################

files = list.files(file.path(data_dir, "raw"))
files_ge = files[substr(files, 3, 4) == "GE"]

for (i in 1:length(files_ge)) {
  clean_dhs_file(raw_file = files_ge[i], data_dir = data_dir)
}


#--------------------------------------------------------------
# combine all the location data and save
#--------------------------------------------------------------

files_cleaned = list.files(file.path(data_dir, "clean"))
files_cleaned = files_cleaned[(files_cleaned != "log.csv") &
                              (substr(files_cleaned, 3, 4) == "GE")]
files_ge = as.list(rep(NA, length(files_cleaned)))
for (i in 1:length(files_cleaned)) {
  cur = read_rds(file.path(data_dir, "clean", files_cleaned[i]))
  files_ge[[i]] = unique(cur)
}
files_ge = bind_rows(files_ge) %>% drop_na(lat, lon)
write_csv(files_ge, file.path("output_labels", "dhs_locations.csv"))



###############################################################
# Clean all the other data
###############################################################

# get the GE filenames
log_raw = read_csv(file.path(data_dir, "raw", "log.csv"), col_types = list(
    filename = col_character(),
    download_date = col_character(),
    year = col_integer()
  )) %>%
  mutate(country = substr(filename, 1, 2),
         type = substr(filename, 3, 4),
         country_year = paste(country, year))

ge_files = log_raw %>% filter(type == "GE")

# get all HR and IR files that have GE files
files = log_raw %>%
  filter(type == "HR" | type == "IR",
         country_year %in% ge_files$country_year)
files = as.vector(files$filename)

for (i in 1:length(files)) {
  clean_dhs_file(raw_file = files[i], override = NULL,
                 data_dir = data_dir)
}


###############################################################
# Combine HR files and get relevant columns
###############################################################

load("dhs_data/recode/crosswalk_countries.rda")
country_years = build_combine_df(min_year = 1996, max_year = 2021,
                                 crosswalk_countries = crosswalk_countries,
                                 data_dir = data_dir)
dhs_hr = combine_dhs_files(country_years, type = "HR",
                           variables = c("hhid", "cname", "year",
                                         "hv000", "hv001", "hv005",
                                         "hv201", "hv205", "hv206",
                                         "hv207", "hv208", "hv209",
                                         "hv211", "hv212", "hv213",
                                         "hv216", "hv221", "hv243a",
                                         "hv013"),
                           data_dir = data_dir,
                           append = "fullHRdata")
# some checks
nrow(dhs_hr) #2,914,526
nrow(unique(dhs_hr[, c("cname", "year")])) # 180

# get crosswalks for coded variables
floor = read_csv("dhs_data/recode/floor_recode.csv")
water = read_csv("dhs_data/recode/water_recode.csv")
toilet = read_csv("dhs_data/recode/toilet_recode.csv")

# prepare DHS data and create index
dhs_hr %<>%
  # rename for ease of referencing cols
  rename(household_members = hv013, rooms = hv216, phone = hv221,
         cellphone = hv243a, radio = hv207, fridge = hv209, tv = hv208,
         car = hv212, motorcycle = hv211, electric = hv206,
         floor_code = hv213, water_code = hv201, toilet_code = hv205)

# figure out what countries don't have important cols and need to drop
drop_countries = dhs_hr %>%
  group_by(cname, year) %>%
  # figure out if an entire column is missing for that country-year
  summarise(across(electric:cellphone, function(x){sum(is.na(x))/n()})) %>%
  mutate(drop = electric==1 | radio==1 | tv==1 | fridge==1 | motorcycle==1 |
                car==1 | rooms==1 | cellphone==1,
         country_year = paste(cname, year)) %>%
  filter(drop)

dhs_hr %<>%

  # drop countries that are entirely missing necessary cols
  filter(!paste(cname, year) %in% drop_countries$country_year) %>%

  # deal with NAs
  mutate(across(electric:motorcycle, as.numeric),
         fridge = ifelse(fridge==9, NA, fridge),
         phone = ifelse(phone==9, NA, phone),
         tv = ifelse(tv==9, NA, tv),
         car = ifelse(car==9, NA, car),
         cellphone = ifelse(cellphone==9, NA, cellphone),
         radio = ifelse(radio==9, NA, radio),
         motorcycle = ifelse(motorcycle==9, NA, motorcycle)) %>%

  # fix phone and create roomspp
  mutate(phone = ifelse((phone==0 | is.na(phone)) & !is.na(cellphone),
                        cellphone, phone),
         rooms = ifelse(rooms>25, 25, rooms)) %>% # to match yeh et al.

  # merge all the recodes in
  merge(floor, by = "floor_code", all.x = TRUE) %>%
  merge(water, by = "water_code", all.x = TRUE) %>%
  merge(toilet, by = "toilet_code", all.x = TRUE) %>%

  # select relevant cols
  select(DHSID_EA, DHSID_HH, cname, year, lat, lon,
         rooms, electric, fridge,
         phone, tv, car, cellphone, radio, motorcycle,
         floor_qual, toilet_qual, water_qual) %>%

  # drop obs that are missing necessary info
  drop_na(lat, lon)

# run checks again
nrow(dhs_hr) # 2,167,073
nrow(unique(dhs_hr[, c("cname", "year")])) # 126

# create asset index
asset_cols = c("rooms", "electric", "phone", "radio", "tv", "car", "fridge",
               "motorcycle", "floor_qual", "toilet_qual", "water_qual")
mask = !apply(is.na(dhs_hr[, asset_cols]), 1, any)
dhs_hr[mask, "asset_index"] = prcomp(dhs_hr[mask, asset_cols])$x[, 1]

dhs_hr %<>%
  rename(water_index = water_qual, 
         sanitation_index = toilet_qual) %>%
  
  # calculate averages for index
  group_by(DHSID_EA, cname, year, lat, lon) %>%
  summarise(n_asset = sum(!is.na(asset_index)), 
            asset_index = mean(asset_index, na.rm = TRUE),
            n_water = sum(!is.na(water_index)), 
            water_index = mean(water_index, na.rm = TRUE),
            n_sanitation = sum(!is.na(sanitation_index)), 
            sanitation_index = mean(sanitation_index, na.rm = TRUE)) %>%
  
  # set index to NA if <5 obs, remove NA rows
  mutate(asset_index = ifelse(n_asset < 5, NA, asset_index),  
         n_asset = ifelse(n_asset < 5, NA, n_asset), 
         
         water_index = ifelse(n_water < 5, NA, water_index),  
         n_water = ifelse(n_water < 5, NA, n_water),
         
         sanitation_index = ifelse(n_sanitation < 5, NA, sanitation_index),  
         n_sanitation = ifelse(n_sanitation < 5, NA, n_sanitation)) %>%
  
  # drop rows where all 3 are NA
  filter(!is.na(asset_index) | !is.na(water_index) | !is.na(sanitation_index))
  

# last check, how many EA's do we end up with?
sum(!is.na(dhs_hr$asset_index)) # 87,119 about 4x Yeh et al. (2020)

write_csv(dhs_hr, 
          file.path("output_labels", "dhs_asset_infrastructure_indices.csv"))


###############################################################
# Clean IR files and get relevant columns
###############################################################

dhs_ir = combine_dhs_files(country_years, type = "IR",
                           variables = c("cname", "caseid", "year",
                                         "v000", "v001", "v002", "v133", 
                                         "v213", "v445",
                                         paste0("b2_", str_pad(1:20, 2, "left", "0")),
                                         paste0("b5_", str_pad(1:20, 2, "left", "0")),
                                         paste0("b7_", str_pad(1:20, 2, "left", "0")),
                                         paste0("b8_", str_pad(1:20, 2, "left", "0"))),
                           data_dir = data_dir, append = "fullIRdata")
cmort = dhs_ir %>%
  pivot_longer(cols = b2_01:b8_20,
               names_to = c(".value", "child"),
               names_sep = "_") %>%
  rename(birth_year = b2, alive = b5, age_death = b7, age_living = b8) %>%
  mutate(age_death = floor(age_death/12), 
         age_living = floor(age_living)) %>%
  filter(age_death <= 5 | age_living <= 5, # only keeping kids less than <=5
         alive | # drop <=5 who died prior to that year
           birth_year + age_death >= (year-1)) %>% 
  group_by(DHSID_EA, cname, year, lat, lon) %>%
  summarise(under5_mort = (sum(alive==0)/n())*1000, 
            n_under5_mort = n()) %>%
  drop_na(lat, lon, under5_mort) %>%
  filter(n_under5_mort >= 5)
write_csv(cmort, "output_labels/dhs_child_mortality.csv")

women_edu = dhs_ir %>%
  mutate(v133 = ifelse(v133 %in% 97:99, NA, v133),
         v133 = ifelse(v133 > 18, 18, v133),
         v445 = ifelse(v445 %in% 9997:9999, NA, v445), 
         v445 = ifelse(v213 == 1, NA, v445)) %>% # remove bmi for pregnant women
  group_by(DHSID_EA, cname, year, lat, lon) %>%
  summarise(women_edu = mean(v133, na.rm = TRUE),
            women_bmi = mean(v445/100, na.rm = TRUE),
            n_women_edu = sum(!is.na(v133)), 
            n_women_bmi = sum(!is.na(v445))) %>%
  drop_na(lat, lon) %>%
  mutate(women_edu = ifelse(n_women_edu < 5, NA, women_edu),  # filter out rows with < 5 obs
         n_women_edu = ifelse(n_women_edu < 5, NA, n_women_edu), 
         women_bmi = ifelse(n_women_bmi < 5, NA, women_bmi), 
         n_women_bmi = ifelse(n_women_bmi < 5, NA, n_women_bmi)) %>%
  filter(!is.na(women_edu) | !is.na(women_bmi))
write_csv(women_edu, "output_labels/dhs_women_education_bmi.csv")


###############################################################
# Merge label CSVs together
###############################################################

asi = read_csv("output_labels/dhs_asset_infrastructure_indices.csv",
               col_types = list(.default = col_character()))
chm = read_csv("output_labels/dhs_child_mortality.csv",
               col_types = list(.default = col_character()))
meb = read_csv("output_labels/dhs_women_education_bmi.csv",
               col_types = list(.default = col_character()))
loc = read_csv("output_labels/dhs_locations.csv",
               col_types = list(.default = col_character()))
merged = asi %>%
  full_join(chm) %>%
  full_join(meb) %>%
  left_join(loc)

# assert that (DHSID_EA, year, lat, lon) are unique
if (sum(duplicated(merged$DHSID_EA)) != 0) {
  stop("Error: mismatched (DHSID_EA, year, lat, lon) in join")
}

write_csv(merged, "output_labels/dhs_merged.csv")
