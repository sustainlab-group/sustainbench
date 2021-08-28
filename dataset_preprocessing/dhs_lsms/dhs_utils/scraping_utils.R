#' Get the df with all the DHS country-year survey combos
#'
#' Queries the DHS API for a list of surveys and returns a dataframe with two
#' columns ("CountryName", "SurveyYear"). Can be directly fed into
#' download_from_dhs() to download survey data.
#'
#' @import jsonlite
#' @export
get_dhs_surveys_df = function() {
  api = "https://api.dhsprogram.com/rest/dhs/surveys"
  surveys = jsonlite::fromJSON(api)$Data %>%
    dplyr::select(CountryName, SurveyYear) %>%
    unique()
  return(surveys)
}


#' Organize the data downloaded from DHS
#'
#' Called from within the download_from_dhs() function. Takes the location of
#' a ZIP file, extracts the correct files to desired directory, and deletes
#' everything unnecessary.
#'
#' @param zip_path Path to downloaded ZIP file
#' @param filename Name of downloaded ZIP file
#' @param final_path Path to folder to save downloaded files in, should not
#'   end in '/'
#' @param files_keep A string identifier (or vector of identifiers) contained
#'   in the files you want to keep. Defaults to '.dta'. Must be lowercase.
#' @param log Dataframe that contains the log of downloads in the folder, has
#'   3 columns: "filename", "download_date", "year"
filehandling_dhs = function(zip_path, filename, final_path, files_keep = ".dta",
                            log, year) {
  # unzip the downloaded ZIP file
  temp_path = substr(zip_path, 1, nchar(zip_path) - 4)
  unzip(zip_path, exdir = temp_path)

  filename_root = str_split(filename, "[.]")[[1]][1]

  # move the relevant extracted files to permanent folder
  for (f in list.files(temp_path)) {
    if (any(sapply(files_keep, grepl, tolower(f)))) {
      from = file.path(temp_path, f)
      file_type = toupper(str_split(from, "[.]")[[1]][2])
      filename = paste0(filename_root, ".", file_type)
      to = file.path(final_path, filename)
      file.copy(from, to, overwrite = TRUE, copy.date = TRUE)

      log =
        tibble(
          filename = toupper(filename),
          download_date = as.character(Sys.Date()),
          year = year
        ) %>%
        bind_rows(log[toupper(filename) != log$filename, ])
    }
  }

  # delete the zip and other files in download, write log.
  file.remove(zip_path, recursive = TRUE)
  unlink(temp_path, recursive = TRUE)
  write_csv(log, file.path(final_path, "log.csv"))
}


