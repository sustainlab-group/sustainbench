#' Saves a DHS file and appropriately logs it
#'
#'
#' @param dhs The dataframe to save.
#' @param data_dir Path to data folder, with "raw" and "clean" subfolders.
#'   Should not end in a '/'.
#' @param raw_file Name of the original raw file.
#' @param clean_file_name The name the new file should be saved under.
#' @return Nothing. Saves the data to the clean folder, and logs its creation.
clean_file_log_saving = function(dhs, data_dir, raw_file, clean_file_name) {

  # read in the log
  clean_log_path = file.path(data_dir, "clean", "log.csv")
  log = read_csv(clean_log_path, col_types = list(
    clean_file = col_character(),
    orig_file = col_character(),
    year = col_integer(),
    date = col_character()
  ))

  # check if there are old files to overwrite
  files_to_remove = log[log$orig_file == raw_file, "clean_file"]
  if (length(files_to_remove) > 0) {
    file.remove(file.path(data_dir, "clean", files_to_remove))
  }

  # save in the log
  tibble(
    clean_file = clean_file_name,
    orig_file = raw_file,
    year = dhs$year[1],
    date = as.character(Sys.Date())
  ) %>%
  bind_rows(log[log$orig_file != raw_file, ]) %>%
  write_csv(clean_log_path)

  # save data as RDS
  write_rds(dhs, file.path(data_dir, "clean", clean_file_name))
}


