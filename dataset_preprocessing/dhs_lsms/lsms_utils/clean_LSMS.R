
library(haven)
library(gtools)
library(reshape2)
library(ggplot2)
library(dplyr)
library(magrittr)


################################################################################
# ETHIOPIA 
################################################################################

# ------------------------------------------------------------------------------
# import data 
# ------------------------------------------------------------------------------

w1 = read_dta("raw/Ethiopia/ERSS_11.12/sect9_hh_w1.dta")
w3 = read_dta("raw/Ethiopia/ERSS_15.16/sect9_hh_w3.dta")
geo = read_dta("raw/Ethiopia/ERSS_11.12/Pub_ETH_HouseholdGeovariables_Y1.dta")


# ------------------------------------------------------------------------------
# drop households that moved 
# ------------------------------------------------------------------------------

# drop migrant households, and split households so that we only keep the 
#   households that are consistent across waves
w3 %<>% 
  filter(hh_s9q02_a >= 4) %>% # drop migrant household, there >4 years
  arrange(household_id, household_id2) %>% # arrange so original id comes first
  filter(!duplicated(household_id), # drops multiples of old id
         household_id %in% w1$household_id)

w1 %<>% 
  filter(household_id %in% w3$household_id)
  
households = w3[, c("household_id", "household_id2")] 


# ------------------------------------------------------------------------------
# get the relevant columns for asset index
# ------------------------------------------------------------------------------

w1_h = w1 %>%
  select(household_id, hh_s9q04, hh_s9q07, hh_s9q10, 
         hh_s9q13, hh_s9q20) %>%
  rename(rooms=hh_s9q04, floor=hh_s9q07, toilet=hh_s9q10, 
         watsup=hh_s9q13, electric=hh_s9q20) %>%
  mutate(electric=ifelse(electric==1, 0, 1)) %>%
  filter(household_id %in% households$household_id)

w3_h = w3 %>%
  select(household_id, household_id2, hh_s9q04, hh_s9q07, hh_s9q10, 
         hh_s9q13, hh_s9q19_a) %>%
  rename(rooms=hh_s9q04, floor=hh_s9q07, toilet=hh_s9q10, 
         watsup=hh_s9q13, electric=hh_s9q19_a) %>%
  mutate(electric=ifelse(electric<=4, 1, 0)) %>%
  filter(household_id2 %in% households$household_id2)


# ------------------------------------------------------------------------------
# recode floor, toilet, and water data as a quality metric
# ------------------------------------------------------------------------------

floor = read.csv("raw/Ethiopia/recode/floor_recode.csv")
toilet = read.csv("raw/Ethiopia/recode/toilet_recode.csv")
watsup = read.csv("raw/Ethiopia/recode/watsup_recode.csv")
w1_h %<>% merge_verbose(floor, by.x="floor", by.y="floor_code", all.x=T)
w1_h %<>% merge_verbose(toilet, by.x="toilet", by.y="toilet_code", all.x=T)
w1_h %<>% merge_verbose(watsup, by.x="watsup", by.y="watsup_code", all.x=T)

watsup = read.csv("raw/Ethiopia/recode/watsup_recode_w3.csv")
toilet = read.csv("raw/Ethiopia/recode/toilet_recode_w3.csv")
w3_h %<>% merge_verbose(floor, by.x="floor", by.y="floor_code", all.x=T)
w3_h %<>% merge_verbose(toilet, by.x="toilet", by.y="toilet_code", all.x=T)
w3_h %<>% merge_verbose(watsup, by.x="watsup", by.y="watsup_code", all.x=T)


# ------------------------------------------------------------------------------
# get asset ownership data
# ------------------------------------------------------------------------------

#import ownership data
w1 = read_dta("raw/Ethiopia/ERSS_11.12/sect10_hh_w1.dta")
w3 = read_dta("raw/Ethiopia/ERSS_15.16/sect10_hh_w3.dta")