#' Download data from DHS website
#'
#' Only downloads DTA and DBF data files at the moment. Must have a log file
#' with columns 'filename' and 'download_date' in the same folder as the
#' download location. Currently limited by hardcoding for flat files in a few
#' places.
#'
#' @param downloads A data frame with the target downloads. Must have columns
#'   "CountryName" and "SurveyYear". CountryName must be written as it
#'   is on the DHS website, e.g., 'Cote d'Ivoire' not 'cote divoire'
#' @param username Username to log in to the DHS website
#' @param password Password to log in to the DHS website
#' @param download_dir Path to folder to save downloaded files in, should not
#'   end in '/'
#' @param goal_types Types of DHS surveys to download. Options are:
#'   c("Standard", "Special", "MIS", "AIS", "Interim", "Depth", "Continuous").
#'   See https://dhsprogram.com/Methodology/Survey-Types/ for more info.
#' @param recode Types of DHS reformat - Household, Birth, Couple, etc.
#'   Must be formatted in the two digit code DHS uses. Options are:
#'   c("HR", "BR", "CR", "HW", "IR", "KR", "MR", "PR", "GE", "GC", "AR").
#'   See https://dhsprogram.com/data/File-Types-and-Names.cfm for complete list
#'   and more info. Defaults to "HR" (Household Recode), "IR" (Individual
#'   Recode), and "GE" (Geographic Data).
#'
#' @import rvest
#' @import dplyr
#' @import stringr
#' @export
download_from_dhs = function(downloads, username, password,
                             download_dir = "raw",
                             goal_types = c("Standard", "Special", "Continuous", "MIS", "Interim"),
                             recode = c("HR", "IR", "GE"),
                             override = FALSE) {

  recode = paste0(recode, "[0-9]")

  #############################################################################
  # initial startup, login, and crawl of DHS page
  #############################################################################
  downloads$CountryName = as.character(downloads$CountryName)
  downloads$SurveyYear = as.numeric(downloads$SurveyYear)

  found = downloads[0, ]
  url = "https://dhsprogram.com/data/dataset_admin"
  session = rvest::session(url)

  form = rvest::html_form(session)[[2]]
  form = rvest::html_form_set(form, UserName = username)
  form = rvest::html_form_set(form, UserPass = password)
  session = rvest::session_submit(session, form)  # log me in
  print("Logged in!")

  form = rvest::html_form(session)[[2]]
  form = rvest::html_form_set(form, proj_id = as.character(form$fields$proj_id$options[2]))
  form$fields[[2]]$type = "submit"  # create fake submit button
  session = rvest::session_submit(session, form)  # go to project page

  # create a countrysession so that we can come back to main session
  form = rvest::html_form(session)[[3]]
  form$fields[[3]]$type = "submit"
  countrysession = session

  #############################################################################
  # loop through the countries in your downloads df
  #############################################################################
  for (country in unique(downloads$CountryName)) {

    sub = downloads[downloads$CountryName == country, ]
    # figure out which dropdown to hit to go to country page
    if (!any(names(form$fields$Apr_Ctry_list_id$options) == country)) {
      warning(str_glue("Country '{country}' doesn't exist in drop down! ",
                       "Skipping to next country."))
      next
    }
    id = which(names(form$fields$Apr_Ctry_list_id$options) == country)
    id = form$fields$Apr_Ctry_list_id$options[id]
    countryform = rvest::html_form_set(form, Apr_Ctry_list_id = id)
    countrysession = rvest::session_submit(countrysession, countryform)
    message("Working on: ", country)

    # create yearsession so we can return to countrysession
    # see what years we care about for this country
    goal_years = unique(sub$SurveyYear)
    links = countrysession %>%
      rvest::html_nodes(xpath = '//*[@id="link to download Survey datasets"]/a') %>%
      rvest::html_attr("href")
    links2 = countrysession %>%
      rvest::html_nodes(xpath = '//*[@id="Link to download Gps datasets"]/a') %>%
      rvest::html_attr("href")
    links = c(links, links2)
    yearsession = countrysession

    ###########################################################################
    # find cross-year surveys for that country and fix goal years to match
    # noted year
    ###########################################################################
    years_seen = countrysession %>%
      rvest::html_nodes("#CountryName a") %>%
      rvest::html_text()
    years_seen = str_replace_all(years_seen, paste0(country, " "), "")
    links_seen = links
    years_seen = years_seen[grepl("-", years_seen)]

    any_not_rep = sum(sapply(goal_years, grepl, links))
    any_not_rep = any(any_not_rep == 0)

    # if there are any cross year surveys figure out which year link to use
    if (length(years_seen) > 0 & any_not_rep) {
      for (i in 1:length(years_seen)) {

        # figure out what the years it has are
        year1 = substr(years_seen[i], 1, 4)
        year2 = paste0(substr(years_seen[i], 1, 2), substr(years_seen[i], 6, 7))

        # if year2 isn't in links, but is in goal
        if (!any(grepl(year2, links_seen)) & year2 %in% goal_years) {
          goal_years[which(goal_years == year2)] = year1 # use the year 1 link
          warning(str_glue("{country} has a cross-year survey. ",
                           "Your requested year, {year2}, will be downloaded ",
                           "as {year1}."))
        }
        # if year1 isn't in links, but is in goal
        else if (!any(grepl(year1, links_seen)) & year1 %in% goal_years) {
          goal_years[which(goal_years == year1)] = year2 # use the year 2 link
          warning(str_glue("{country} has a cross-year survey. ",
                           "Your requested year, {year1}, will be downloaded ",
                           "as {year2}."))
        }
      }
      goal_years = unique(goal_years)
    }

    ###########################################################################
    # loop through the links to figure out what to download
    ###########################################################################
    for (i in 1:length(links)) {

      # figure out if this survey is relevant to goal year and goal type
      link = links[i]
      is_goal_year = any(sapply(goal_years, grepl, link))
      is_goal_type = any(sapply(goal_types, grepl, link))

      # if it is, go through the list of links for that year
      if (is_goal_year & is_goal_type) {

        # get the links to downloadable files
        year = goal_years[which(sapply(goal_years, grepl, link))][1]
        yearsession = yearsession %>% rvest::session_jump_to(link)
        yearlinks = yearsession %>%
          rvest::html_elements("td a") %>%
          rvest::html_attr("href")
        found[, 1] = as.character(found[, 1])
        found = unique(rbind(data.frame(CountryName = country, SurveyYear = year), found))

        # check if that link is for the correct recode and type
        for (yearlink in yearlinks) {

          # for each of the links for that country-year
          # check if the file is the right recode (HR/GE)
          correct_code = any(sapply(recode, grepl, yearlink))

          # and check that it's the right kind of file
          correct_filetype = grepl("DT[.]", yearlink) | # DT for data
            (any(grepl("GE", recode)) & # FL for geo
               grepl("GE[0-9][0-9a-zA-Z]FL[.]", yearlink))
          should_download = any(all(correct_code, correct_filetype),
                                all(grepl("GE", yearlink), "GE" %in% recode))

          # make sure that it's not already in the log
          if (should_download) {

            # THIS IS HARDCODED FOR FLATFILES!!!!!
            filename = str_match(yearlink, "Filename=(.*?)&")[, 2]
            trunc_filename = substr(filename, 1, nchar(filename) - 6)
            log = read_csv(
              file.path(download_dir, "log.csv"),
              col_types = list(
                filename = col_character(),
                download_date = col_character(),
                year = col_integer()
              )
            )
            # make sure you haven't downloaded it already
            if ((paste0(trunc_filename, "DT.DTA") %in% log$filename) |
                (paste0(trunc_filename, "FL.DBF") %in% log$filename)) {
              warning(str_glue("Already downloaded {filename}! ",
                               "If override = T, will continue."))
              if (!override) {
                next
              }
            }

            ###################################################################
            # actually download the file!
            ###################################################################
            downloading = yearsession %>% rvest::session_jump_to(yearlink)
            download_path = file.path(download_dir, filename)
            writeBin(downloading$response$content, download_path)

            # take out the relevant files and delete the zip
            filehandling_dhs(zip_path = download_path,
                             filename = filename,
                             final_path = download_dir,
                             files_keep = c(".dta", ".dbf"),  # lowercase
                             log = log,
                             year = as.integer(year))
          }
        }
      }
    }
  }

  downloads$SurveyYear = as.numeric(downloads$SurveyYear)
  found$SurveyYear = as.numeric(as.character(found$SurveyYear))
  d = anti_join(downloads, found)
  if (nrow(d) > 0) {
    message("Didn't find following country-years:")
    print(d)
  }
}