#' Cleans a DHS file
#'
#' Raw DHS file must be located at <data_dir>/"raw"/<raw_file>. Currently
#' only handles HR, IR, and GE. KR, BR etc are not dealt with explicitly,
#' probably best to not use for that. Saves a cleaned version of the data to
#' <data_dir>/"clean"/<raw_file_name>_<cur_date>[_<suffix>].RDS
#'
#' @param raw_file Name of raw DHS file
#' @param data_dir Path to data folder, with "raw" and "clean" subfolders.
#'   Should not end in a "/".
#' @param suffix String to append to end of raw name in order to identify the
#'   cleaned version.
#' @param override Default FALSE, will ask if you want to write over files,
#'   TRUE will automatically write over files, NULL will just ignore and let
#'   you know it's not writing
#' @return Nothing. Saves the data to the clean folder, and logs its creation.
#' @import dplyr
#' @import readstata13
#' @import stringr
#' @export
clean_dhs_file = function(raw_file,
                          data_dir = ".",
                          suffix = NULL,
                          override = FALSE) {
  recode_abbrv = substr(raw_file, 3, 4)
  if (!(recode_abbrv %in% c("HR", "IR", "GE"))) {
    stop("File is not GE, HR or IR file. This file type isn't supported.")
  }

  # get info to check log
  path_to_raw = file.path(data_dir, "raw", raw_file)
  file_name = strsplit(raw_file, "\\.")[[1]][1]
  cur_date = as.character(Sys.Date())
  clean_file_name = str_c(file_name, "_", cur_date, ".RDS")
  if (length(suffix) > 0) {
    clean_file_name = str_c(file_name, "_", cur_date, "_", suffix, ".RDS")
  }

  # Check if this file name already exists
  # - doesn't check to see if the configuration already exists
  # - will overwrite the current file if it does
  log = read_csv(file.path(data_dir, "clean", "log.csv"), col_types = list(
    clean_file = col_character(),
    orig_file = col_character(),
    year = col_integer(),
    date = col_character()
  ))
  exists = log[log$orig_file == raw_file, ]
  if (nrow(exists) > 0) {
    if (is.null(override)) {
      print(str_glue("Already run for this raw_file. 'override'=NULL so ",
                     "will not run for file: {raw_file}"))
      return()
    } else if (override) {
      print("Already run for this raw_file. 'override'=T so will run anyway.")
    } else {
      prompt = str_glue("Already run for {raw_file}. Enter 'y' to run anyway: ")
      if (readline(prompt) != 'y') {
        orig_file = exists$clean_file[1]
        print(str_glue("Stopping. See '{orig_file}' for the original file."))
        return()
      }
    }
  }

  log_raw = read_csv(file.path(data_dir, "raw", "log.csv"), col_types = list(
    filename = col_character(),
    download_date = col_character(),
    year = col_integer()
  ))
  dhs_year = log_raw[log_raw$filename == raw_file, ]$year
  dhs_round = substr(raw_file, 5, 6)
  dhs_round = ifelse(grepl('[A-Za-z]', dhs_round),
                     paste0(substr(dhs_round, 1, 1), "Z"),
                     paste0(substr(dhs_round, 1, 1), "#"))

  # if it's a geo file: process, save and return
  if (recode_abbrv == "GE") {

    # read in the file
    dhs = foreign::read.dbf(path_to_raw) %>% as.data.frame()

    # do some normalizing and name changing
    dhs[(dhs$LATNUM == 0) & (dhs$LONGNUM == 0), c("LATNUM", "LONGNUM")] = NA
    dhs = dhs %>%
      mutate(DHSID_EA = str_c(
        DHSCC,
        dhs_year,
        dhs_round,
        str_pad(DHSCLUST, width = 8, pad = "0", side = "left"),
        sep = "-")
      ) %>%
      select(DHSID_EA, DHSCLUST, ADM1FIPS, ADM1DHS, URBAN_RURA, LATNUM, LONGNUM) %>%
      set_names("DHSID_EA", "cluster_id", "adm1fips", "adm1dhs", "urban", "lat", "lon") %>%
      mutate(year = dhs_year)

    clean_file_log_saving(dhs, data_dir, raw_file, clean_file_name)

    return()
  }

  # read in the data
  dhs = tryCatch({
    dhs <- haven::read_dta(path_to_raw)
    dhs <- sjlabelled::remove_all_labels(dhs)
  }, error = function(e) {
    dhs <- read.dta13(path_to_raw, generate.factors = TRUE)
  })
  dhs = as.data.frame(dhs)

  # do some edits that we know on a country by country level
  # dhs = manual_country_edits(dhs, raw_file)

  # set up variables to work with for household or individual
  if (recode_abbrv == "IR") {
    type = "individual"
    year = "v007"
    date = "v008"
    id = "v000"
  } else if (recode_abbrv == "HR") {
    type = "household"
    year = "hv007"
    date = "hv008"
    id = "hv000"
  }

  # seperate country name
  dhs$cname = substr(dhs[,id], 1, 2)

  # set year to the year listed on the DHS site
  dhs$year = dhs_year
  dhs = dhs[, names(dhs) != year] # drop original year var
  dhs$svyid = paste0(dhs$cname, dhs$year[1])

  # create unique id's
  if (type == "individual") {
    dhs$DHSID_EA = paste(dhs$cname, dhs$year, dhs_round,
                         stringr::str_pad(dhs$v001, width = 8, pad = "0", side = "left"),
                         sep = "-")
    dhs$DHSID_HH = paste(dhs$DHSID_EA,
                         stringr::str_pad(dhs$v002, width = 4, pad = "0", side = "left"),
                         sep = "-")
    dhs$DHSID_HH_unique = dhs$DHSID_HH
    dhs$DHSID_mom = paste(dhs$DHSID_HH,
                          stringr::str_pad(dhs$v003, width = 3, pad = "0", side = "left"),
                          sep = "-")

    if (length(dhs$DHSID_mom) != length(unique(dhs$DHSID_mom))) {
      #if the id's aren't unique, add n to the end to enforce uniqueness
      dhs = dhs %>% group_by(DHSID_mom) %>% mutate(n = row_number())
      dhs$DHSID_mom = paste0(dhs$DHSID_mom, "_", dhs$n)
      dhs %<>% select(-n)
    }

    dhs = dhs %>% select(cname, year, svyid, DHSID_EA, DHSID_HH,
                         DHSID_HH_unique, DHSID_mom, everything())

  } else if (type == "household") {

    dhs$DHSID_EA = paste(dhs$cname, dhs$year, dhs_round,
                         stringr::str_pad(dhs$hv001, width = 8, pad = "0", side = "left"),
                         sep = "-")
    dhs$DHSID_HH = paste(dhs$DHSID_EA,
                         stringr::str_pad(dhs$hv002, width = 4, pad = "0", side = "left"),
                         sep = "-")
    dhs$DHSID_HH_unique = dhs$DHSID_HH
    dhs %<>%
      select(cname, year, svyid, DHSID_EA, DHSID_HH,
             DHSID_HH_unique, everything())
  }

  # if DHSID isn't unique, add n to the end to enforce uniqueness
  if (length(dhs$DHSID_HH) != length(unique(dhs$DHSID_HH))) {
    dhs = dhs %>%
        group_by(DHSID_HH) %>%
        mutate(n = row_number()) %>%
        mutate(DHSID_HH_unique = paste0(DHSID_HH, "_", n)) %>%
        select(-n)
  }

  clean_file_log_saving(dhs, data_dir, raw_file, clean_file_name)
}