#reshape asset ownership data
w1 %<>% 
  filter(hh_s10q0a %in% c("Fixed line telephone", "Radio", "Television", 
                          "Refrigerator", "Private car")) %>%
  select(household_id, hh_s10q0a, hh_s10q01) %>%
  reshape2::dcast(household_id ~ hh_s10q0a) %>%
  mutate_at(vars(-("household_id")), 
                function(x) {ifelse(x>=1, 1, 0)}) %>%
  rename(phone=`Fixed line telephone`, auto=`Private car`, radio=Radio, 
         fridge=Refrigerator, tv=Television)

w3 %<>% 
  filter(household_id2 %in% w3_h$household_id2, 
         hh_s10q0a %in% c("Fixed line telephone", "Radio/tape recorder", 
                          "Television", "Refrigerator", "Private car")) %>%
  select(household_id, hh_s10q0a, hh_s10q01) %>%
  reshape2::dcast(household_id ~ hh_s10q0a) %>%
  mutate_at(vars(-("household_id")), 
            function(x) {ifelse(x>=1, 1, 0)}) %>%
  rename(phone=`Fixed line telephone`, auto=`Private car`, 
         radio=`Radio/tape recorder`, fridge=Refrigerator, tv=Television)


# ------------------------------------------------------------------------------
# combine asset ownership, house traits data, and geography info
# ------------------------------------------------------------------------------

geo %<>% 
  select(household_id, ea_id, LAT_DD_MOD, LON_DD_MOD) %>%
  rename(lat=LAT_DD_MOD, lon=LON_DD_MOD)

#merge the asset w/ house data
w1_h %<>% 
  merge_verbose(w1, by="household_id", all.x=T) %>%
  merge_verbose(geo, by='household_id', all.x=T)

w3_h %<>% 
  merge_verbose(w3, by="household_id", all.x=T) %>%
  merge_verbose(geo, by='household_id', all.x=T)


# ------------------------------------------------------------------------------
# normalize waves and combine
# ------------------------------------------------------------------------------

w1_h %<>% 
  mutate(year = 2011, country = "et") %>%
  select(year, country, household_id, ea_id, lat, lon, 
         rooms, electric, phone, radio, tv, auto, 
         floor_qual, toilet_qual, watsup_qual) %>%
  filter(household_id %in% households$household_id)

w3_h %<>% 
  mutate(year = 2015, country = "et") %>%
  select(year, country, household_id, ea_id, lat, lon, 
         rooms, electric, phone, radio, tv, auto, 
         floor_qual, toilet_qual, watsup_qual) %>%
  filter(household_id %in% households$household_id)

ethiopia = rbind(w1_h, w3_h)
saveRDS(ethiopia, "clean/ethiopia.RDS")
all_ll = ethiopia[, c("lat", "lon", "year")]


################################################################################
# NIGERIA 
################################################################################  

# ------------------------------------------------------------------------------
# import data 
# ------------------------------------------------------------------------------

w1 = read_dta("raw/Nigeria/GHS_10.11/sect8_harvestw1.dta")
w3 = read_dta("raw/Nigeria/GHS_15.16/sect11_plantingw3.dta")
geo = read_dta("raw/Nigeria/GHS_10.11/NGA_HouseholdGeovariables_Y1.dta")


# ------------------------------------------------------------------------------
# drop households that moved 
# ------------------------------------------------------------------------------

w1 %<>%
  filter(paste(state, lga, hhid, sep="_") %in% 
           paste(w3$state, w3$lga, w3$hhid, sep="_")) #removing households not in w3
w3 %<>% filter(hhid %in% w1$hhid) # not new household


# ------------------------------------------------------------------------------
# get the relevant columns for asset index
# ------------------------------------------------------------------------------

w1_h = w1 %>% 
  select(hhid, s8q9, s8q8, s8q36a, s8q33c, s8q17) %>%
  rename(household_id=hhid, rooms=s8q9, floor=s8q8, toilet=s8q36a, 
         watsup=s8q33c, electric=s8q17) %>%
  mutate(electric=ifelse(electric==2, 0, 1))

w3_h = w3 %>% 
  select(hhid, s11q9, s11q8, s11q36, s11q33b, s11q17b) %>%
  rename(household_id=hhid, rooms=s11q9, floor=s11q8, toilet=s11q36, 
         watsup=s11q33b, electric=s11q17b) %>%
  mutate(electric=ifelse(electric==2, 0, 1))


