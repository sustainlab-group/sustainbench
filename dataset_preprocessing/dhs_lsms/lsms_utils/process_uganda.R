#' Extracts the necessary data files for LSMS Uganda surveys.
#'
#' Depends on extract_and_rename() function in lsms_utils.R.
#' Assumes that the following ZIP files have already been downloaded
#' into {data_dir}/raw/Uganda:
#' - "UGA_2005_2009_UNPS_v01_M_Stata8.zip"
#' - "UGA_2013_UNPS_v01_M_CSV.zip"
#'
#' @param data_dir Path to data folder, with "raw" and "clean" subfolders.
#'   Should not end in a "/".
#' @return Nothing.
#' @export
extract_uganda = function(data_dir) {
  raw_ug = file.path(data_dir, "raw", "Uganda")
  # raw/Uganda/UNHS_05.06/GSEC1.dta, GSEC11.dta, GSEC12A.dta
  zip_path = file.path(raw_ug, "UGA_2005_2009_UNPS_v01_M_Stata8.zip")
  extract_dir = file.path(raw_ug, "UNHS_05.06")
  extract_files = c(
      "2005_GSEC1.dta",    # "Socio-Economic Questionnaire", Section 1: Identification particulars
      "2005_GSEC11.dta",   # "Socio-Economic Questionnaire", Section 11: Housing conditions
      "2005_GSEC12A.dta")  # "Socio-Economic Questionnaire", Section 12A: Household and enterprise assets
  rename = c(
      "GSEC1.dta",
      "GSEC11.dta",
      "GSEC12A.dta")
  extract_and_rename(zip_path, extract_files, extract_dir, rename)

  # raw/Uganda/UNPS_09.10/GSEC9.dta, GSEC10A.dta, GSEC14.dta, UNPS_Geovars_0910.dta
  zip_path = file.path(raw_ug, "UGA_2005_2009_UNPS_v01_M_Stata8.zip")
  extract_dir = file.path(raw_ug, "UNPS_09.10")
  extract_files = c(
      "2009_GSEC1.dta",    # "Household Questionnaire", Section 1B: Staff details and survey time
      "2009_GSEC9.dta",    # "Household Questionnaire", Section 9: Housing conditions, water and sanitation
      "2009_GSEC10A.dta",  # "Household Questionnaire", Section 10A: Energy use
      "2009_GSEC14.dta",   # "Household Questionnaire", Section 14: Household assets
      "2009_UNPS_Geovars_0910.dta")
  rename = c(
      "GSEC1.dta",
      "GSEC9.dta",
      "GSEC10A.dta",
      "GSEC14.dta",
      "UNPS_Geovars_0910.dta")
  extract_and_rename(zip_path, extract_files, extract_dir, rename)

  # raw/Uganda/UNPS_13.14/GSEC1.csv, GSEC9_1.csv, GSEC10_1.csv, GSEC14A.csv
  zip_path = file.path(raw_ug, "UGA_2013_UNPS_v01_M_CSV.zip")
  extract_dir = file.path(raw_ug, "UNPS_13.14")
  extract_files = c(
      "gsec1.csv",     # - HH Questionnaire Section 1A: Household Identification Particulars
      "gsec9_1.csv",   # - HH Questionnaire Section 9: Housing Conditions, Water and Sanitation
      "gsec10_1.csv",  # - HH Questionnaire Section 10: Energy Use
      "gsec14a.csv")   # - HH Questionnaire Section 14A: Household Assets
  rename = c(
      "GSEC1.csv",
      "GSEC9_1.csv",
      "GSEC10_1.csv",
      "GSEC14A.csv")
  extract_and_rename(zip_path, extract_files, extract_dir, rename)
  return()
}