#' Gets the country/year combos to combine
#'
#' Creates a dataframe that contains all the CountryName/SurveyYear pairs that
#' are currently in your cleaned folder, after filtering by specified regions and
#' years
#'
#' @param regions The regions you're interested in including in your final
#    dataset. Default is set to all regions.
#' @param crosswalk_countries dataframe with columns
#'   (iso2, iso3, country, country_simp, region, sub_region, dhscode)
#' @param min_year The earliest year to include.
#' @param max_year The latest year to include.
#' @param data_dir Path to data folder, with "raw" and "clean" subfolders.
#'   Should not end in a '/'.
#' @return A dataframe that contains all the CountryName/SurveyYear pairs that
#'   are currently in your cleaned folder, after filtering by specified regions.
#' @export
build_combine_df = function(regions = c("Australia and New Zealand", "Polynesia",
                                        "Central Asia", "Eastern Asia",
                                        "Western Asia", "Southern Asia",
                                        "South-eastern Asia", "Melanesia",
                                        "Micronesia", "Eastern Europe",
                                        "Northern Europe", "Southern Europe",
                                        "Western Europe",
                                        "Latin America and the Caribbean",
                                        "Northern America", "Northern Africa",
                                        "Sub-Saharan Africa"),
                            crosswalk_countries,
                            min_year = "1980", max_year = substr(Sys.Date(), 1, 4),
                            data_dir = "~/BurkeLab Dropbox/dhs/") {

  isos = crosswalk_countries[crosswalk_countries$sub_region %in% regions, "iso2"]
  dhs_isos = crosswalk_countries[crosswalk_countries$sub_region %in% regions, "dhscode"]
  isos = ifelse(is.na(dhs_isos), as.character(isos), as.character(dhs_isos))

  log = read_csv(file.path(data_dir, "clean", "log.csv"), col_types = list(
    clean_file = col_character(),
    orig_file = col_character(),
    year = col_integer(),
    date = col_character()
  ))

  downloads = data.frame(country = character(), year = integer())
  for (iso in isos) {
    temp_log = log %>%
      filter(substr(orig_file, 1, 2) == iso,
             year >= min_year, year <= max_year) %>%
      mutate(country = iso) %>%
      select(country, year) %>%
      unique()
    downloads = rbind(downloads, temp_log)
  }

  downloads = downloads[complete.cases(downloads), ]

  return(downloads)
}