# ------------------------------------------------------------------------------
# recode floor, toilet, and water data as a quality metric
# ------------------------------------------------------------------------------

floor = read.csv("raw/Nigeria/recode/floor_recode.csv")
toilet = read.csv("raw/Nigeria/recode/toilet_recode.csv")
watsup = read.csv("raw/Nigeria/recode/watsup_recode.csv")

w1_h %<>% merge_verbose(floor, by="floor", all.x=T)
w1_h %<>% merge_verbose(toilet, by="toilet", all.x=T)
w1_h %<>% merge_verbose(watsup, by="watsup", all.x=T)

w3_h %<>% merge_verbose(floor, by="floor", all.x=T)
w3_h %<>% merge_verbose(toilet, by="toilet", all.x=T)
w3_h %<>% merge_verbose(watsup, by="watsup", all.x=T)


# ------------------------------------------------------------------------------
# get asset ownership data
# ------------------------------------------------------------------------------

#import asset data
w1 = read_dta("raw/Nigeria/GHS_10.11/sect5_plantingw1.dta")
w3 = read_dta("raw/Nigeria/GHS_15.16/sect5_plantingw3.dta")

#reshape asset data
w1 %<>%
  filter(item_cd %in% c(322, 327,  312, 319)) %>%
  select(hhid, item_cd, s5q1) %>%
  reshape2::dcast(hhid ~item_cd) %>%
  mutate_at(vars(-("hhid")), 
            function(x) {ifelse(x>=1, 1, 0)}) %>%
  mutate_at(vars(-("hhid")), 
            function(x) {ifelse(is.na(x), 0, x)}) %>%
  rename(fridge=`312`, auto=`319`, radio=`322`, tv=`327`) %>%
  rename(household_id=hhid)

#get the mobile phone data seperately
phone = read_dta("raw/Nigeria/GHS_10.11/sect5_harvestw1.dta") %>%
  select(hhid, s5q10) %>%
  group_by(hhid) %>%
  summarise(phone = sum(s5q10, na.rm=T)) %>%
  mutate(phone = ifelse(phone>=1, 1, 0)) %>%
  rename(household_id=hhid)

w1 %<>% merge_verbose(phone, by='household_id', all.x=T)

w3 %<>% 
  filter(item_cd %in% c(322, 327,  312, 319, 332)) %>%
  select(hhid, item_cd, s5q1) %>%
  reshape2::dcast(hhid ~ item_cd) %>%
  mutate_at(vars(-("hhid")), 
            function(x) {ifelse(x>=1, 1, 0)}) %>%
  mutate_at(vars(-("hhid")), 
            function(x) {ifelse(is.na(x), 0, x)}) %>%
  rename(household_id=hhid, fridge=`312`, auto=`319`, radio=`322`, 
         tv=`327`, phone=`332`)
  

# ------------------------------------------------------------------------------
# combine asset ownership, house traits data, and geography info
# ------------------------------------------------------------------------------

#attach geography info
geo %<>% 
  mutate(ea = paste0(zone, state, lga, sector, ea)) %>%
  select(hhid, ea, lat_dd_mod, lon_dd_mod) %>%
  rename(household_id=hhid, ea_id=ea, lat=lat_dd_mod, lon=lon_dd_mod)

w1_h %<>% 
  merge_verbose(geo, by='household_id', all.x=T) %>% # merge geo
  merge_verbose(w1, by="household_id") # merge asset data

w3_h %<>% merge_verbose(geo, by='household_id', all.x=T) %>% # merge geo
  merge_verbose(w3, by="household_id") # merge asset data


# ------------------------------------------------------------------------------
# normalize waves and combine
# ------------------------------------------------------------------------------

#normalize waves and combine
households = intersect(w1$household_id, w3$household_id)

w1_h %<>% 
  mutate(year = 2010, country="ng") %>%
  select(year, country, household_id, ea_id, lat, lon, 
         rooms, electric, phone, radio, tv, auto, 
         floor_qual, toilet_qual, watsup_qual) %>%
  filter(household_id %in% households) 