#' Converts ug13 HHID to ug05 HHID
#'
#' @param ug13_data Dataframe from UNPS_13.14 survey, has "HHID" column
#' @param raw_ug13 Path to raw/Uganda/UNPS_13.14 data folder, containing
#'   "GSEC1.csv" file. Should not end in a "/".
#' @return Dataframe with HHID changed to match UNHS_05.06 / UNPS_09.10
#'   surveys
convert_to_ug05_hhid = function(ug13_data, raw_ug13) {
  ug13_hh_info = read_csv(file.path(raw_ug13, "GSEC1.csv"),
      col_types = list(.default = col_character())) %>%
    select(HHID, HHID_old)
  data = ug13_data %>%
    inner_join(ug13_hh_info, by = "HHID") %>%
    select(-HHID) %>%
    rename(HHID = HHID_old) %>%
    mutate(HHID = as.character(HHID)) %>%
    select(HHID, everything())
  return(data)
}


#' Main function for processing Uganda LSMS data
#'
#' @param data_dir Path to data folder, with "raw" and "clean" subfolders.
#'   Should not end in a "/".
process_uganda = function(data_dir) {

  # raw data folders
  raw_ug05 = file.path(data_dir, "raw", "Uganda", "UNHS_05.06")
  raw_ug09 = file.path(data_dir, "raw", "Uganda", "UNPS_09.10")
  raw_ug13 = file.path(data_dir, "raw", "Uganda", "UNPS_13.14")

  # ---------------------------------------------------------------------------
  # Read household info
  # - some info is used for the enumeration ID (cluster ID) later
  # - get a list of households IDs that are in all of the surveys
  # ---------------------------------------------------------------------------
  ug05_hh_info = haven::read_dta(file.path(raw_ug05, "GSEC1.dta")) %>%
    select(Hhid, Districtc05) %>%
    mutate(across(everything(), as.character))
  ug09_hh_info = haven::read_dta(file.path(raw_ug09, "GSEC1.dta")) %>%
    select(HHID, h1aq1, h1aq1_05, comm) %>%
    mutate(across(everything(), as.character))
  ug13_hh_info = read_csv(
      file.path(raw_ug13, "GSEC1.csv"),
      col_types = list(.default = col_character())) %>%
    select(HHID, HHID_old, h1aq1a)

  # get households that are in all of the surveys
  households = ug05_hh_info %>%  # 3123 rows
    rename(HHID = Hhid) %>%
    inner_join(ug09_hh_info, by = "HHID") %>%  # becomes 2607 rows
    inner_join(ug13_hh_info, by = c("HHID" = "HHID_old")) %>%  # becomes 1543 rows
    select(HHID, h1aq1, h1aq1a, h1aq1_05, Districtc05) %>%
    filter(Districtc05 == h1aq1_05,  # 2005 district == 2009 district
           h1aq1 == h1aq1a)          # 2009 district == 2013 district
    # becomes 1215 rows

  # ---------------------------------------------------------------------------
  # Get enumeration ID (cluster ID) with lat/lon
  # ---------------------------------------------------------------------------
  geo = haven::read_dta(file.path(raw_ug09, "UNPS_Geovars_0910.dta")) %>%
    select(HHID, COMM, lat_mod, lon_mod) %>%
    mutate(COMM = as.character(COMM)) %>%

    # there are some households where COMM=0 (i.e., unknown) but the corresponding
    # "comm" column in ug09_hh_info is valid
    left_join(ug09_hh_info[, c("HHID", "comm")], by = "HHID") %>%
    mutate(COMM = ifelse(COMM == "0", comm, COMM)) %>%
    filter(nchar(COMM) > 0) %>%

    # finalize
    rename(household_id = HHID, ea_id = COMM, lat = lat_mod, lon = lon_mod) %>%
    select(household_id, ea_id, lat, lon) %>%
    drop_na(household_id, ea_id, lat, lon)

  # ---------------------------------------------------------------------------
  # Load housing data
  # - filters out household_id's that aren't present in all surveys
  # ---------------------------------------------------------------------------
  ug05_housing = haven::read_dta(file.path(raw_ug05, "GSEC11.dta")) %>%
    select(Hhid, H11q3a1, H11q6a, H11q10a, H11q7a, H11q11a) %>%
    rename(household_id = Hhid, rooms = H11q3a1, floor = H11q6a,
           toilet = H11q10a, watsup = H11q7a, electric = H11q11a) %>%
    mutate(electric = ifelse(electric == 1, 1, 0)) %>%
    filter(household_id %in% households$HHID)

  ug09_electric = haven::read_dta(file.path(raw_ug09, "GSEC10A.dta")) %>%
    select(HHID, h10q1) %>%
    rename(household_id = HHID, electric = h10q1) %>%
    mutate(electric = ifelse(electric == 2,0,1))
  ug09_housing = haven::read_dta(file.path(raw_ug09, "GSEC9.dta")) %>%
    select(Hhid, H9q03, H9q06, H9q22, H9q07) %>%
    rename(household_id = Hhid, rooms = H9q03, floor = H9q06, toilet = H9q22,
           watsup = H9q07) %>%
    merge_verbose(ug09_electric, by = "household_id", all.x = T) %>%
    filter(household_id %in% households$HHID)

  ug13_electric = read_csv(file.path(raw_ug13, "GSEC10_1.csv"),
      col_types = list(
          HHID = col_character(),
          .default = col_double())) %>%
    convert_to_ug05_hhid(raw_ug13) %>%
    select(HHID, h10q1) %>%
    rename(household_id = HHID, electric = h10q1) %>%
    mutate(electric = ifelse(electric == 2, 0, 1))
  ug13_housing = read_csv(file.path(raw_ug13, "GSEC9_1.csv"),
      col_types = list(
          HHID = col_character(),
          h9q3 = col_double(),
          h9q6 = col_double(),
          h9q22 = col_double(),
          h9q7 = col_double())) %>%
    convert_to_ug05_hhid(raw_ug13) %>%
    select(HHID, h9q3, h9q6, h9q22, h9q7) %>%
    rename(household_id = HHID, rooms = h9q3, floor = h9q6, toilet = h9q22,
           watsup = h9q7) %>%
    merge_verbose(ug13_electric, by = "household_id", all.x = T) %>%
    filter(household_id %in% households$HHID)

  # ---------------------------------------------------------------------------
  # Apply recoding for floor, toilet, and watsup (water)
  # - filters out household_id's that aren't present in all surveys
  # ---------------------------------------------------------------------------
  recode_dir = file.path(data_dir, "raw", "Uganda", "recode")

  floor0509 = read_csv(file.path(recode_dir, "floor_recode.csv"))
  toilet0509 = read_csv(file.path(recode_dir, "toilet_recode.csv"))
  watsup0509 = read_csv(file.path(recode_dir, "watsup_recode.csv"))

  floor13 = read_csv(file.path(recode_dir, "floor_recode_w5.csv"))
  toilet13 = read_csv(file.path(recode_dir, "toilet_recode_w5.csv"))
  watsup13 = read_csv(file.path(recode_dir, "watsup_recode_w5.csv"))

  ug05_housing = ug05_housing %>%
    merge_verbose(floor0509, by = "floor", all.x = TRUE) %>%
    merge_verbose(toilet0509, by = "toilet", all.x = TRUE) %>%
    merge_verbose(watsup0509, by = "watsup", all.x = TRUE)

  ug09_housing = ug09_housing %>%
    merge_verbose(floor0509, by = "floor", all.x = TRUE) %>%
    merge_verbose(toilet0509, by = "toilet", all.x = TRUE) %>%
    merge_verbose(watsup0509, by = "watsup", all.x = TRUE)

  ug13_housing = ug13_housing %>%
    merge_verbose(floor13, by = "floor", all.x = TRUE) %>%
    merge_verbose(toilet13, by = "toilet", all.x = TRUE) %>%
    merge_verbose(watsup13, by = "watsup", all.x = TRUE)

  # -----------------------------------------------------------------------------
  # Asset ownership data
  # - The asset ownership question values are: 1 = YES, 2 = NO
  # - In UG2005, asset code `7` is "Electronic equipment", which isn't explicitly
  #   radio or TV, but we use it as a proxy for both radio and TV
  # -----------------------------------------------------------------------------
  ug05_assets = haven::read_dta(file.path(raw_ug05, "GSEC12A.dta")) %>%
    select(Hhid, H12aq2, H12aq3) %>%
    rename(HHID = Hhid) %>%
    # remove Stata labelling
    mutate(H12aq2 = as.double(H12aq2), H12aq3 = as.double(H12aq3)) %>%
    filter(H12aq2 %in% c(12, 7, 14)) %>%
    reshape2::dcast(HHID ~ H12aq2) %>%
    mutate_at(vars(-("HHID")),
              function(x) {ifelse(x == 2, 0, 1)}) %>%
    rename(household_id = HHID, radio = `7`, auto = `12`, phone = `14`) %>%
    mutate(tv = radio)  # From Yeh et al., 2020

  ug09_assets = haven::read_dta(file.path(raw_ug09, "GSEC14.dta")) %>%
    select(HHID, h14q2, h14q3) %>%
    # remove Stata labelling
    mutate(h14q2 = as.double(h14q2), h14q3 = as.double(h14q3)) %>%
    filter(h14q2 %in% c(6, 7, 12, 16)) %>%
    reshape2::dcast(HHID ~ h14q2) %>%
    mutate_at(vars(-("HHID")),
              function(x) {ifelse(x == 2, 0, 1)}) %>%
    rename(household_id = HHID, tv = `6`, radio = `7`, auto = `12`, phone = `16`)

  ug13_assets = read_csv(file.path(raw_ug13, "GSEC14A.csv"),
      col_types = list(
          HHID = col_character(),
          h14q2 = col_double(),
          h14q3 = col_double())) %>%
    convert_to_ug05_hhid(raw_ug13) %>%
    select(HHID, h14q2, h14q3) %>%
    filter(h14q2 %in% c(6, 7, 12, 16),
           !is.na(HHID)) %>%
    reshape2::dcast(HHID ~ h14q2) %>%
    mutate_at(vars(-("HHID")),
              function(x) {ifelse(x == 2, 0, 1)}) %>%
    rename(household_id = HHID, tv = `6`, radio = `7`, auto = `12`, phone = `16`)

  # -----------------------------------------------------------------------------
  # combine asset ownership, housing, and geography data
  # -----------------------------------------------------------------------------
  ug05_all = ug05_housing %>%
    merge_verbose(geo, by = 'household_id', all.x = TRUE) %>%
    merge_verbose(ug05_assets, by = 'household_id', all.x = TRUE)

  ug09_all = ug09_housing %>%
    merge_verbose(geo, by = 'household_id', all.x = TRUE) %>%
    merge_verbose(ug09_assets, by = 'household_id', all.x = TRUE)

  ug13_all = ug13_housing %>%
    merge_verbose(geo, by = 'household_id', all.x = TRUE) %>%
    merge_verbose(ug13_assets, by = 'household_id', all.x = TRUE)

  # -----------------------------------------------------------------------------
  # Combine the 3 survey rounds
  # - only keep households with data from all rounds
  # -----------------------------------------------------------------------------
  households = intersect(
      intersect(ug05_housing$household_id, ug09_housing$household_id),
      ug13_housing$household_id)

  ug05_all = ug05_all %>%
    mutate(year = 2005, country = "ug") %>%
    select(year, country, household_id, ea_id, lat, lon,
           rooms, electric, phone, radio, tv, auto,
           floor_qual, toilet_qual, watsup_qual) %>%
    filter(household_id %in% households)

  ug09_all = ug09_all %>%
    mutate(year = 2009, country = "ug") %>%
    select(year, country, household_id, ea_id, lat, lon,
           rooms, electric, phone, radio, tv, auto,
           floor_qual, toilet_qual, watsup_qual) %>%
    filter(household_id %in% households)

  ug13_all = ug13_all %>%
    mutate(year = 2013, country = "ug") %>%
    select(year, country, household_id, ea_id, lat, lon,
           rooms, electric, phone, radio, tv, auto,
           floor_qual, toilet_qual, watsup_qual) %>%
    filter(household_id %in% households)

  uganda = rbind(ug05_all, ug09_all, ug13_all)

  clean_dir = file.path(data_dir, "clean")
  if (!dir.exists(clean_dir)) {
    dir.create(clean_dir)
  }
  rds_path = file.path(clean_dir, "uganda.RDS")
  print(paste0("Writing uganda.RDS to ", rds_path))
  write_rds(uganda, rds_path)

  return(uganda)
}