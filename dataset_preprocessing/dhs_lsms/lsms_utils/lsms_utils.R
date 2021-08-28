#' Prints number of rows in dataframe, and passes the dataframe through
#'
#' Useful in pipes
#'
print_nrow = function(data, msg = NULL) {
    if (!is.null(msg)) {
        print(paste(msg, nrow(data), sep = ' - '))
    } else {
        print(nrow(data))
    }
    return(data)
}


#' Helper function to extract files and optionally rename them
#'
#' @param zip_path Path to zip file.
#' @param extract_files Character vector of filenames within zip file to
#'   extract
#' @param extract_dir Path to directory for extracted files
#' @param rename Optional character vector of new filenames. If given,
#'   must be same length as `extract_files`.
#' @return Nothing.
#' @export
extract_and_rename = function(zip_path, extract_files, extract_dir, rename = NULL) {
    unzip(zip_path, files = extract_files, overwrite = FALSE, junkpaths = TRUE,
          exdir = extract_dir)
    if (!is.null(rename )) {
        file.rename(file.path(extract_dir, extract_files),
                    file.path(extract_dir, rename))
    }
}


#' Wrapper for merge that lets you know about rows dropped
#' 
#' Lets you know how many rows were dropped if all=F, and how many rows are all NA's if all=T
#'
merge_verbose = function(x, y, by, by.y=by, by.x=by, all=F, all.x=all, 
                         all.y=all, sort=T, suffixes=c(".x", ".y"), no.dups=T) {

  new = merge(x, y, by, by.x, by.y, all, all.x, all.y, sort, suffixes, no.dups)

  x_names = names(new)[names(new) %in% names(x)]
  x_names = c(x_names, names(new)[grepl(suffixes[1], names(new))])
  y_names = names(new)[names(new) %in% names(y)]
  y_names = c(x_names, names(new)[grepl(suffixes[2], names(new))])

  nas_y = rowSums(is.na(new[, x_names]))
  nas_y = sum(nas_y == length(x_names))

  nas_x = rowSums(is.na(new[, y_names]))
  nas_x = sum(nas_x == length(y_names))

  if (nas_x > 0)  {
    print(sprintf("There are %i rows in x that didn't have match in y.", nas_x))
  }
  if (nas_y > 0) {
    print(sprintf("There are %i rows in y that didn't have match in x.", nas_y))
  }
  if (nrow(new) != nrow(x)) {
    print(sprintf("There are %i more rows in new dataset than in x.", nrow(new)-nrow(x)))
  }

  return(new)
}