w3_h %<>% 
  mutate(year = 2015, country="ng") %>%
  select(year, country, household_id, ea_id, lat, lon, 
         rooms, electric, phone, radio, tv, auto, 
         floor_qual, toilet_qual, watsup_qual) %>%
  filter(household_id %in% households)

nigeria = rbind(w1_h, w3_h)

saveRDS(nigeria, "clean/nigeria.RDS")
all_ll = rbind(all_ll, nigeria[, c("lat", "lon", "year")])


################################################################################
# UGANDA
################################################################################

convert_HHw5 = function(data) {
  data %<>% 
    merge(read_dta("raw/Uganda/UNPS_13.14/GSEC1.dta")[, c("HHID", "HHID_old")], 
          by="HHID") %>%
    select(-HHID) %>%
    rename(HHID=HHID_old) %>%
    mutate(HHID=as.character(HHID)) %>%
    select(HHID, everything())
  return(data)
}

# ------------------------------------------------------------------------------
# import data 
# ------------------------------------------------------------------------------

w1 = read_dta("raw/Uganda/UNHS_05.06/GSEC11.dta")
w2 = read_dta("raw/Uganda/UNPS_09.10/GSEC9.dta")
w5 = read_dta("raw/Uganda/UNPS_13.14/GSEC9_1.dta") %>%
  convert_HHw5()
geo = read_dta("raw/Uganda/UNPS_09.10/UNPS_Geovars_0910.dta")


# ------------------------------------------------------------------------------
# drop households that moved 
# ------------------------------------------------------------------------------

households = read_dta("raw/Uganda/UNHS_05.06/GSEC1.dta") %>%
  merge(read_dta("raw/Uganda/UNPS_13.14/GSEC1.dta"), 
        by.x="HHID", by.y="HHID_old") %>%
  filter(h1aq1 == h1aq1a & # households where 09 district == 13 district
           h1aq1 == h1aq1_05) #05 district == 09 district 

w1 %<>% filter(HHID %in% households$HHID) 
w2 %<>% filter(HHID %in% households$HHID)
w5 %<>% filter(HHID %in% households$HHID)


# ------------------------------------------------------------------------------
# get the relevant columns for asset index
# ------------------------------------------------------------------------------

w1_h = w1 %>%
  select(HHID, h11q3a1, h11q6a, h11q10a, h11q7a, h11q11a) %>%
  rename(household_id=HHID, rooms=h11q3a1, floor=h11q6a, 
         toilet=h11q10a, watsup=h11q7a, electric=h11q11a) %>%
  mutate(electric=ifelse(electric==1, 1, 0))

w2_h = w2 %>%
  select(HHID, h9q03, h9q06, h9q22, h9q07) %>%
  rename(household_id=HHID, rooms=h9q03, floor=h9q06, toilet=h9q22, 
         watsup=h9q07)
# get electric info from separate file
w2 = read_dta("raw/Uganda/UNPS_09.10/GSEC10A.dta") %>% 
  select(HHID, h10q1) %>%
  rename(household_id=HHID, electric=h10q1) %>%
  mutate(electric = ifelse(electric==2,0,1))
# merge in electric info
w2_h %<>% merge_verbose(w2, by="household_id", all.x=T)
  
w5_h = w5 %>%
  select(HHID, h9q3, h9q6, h9q22, h9q7) %>%
  rename(household_id=HHID, rooms=h9q3, floor=h9q6, toilet=h9q22, watsup=h9q7)
w5 = read_dta("raw/Uganda/UNPS_13.14/GSEC10_1.dta") %>% 
  # convert to the right household id
  convert_HHw5() %>%
  #actually get the info
  select(HHID, h10q1) %>%
  rename(household_id=HHID, electric=h10q1) %>%
  mutate(electric = ifelse(electric==2, 0, 1))
# merge in electric info
w5_h %<>% merge_verbose(w5, by="household_id", all.x=T)

# ------------------------------------------------------------------------------
# recode floor, toilet, and water data as a quality metric
# ------------------------------------------------------------------------------

floor = read.csv("raw/Uganda/recode/floor_recode.csv")
toilet = read.csv("raw/Uganda/recode/toilet_recode.csv")
watsup = read.csv("raw/Uganda/recode/watsup_recode.csv")

