source("lsms_utils/lsms_utils.R")
source("lsms_utils/process_uganda.R")

library(haven)
library(reshape2)
library(tidyverse)

data_dir = "lsms_data"

# NIGERIA

# TANZANIA

# UGANDA
extract_uganda(data_dir)
uganda = process_uganda(data_dir)
# all_ll = rbind(all_ll, uganda[, c("lat", "lon", "year", "country")])