#' Saves a DHS file and appropriately logs it
#'
#'
#' @param dhs The file to save.
#' @param data_dir Path to data folder, with "raw" and "clean" subfolders.
#'   Should not end in a '/'.
#' @param new_file_name The name the new file should be saved under.
#' @param files The list of "clean" files used to put together data.
#' @param variables The list of variables that was queried for.
#' @param country_years_used The list of country-years ultimately included.
#' @return Nothing. Saves the data to the clean folder, and logs its creation.
output_file_log_saving = function(dhs, data_dir, new_file_name, files,
                                  variables, country_years_used) {

  # read in the log
  # columns: (final_file, orig_file, variables, country_years, date)
  log = read_csv(file.path(data_dir, "output", "log.csv"),
                 col_types = list(.default = col_character()))

  # prep log
  log = rbind(c(new_file_name, # new file name
                paste(sort(files), collapse = "_"), # list of clean files used
                paste(sort(variables), collapse = "_"), # list of variables used
                paste(sort(country_years_used), collapse = "_"), # countries used
                as.character(Sys.Date())), # date
              log)
  names(log) = c("final_file", "orig_file", "variables", "country_years", "date")

  # save out data
  write_rds(dhs, file = file.path(data_dir, "output", new_file_name))

  # save out log
  write_csv(log, file.path(data_dir, "output", "log.csv"))
}