w1_h %<>% merge_verbose(floor, by="floor", all.x=T)
w1_h %<>% merge_verbose(toilet, by="toilet", all.x=T)
w1_h %<>% merge_verbose(watsup, by="watsup", all.x=T)

w2_h %<>% merge_verbose(floor, by="floor", all.x=T)
w2_h %<>% merge_verbose(toilet, by="toilet", all.x=T)
w2_h %<>% merge_verbose(watsup, by="watsup", all.x=T)

floor = read.csv("raw/Uganda/recode/floor_recode_w5.csv")
toilet = read.csv("raw/Uganda/recode/toilet_recode_w5.csv")
watsup = read.csv("raw/Uganda/recode/watsup_recode_w5.csv")

w5_h %<>% merge_verbose(floor, by="floor", all.x=T)
w5_h %<>% merge_verbose(toilet, by="toilet", all.x=T)
w5_h %<>% merge_verbose(watsup, by="watsup", all.x=T)

# ------------------------------------------------------------------------------
# get asset ownership data
# ------------------------------------------------------------------------------

#import asset data
w1 = read_dta("raw/Uganda/UNHS_05.06/GSEC12A.dta") %>%
  select(HHID, h12aq2, h12aq3) %>%
  sjlabelled::unlabel() %>%
  filter(h12aq2 %in% c(12, 7, 14)) %>%
  reshape2::dcast(HHID ~ h12aq2) %>%
  mutate_at(vars(-("HHID")), 
            function(x) {ifelse(x==2, 0, 1)}) %>%
  rename(household_id=HHID, radio=`7`, auto=`12`, phone=`14`) %>%
  mutate(tv=radio) # FROM YEH ET AL, XYZZY
  
w2 = read_dta("raw/Uganda/UNPS_09.10/GSEC14.dta") %>%
  select(HHID, h14q2, h14q3) %>%
  sjlabelled::unlabel() %>%
  filter(h14q2 %in% c(6, 7, 12, 16)) %>%
  reshape2::dcast(HHID ~ h14q2) %>%
  mutate_at(vars(-("HHID")), 
            function(x) {ifelse(x==2, 0, 1)}) %>%
  rename(household_id=HHID, tv=`6`, radio=`7`, auto=`12`, phone=`16`) 

w5 = read_dta("raw/Uganda/UNPS_13.14/GSEC14A.dta") %>% 
  convert_HHw5() %>%
  select(HHID, h14q2, h14q3) %>%
  sjlabelled::unlabel() %>% 
  filter(h14q2 %in% c(6, 7, 12, 16), 
         !is.na(HHID)) %>%
  reshape2::dcast(HHID ~ h14q2) %>%
  mutate_at(vars(-("HHID")), 
            function(x) {ifelse(x==2, 0, 1)}) %>%
  rename(household_id=HHID, tv=`6`, radio=`7`, auto=`12`, phone=`16`) 


# ------------------------------------------------------------------------------
# combine asset ownership, house traits data, and geography info
# ------------------------------------------------------------------------------

#attaching geo data
geo %<>% 
  select(HHID, COMM, lat_mod, lon_mod) %>%
  rename(household_id=HHID, ea_id=COMM, lat=lat_mod, lon=lon_mod)

w1_h %<>% 
  merge_verbose(geo, by='household_id', all.x=T) %>%
  merge_verbose(w1, by='household_id', all.x=T)

w2_h %<>% 
  merge_verbose(geo, by='household_id', all.x=T) %>%
  merge_verbose(w2, by='household_id', all.x=T)

w5_h %<>% 
  merge_verbose(geo, by='household_id', all.x=T) %>%
  merge_verbose(w5, by='household_id', all.x=T)

# ------------------------------------------------------------------------------
# normalize waves and combine
# ------------------------------------------------------------------------------

households = intersect(intersect(w1_h$household_id, w2_h$household_id), 
                       w5_h$household_id)

w1_h %<>% 
  mutate(year=2005, country="ug") %>%
  select(year, country, household_id, ea_id, lat, lon, 
         rooms, electric, phone, radio, tv, auto, 
         floor_qual, toilet_qual, watsup_qual) %>%
  filter(household_id %in% households) 

