
library(haven)
library(gtools)
library(reshape2)
library(ggplot2)
library(dplyr)
library(magrittr)
library(readr)

################################################################################
# READ IN CLEAN DATA
################################################################################    

malawi = readRDS("clean/malawi.RDS")
tanzania = readRDS("clean/tanzania.RDS")
ethiopia = readRDS("clean/ethiopia.RDS")
uganda = readRDS("clean/uganda.RDS")
nigeria = readRDS("clean/nigeria.RDS")

################################################################################
# COMBINE EVERYTHING AND ONLY KEEP CONSISTENT HOUSEHOLDS
################################################################################    

full = rbind(malawi, tanzania, ethiopia, uganda, nigeria)

# only keep rows that have all relevant data
index_vars = c("rooms", "electric", "phone", "radio", "tv", "auto", 
               "floor_qual", "toilet_qual", "watsup_qual")
inf_index_vars = c("electric", "watsup_qual", "toilet_qual")
full = full[complete.cases(full[, c(index_vars, "lat", "lon")]), ] 

# drop households that only exist in one timepoint bcz of complete.cases
counts = as.data.frame(table(full$household_id))
counts = as.character(counts[counts$Freq==1,]$Var1)
full %<>%
  filter(!household_id %in% counts) 

# drop households that are only in two of the uganda timepoints
counts = full %>% 
  filter(country == "ug") %>% 
  group_by(household_id) %>% 
  summarise(n = n()) %>%
  filter(n < 3)
counts = counts$household_id
full %<>% 
  filter(!household_id %in% counts)

################################################################################
# CHECK EA #'s AREN'T DUPLICATED & LAT/LON ARE CORRECT
################################################################################  

#find the ea to best allocate each lat/lon to, in the case where a lat/lon has more than one EA
eas = unique(full[, c("lat", "lon", "year", "ea_id")])
eas = eas[order(eas$lat, eas$lon, -as.numeric(eas$ea_id)), ]
eas = eas[!duplicated(eas[, c("lat", "lon", "year")]), ]

full %<>%
  merge_verbose(eas, by=c("lat", "lon", "year"), all.x=T) %>%
  select(-ea_id.x) %>%
  rename(ea_id = ea_id.y)

################################################################################
# CREATE INDEX AND SAVE DATA
################################################################################  

# create the index
full$asset_index = prcomp(full[, index_vars])$x[, 1]
full$infrastructure_index = prcomp(full[, inf_index_vars])$x[, 1]

full_agg = full %>%
  group_by(country, year, ea_id, lat, lon) %>%
  summarise(asset_index = mean(asset_index, na.rm=T), 
            infrastructure_index = mean(infrastructure_index, na.rm=T), 
            n=n())

#--------------------------------------------------------------------------------
write_csv(full_agg, "final_labels/asset_infrstructure_indicies_lsms.csv")
#--------------------------------------------------------------------------------


################################################################################
# GET CHANGES FOR LSMS OVER TIME
################################################################################

# combine full with itself to get matches
full_time = full %>%
  merge(full, by=c("country", "ea_id", "household_id", "lat", "lon")) %>%
  filter(year.y - year.x < 7, 
         year.y > year.x)

# get the differences to create an index out of
differences = full_time[,paste0(index_vars, ".y")] - 
  full_time[,paste0(index_vars, ".x")] 

# get difference of indices
full_time %<>%
  mutate(asset_index = asset_index.y - asset_index.x, 
         infrastructure_index = infrastructure_index.y - infrastructure_index.x)

# get indices of diff
inf_index_vars = paste0(inf_index_vars, ".y")
full_time$asset_index_diff = prcomp(differences)$x[, 1]
full_time$infrastructure_index_diff = prcomp(differences[,inf_index_vars])$x[, 1]

# aggregate to ea level
full_time_agg = full_time %>%
  group_by(country, ea_id, year.x, year.y) %>%
  summarise(asset_index = mean(asset_index), 
            asset_index_diff = mean(asset_index_diff), 
            infrastructure_index = mean(infrastructure_index), 
            infrastructure_index_diff = mean(infrastructure_index_diff), 
            n=n())

#--------------------------------------------------------------------------------
write_csv(full_time_agg, 
          "final_labels/asset_infrstructure_indicies_lsms_over_time.csv")
#--------------------------------------------------------------------------------