#' Collects specified files, retrieves, combines and filters them.
#'
#' @param country_years A dataframe with columns ('country', 'year').
#'   'country' = DHS adapted iso2 country code. 'year' = year of interest.
#' @param type 'HR' or 'IR', which file type to read in.
#' @param variables A vector containing the column names you want to keep from the data.
#' @param data_dir Path to data folder, with "raw" and "clean" subfolders.
#'   Should not end in a '/'.
#' @param override If you should just give a warning and return rather than throwing an error and stopping for everything.
#' @return The combined data from all country-years specified, with only specified columns selected.
#' @import plyr
#' @export
combine_dhs_files = function(country_years,
                             type = "HR",
                             variables = c("hhid", "cname", "year", "hv000",
                                           "hv001", "hv005", "hv201", "hv205",
                                           "hv206", "hv207", "hv208", "hv209",
                                           "hv211", "hv212", "hv213", "hv216",
                                           "hv221", "hv243a", "hv013"),
                             data_dir = "~/BurkeLab Dropbox/dhs/",
                             override = FALSE, append = "") {

  # setup
  meta = c("DHSID_EA", "DHSID_HH")
  variables = unique(c(meta, variables))
  log = read_csv(file.path(data_dir, "clean", "log.csv"), col_types = list(
    clean_file = col_character(),
    orig_file = col_character(),
    year = col_integer(),
    date = col_character()
  ))
  bound = data.frame(matrix(ncol = length(variables), nrow = 0), stringsAsFactors = FALSE)
  colnames(bound) = variables
  files = c()
  geos = c()
  new_file_name = paste0("DHS_output", "_", as.character(Sys.Date()), ".RDS")
  country_years_used = c()

  # figure out what files we need to read in
  for (i in 1:nrow(country_years)) {

    # for each country year find the relevant "clean" files
    cur = country_years[i, ]
    file_name = log[log$year == cur$year &
                    grepl(paste0(cur$country, type), log$clean_file), "clean_file"]
    geo = log[log$year == cur$year &
              grepl(paste0(cur$country, "GE"), log$clean_file), "clean_file"]

    # throw warning if no files are found for that country-year
    if (length(file_name) == 0) {
      file_name = NA
      geo = NA
      warning(sprintf("No file found for %s, %s, %s. Continuing with other specifications.", cur$country, cur$year, type))
      next
    } else {file_name = sort(file_name)[1]}

    # if there's no geography for that year check if adjacent years have geo
    if (length(geo) == 0) {

      geo = log[abs(log$year - as.numeric(cur$year)) <= 2 &
                grepl(paste0(cur$country, "GE"), log$clean_file), ]
      geo = geo[order(abs(geo$year-as.numeric(cur$year)), geo$year), ][1,]

      if (length(geo) == 0) {
        geo = NA
        warning(sprintf("No geodata file found for %s, %s. Will still include, but without geodata.",
                        cur$country, cur$year))
      } else {
        warning(sprintf("No geodata file found for %s, %s. Using geo for %s, %s.",
                        cur$country, cur$year, cur$country, geo$year))
        geo = geo[, "clean_file"]
      }
    } else {geo = sort(geo)[1]} #take most recent if more than one

    geos = c(geos, geo)
    files = c(files, file_name)
    country_years_used = c(country_years_used, paste0(cur$country, cur$year))
  }

  # break if no files are found for any country-year.
  if (length(files) == 0) {
    stop("None of country/year/type pairs found in log. Check to ensure they exist in the 'clean' folder and log.")
  }

  # take the files for country-years that were found
  geos = geos[!is.na(files)]
  files = files[!is.na(files)]

  # check to make sure we haven't made this combination already
  # columns: (final_file, orig_file, variables, country_years, date)
  log = read_csv(file.path(data_dir, "output", "log.csv"),
                 col_types = list(.default = col_character()))
  exists = log[log$orig_file == paste(sort(files), collapse = "_") &
               log$variables == paste(sort(variables), collapse = "_"), ]

  # throw an error if we have already made it
  if (nrow(exists)>0) {
    stop(sprintf("This configuration has already been run. The file with these inputs and variables is: %s.",
                 exists$final_file[1]))
  } else if (append != "") {
    new_file_name = paste0("DHS_output", "_", as.character(Sys.Date()),
                           "_", append, ".RDS")
    warning(sprintf("Using append specified in function call: %s.", append))
  } else if (new_file_name %in% log$final_file) {
    if (override) {
      append = format(Sys.time(), "%X")
      new_file_name = paste0("DHS_output", "_", as.character(Sys.Date()),
                             "_", append, ".RDS")
      warning("Base filename already exists, using time as append (since override=T).")
    } else {
      append = readline(prompt = "Base filename already exists. Leave blank to cancel, otherwise enter unique 'append': ")
      if (append == "") {warning("Cancelling because filename already exists."); return()}
      new_file_name = paste0("DHS_output", "_", as.character(Sys.Date()),
                             "_", append, ".RDS")
    }
    if (new_file_name %in% log$final_file) {
      stop("This 'append' already used. Cancelling. Try again and provide a new append.")
    }
  }

  #loop through files and add to the final combined dataframe
  for (i in 1:length(files)) {

    file = files[i]
    geo = geos[i]
    read_file = read_rds(file.path(data_dir, "clean", file)) %>%
      ungroup() %>%
      as.data.frame()

    if (sum(!variables %in% names(read_file)) > 0) {
      warning(sprintf("Variables '%s' aren't included in file '%s'. Running anyway, populating columns w/ NA.",
                      paste(variables[!variables %in% names(read_file)], collapse = ", "), file))
    }

    # if some columns we want don't exist in data, add dummy NA cols
    missings = as.data.frame(matrix(NA, nrow = nrow(read_file),
                                    ncol = sum(!variables %in% names(read_file))))
    names(missings) = variables[!variables %in% names(read_file)]
    read_file = cbind(read_file, missings)
    read_file = read_file[, variables]

    # if there's geo data for that country-year
    if (!is.na(geo)) {
      read_geo = read_rds(file.path(data_dir, "clean", geo)) %>% select(-year)

      # if you had to use a geo that's a year or two off, even if it's from the same
      # wave the ID years need to be changed for merging
      # RIGHT NOW I DON'T THINK THIS IS CORRECT SO I'M NOT GOING TO MERGE DATA
      #   W GEO FROM DIFFERENT YEARS
      #if (substr(read_file$DHSID_EA[1], 3, 6) !=
      #      substr(read_geo$DHSID_EA[1], 3, 6)) {

      #  read_geo$DHSID = paste0(substr(read_geo$DHSID_EA, 1, 2),
      #                          substr(read_file$DHSID_EA[1], 3, 6),
      #                          substr(read_geo$DHSID_EA, 7, 1000))
      #}

      read_file = merge(read_file, read_geo, by = "DHSID_EA", all.x = TRUE)
    } else {

      # if there's no geo, add fake NA columns instead
      missings = as.data.frame(matrix(NA, nrow = nrow(read_file), ncol = 6))
      names(missings) = c("cluster_id", "adm1fips", "adm1dhs", "urban", "lat", "lon")
      read_file = cbind(read_file, missings)
    }

    bound = rbind(bound, read_file)
  }

  # saving out
  output_file_log_saving(bound, data_dir, new_file_name, files,
                         variables, country_years_used)

  return(bound)
}