w2_h %<>% 
  mutate(year=2009, country="ug") %>%
  select(year, country, household_id, ea_id, lat, lon, 
         rooms, electric, phone, radio, tv, auto, 
         floor_qual, toilet_qual, watsup_qual) %>%
  filter(household_id %in% households) 

w5_h %<>% 
  mutate(year=2013, country="ug") %>%
  select(year, country, household_id, ea_id, lat, lon, 
         rooms, electric, phone, radio, tv, auto, 
         floor_qual, toilet_qual, watsup_qual) %>%
  filter(household_id %in% households) 

uganda = rbind(w1_h, w2_h, w5_h)
saveRDS(uganda, "clean/uganda.RDS")
all_ll = rbind(all_ll, uganda[, c("lat", "lon", "year")])


################################################################################
# TANZANIA 
################################################################################

#create key and figure out which households to keep
key = read_dta("raw/Tanzania/TZNPS_12.13/NPSY3_PANEL_KEY.dta")
key = unique(dplyr::select(key, y1_hhid, y3_hhid))
key[key==""] = NA
key = key[complete.cases(key), ]
key = key[!duplicated(key$y1_hhid), ]
w1 = read_dta("raw/Tanzania/TZNPS_08.09/HH_SEC_A_T.dta")
w3 = read_dta("raw/Tanzania/TZNPS_12.13/HH_SEC_A.dta")
w3 = merge_verbose(w3, key, by="y3_hhid")
w3 = w3[paste(w3$y1_hhid, w3$hh_a02_1, sep="_") %in% paste(w1$hhid, w1$district, sep="_"), ] #non-migrant
households = w3$y1_hhid

#import data
w1 = read_dta("raw/Tanzania/TZNPS_08.09/HH_SEC_H1_J_K2_O2_P1_Q1_S1.dta")
w3 = read_dta("raw/Tanzania/TZNPS_12.13/HH_SEC_I.dta")
geo = read_dta("raw/Tanzania/TZNPS_08.09/HH.Geovariables_Y1.dta")

#find the households that existed in w1 and didn't move, geocode them
w3 = merge_verbose(w3, key, by="y3_hhid")
w3 = plyr::rename(w3, c("y1_hhid" = "hhid"))
w1 = w1[w1$hhid %in% households, ] #removing households not in later wave
w3 = w3[w3$hhid %in% households, ] #not new household

#trim cols
w1_h = dplyr::select(w1, hhid, sjq3_1, sjq6, sjq16, sjq8, sjq18)
w3_h = dplyr::select(w3, hhid, y3_hhid, hh_i07_1, hh_i10, hh_i12, hh_i19, hh_i17)
names(w1_h) = c("household_id", "rooms", "floor", "toilet", "watsup", "electric")
names(w3_h) = c("household_id", "household_id3", "rooms", "floor", "toilet", "watsup", "electric")
w1_h$electric = ifelse(w1_h$electric<=2,1,0)
w3_h$electric = ifelse(w3_h$electric<=2,1,0)

#attaching geo data
geo = dplyr::select(geo, hhid, ea_id, lat_modified, lon_modified)
names(geo) = c("household_id", "ea_id", "lat", "lon")
w1_h = merge_verbose(w1_h, geo, by='household_id', all.x=T)   
w3_h = merge_verbose(w3_h, geo, by='household_id', all.x=T)

#import asset data
w1 = read_dta("raw/Tanzania/TZNPS_08.09/HH_SEC_N.dta")
w3 = read_dta("raw/Tanzania/TZNPS_12.13/HH_SEC_M.dta")

#reshape asset data
w1 = w1[w1$sncode %in% c(401, 402, 404, 406, 425),]
w1 = dplyr::select(w1, hhid, sncode, snq1)
w1 =  dcast(w1, hhid ~ sncode)
w1[,2:ncol(w1)] = ifelse(w1[,2:ncol(w1)]==1,1,0)
w1[is.na(w1)] = 0 # THIS SEEMS NOT RIGHT??
names(w1) = c("household_id", "radio", "phone", "fridge", "tv", "auto")

w3 = w3[w3$itemcode %in% c(401, 402, 404, 406, 425),]
w3 = dplyr::select(w3, y3_hhid, itemcode, hh_m01)
w3 =  dcast(w3, y3_hhid ~ itemcode)
w3[,2:ncol(w3)] = ifelse(w3[,2:ncol(w3)]>=1,1,0)
names(w3) = c("household_id", "radio", "phone", "fridge", "tv", "auto")

#merge asset and house data
w1 = merge_verbose(w1_h, w1, by="household_id", all.x=T)
w3 = merge_verbose(w3_h, w3, by.x="household_id3", by.y="household_id", all.x=T)

#recode floor, toilet, watsup
floor = read.csv("raw/Tanzania/recode/floor_recode.csv")
toilet = read.csv("raw/Tanzania/recode/toilet_recode.csv")
watsup = read.csv("raw/Tanzania/recode/watsup_recode.csv")
w1 = merge_verbose(w1, floor, by="floor", all.x=T)
w1 = merge_verbose(w1, toilet, by="toilet", all.x=T)
w1 = merge_verbose(w1, watsup, by="watsup", all.x=T)
w3 = merge_verbose(w3, floor, by="floor", all.x=T)
w3 = merge_verbose(w3, toilet, by="toilet", all.x=T)
w3 = merge_verbose(w3, watsup, by="watsup", all.x=T)

#normalize waves and combine
households = intersect(w1$household_id, w3$household_id)
w1 = w1[w1$household_id %in% households, ]
w3 = w3[w3$household_id %in% households, ]
w1$year = 2008
w3$year = 2012
w1$country = w3$country = "tz"


w1 = w1 %>%
  select(year, country, household_id, ea_id, lat, lon, 
         rooms, electric, phone, radio, tv, auto, 
         floor_qual, toilet_qual, watsup_qual)
w3 = w3 %>%
  select(year, country, household_id, ea_id, lat, lon, 
         rooms, electric, phone, radio, tv, auto, 
         floor_qual, toilet_qual, watsup_qual)

tanzania = rbind(w1, w3)
saveRDS(tanzania, "clean/tanzania.RDS")
all_ll = rbind(all_ll, tanzania[, c("lat", "lon", "year")])


################################################################################
# MALAWI 
################################################################################  

#import data. IMPORTING A BECAUSE ITS ONLY ONE THAT HAS CROSS ID's
w1 = read_dta("raw/Malawi/hh_mod_a_filt_10.dta")
w2 = read_dta("raw/Malawi/hh_mod_a_filt_13.dta")
w3 = read_dta("raw/Malawi/hh_mod_a_filt_16.dta")
geo = read_dta("raw/Malawi/HouseholdGeovariables_IHS3_Rerelease_10.dta")

#building match frame across years, filter to households in all waves
match_11 = w1[, c("HHID", "case_id")]
match_12 = w2[, c("y2_hhid", "HHID")]
match_23 = w3[, c("y3_hhid", "y2_hhid")]
match = merge_verbose(match_12, match_23, by="y2_hhid", all=T)
match = merge_verbose(match, match_11, by="HHID", all=T)
match = match[order(match$HHID, match$y3_hhid),] #assumes that the suffixes mean new branch
match = match[!duplicated(match$HHID),] #removes branches
match = match[complete.cases(match), ]

#removing migrants by making sure they are still in same district
w2 = w2[paste(w2$district, w2$HHID, sep="_") %in% paste(w3$district, w3$HHID, sep="_"), ] 
households = w1[paste(w1$hh_a01, w1$HHID, sep="_") %in% paste(w2$district, w2$HHID, sep="_"), "HHID"]$HHID

#import actual household data and get only the relevant households
w1 = read_dta("raw/Malawi/hh_mod_f_10.dta")
w2 = read_dta("raw/Malawi/hh_mod_f_13.dta")
w3 = read_dta("raw/Malawi/hh_mod_f_16.dta")
w2 = merge_verbose(w2, match, by="y2_hhid")
w3 = merge_verbose(w3, match, by="y3_hhid")
w1 = w1[w1$HHID %in% households, ]
w2 = w2[w2$HHID %in% households, ]
w3 = w3[w3$HHID %in% households, ]