clean_asset_vars = function(df) {
  rec = function(x) recode(x, "yes" = 1, "no" = 0)
  df = df %>%
    mutate(across(c(hv206:hv212, hv221, hv243a), rec),
           hv201 = as.character(hv201),
           hv205 = as.character(hv205),
           hv213= as.character(hv213)) %>%
    recode(hv201, "piped water" = 11, "piped into dwelling" = 11,
           "piped to yard/plot" = 12, "public tap/standpipe" = 13,
           "tube well water" = 21, "tube well or borehole" = 21,
           "dug well (open/protected)" = 31, "protected well" = 31,
           "unprotected well" = 32, "protected spring" = 41,
           "unprotected spring" = 42,
           "river/dam/lake/ponds/stream/canal/irrigation channel" = 81,
           "rainwater" = 51, "tanker truck" = 61, "cart with small tank" = 71,
           "bottled water" = 91, "community ro plant" = 96, "other" = 96) %>%
    recode(hv205, "flush to piped sewer system" = 11, "flush to septic tank" = 12,
           "flush to pit latrine" = 13, "flush to somewhere else" = 14,
           "flush, don't know where" = 15,
           "ventilated improved pit latrine (vip)" = 21,
           "pit latrine with slab" = 22, "pit latrine without slab/open pit" = 23,
           "no facility/bush/field" = 51, "composting toilet" = 31, "dry toilet" = 41,
           other = 96) %>%
    mutate(hv213 = ifelse(grepl("mud|clay|earth|dirt", hv213, ignore.case = TRUE), 11, hv213),
           hv213 = ifelse(grepl("sand", hv213, ignore.case = TRUE), 12, hv213),
           hv213 = ifelse(grepl("dung|manure", hv213, ignore.case = TRUE), 13, hv213),
           hv213 = ifelse(grepl("palm|bamboo|reed", hv213, ignore.case = TRUE), 22, hv213),
           hv213 = ifelse(grepl("parquet|parket", hv213, ignore.case = TRUE), 31, hv213),
           hv213 = ifelse(grepl("wood", hv213, ignore.case = TRUE), 31, hv213),
           hv213 = ifelse(grepl("brick", hv213, ignore.case = TRUE), 23, hv213),
           hv213 = ifelse(grepl("vinyl|asphalt", hv213, ignore.case = TRUE), 34, hv213),
           hv213 = ifelse(grepl("cement|concrete", hv213, ignore.case = TRUE), 34, hv213),
           hv213 = ifelse(grepl("carpet", hv213, ignore.case = TRUE), 35, hv213),
           hv213 = ifelse(grepl("ceramic", hv213, ignore.case = TRUE), 33, hv213),
           hv213 = ifelse(grepl("marble|stone|granite|tile", hv213, ignore.case = TRUE), 36, hv213)
    )

  recode(hv213, "mud/clay/earth" = 11, "sand" = 12, "dung" = 13,
         "raw wood planks" = 21, "palm, bamboo" = 22, "brick" = 23, "stone" = 24,
         "parquet, polished wood" = 31, "vinyl, asphalt strips" = 32,
         "ceramic tiles" = 33, "cement" = 34, "carpet" = 35,
         "polished stone/marble/granite" = 36, "other" = 96)
}