#trim cols
w1_h = dplyr::select(w1, case_id, hh_f10, hh_f09, hh_f41, hh_f36, hh_f19, hh_f31)
w3_h = dplyr::select(w3, case_id, hh_f10, hh_f09, hh_f41, hh_f36, hh_f19, hh_f31)
names(w1_h) = c("household_id", "rooms", "floor", "toilet", "watsup", "electric", "phone")
names(w3_h) = c("household_id", "rooms", "floor", "toilet", "watsup", "electric", "phone")
w1_h[, c("phone", "electric")] = ifelse(w1_h[,c("phone", "electric")]==2,0,1)
w3_h[, c("phone", "electric")] = ifelse(w3_h[,c("phone", "electric")]==2,0,1)

#adding geo
geo = dplyr::select(geo, case_id, ea_id, lat_modified, lon_modified)
names(geo) = c("household_id", "ea_id", "lat", "lon")
w1_h = merge_verbose(w1_h, geo, by='household_id', all.x=T)
w3_h = merge_verbose(w3_h, geo, by='household_id', all.x=T)

#import asset data
w1 = read_dta("raw/Malawi/hh_mod_l_10.dta")
w3 = read_dta("raw/Malawi/hh_mod_l_16.dta")

#reshape asset data
w1 = w1[w1$hh_l02 %in% c(507, 509, 514, 518),]
w1 = dplyr::select(w1, case_id, hh_l02, hh_l01) %>% sjlabelled::unlabel()
w1 =  dcast(w1, case_id ~ hh_l02)
w1[,2:ncol(w1)] = ifelse(w1[,2:ncol(w1)]==1,1,0)
w1[is.na(w1)] = 0
names(w1) = c("household_id", "radio", "tv", "fridge", "auto")

w3 = w3[w3$hh_l02 %in% c(507, 509, 514, 518),]
w3 = dplyr::select(w3, y3_hhid, hh_l02, hh_l03)
w3 =  dcast(w3, y3_hhid ~ hh_l02)
w3[,2:ncol(w3)] = ifelse(w3[,2:ncol(w3)]>=1,1,0)
w3[is.na(w3)] = 0
w3 = merge_verbose(w3, match, by="y3_hhid")
w3 = dplyr::select(w3, case_id, `507`, `509`, `514`, `518`)
names(w3) = c("household_id", "radio", "tv", "fridge", "auto")

#merge asset and house data
w1 = merge_verbose(w1_h, w1, by="household_id", all.x=T)
w3 = merge_verbose(w3_h, w3, by="household_id", all.x=T)

#recode floor, toilet, watsup
floor = read.csv("Malawi/recode/floor_recode.csv")
toilet = read.csv("Malawi/recode/toilet_recode.csv")
watsup = read.csv("Malawi/recode/watsup_recode.csv")
w1 = merge_verbose(w1, floor, by="floor", all.x=T)
w1 = merge_verbose(w1, toilet, by="toilet", all.x=T)
w1 = merge_verbose(w1, watsup, by="watsup", all.x=T)
w3 = merge_verbose(w3, floor, by="floor", all.x=T)
w3 = merge_verbose(w3, toilet, by="toilet", all.x=T)
w3 = merge_verbose(w3, watsup, by="watsup", all.x=T)

households = intersect(w1$household_id, w3$household_id)
w1 = w1[w1$household_id %in% households, ]
w3 = w3[w3$household_id %in% households, ]
w1$year = 2010
w3$year = 2016
w1$country = w3$country = "mw"

w1 %<>% 
  select(year, country, household_id, ea_id, lat, lon, 
         rooms, electric, phone, radio, tv, auto, 
         floor_qual, toilet_qual, watsup_qual)

w3 %<>% 
  select(year, country, household_id, ea_id, lat, lon, 
         rooms, electric, phone, radio, tv, auto, 
         floor_qual, toilet_qual, watsup_qual)

malawi = rbind(w1, w3)
saveRDS(malawi, "clean/malawi.RDS")
all_ll = rbind(all_ll, malawi[, c("lat", "lon", "year")])
all_ll = unique(all_ll)

saveRDS(all_ll, "clean/all_locaitons.RDS")
