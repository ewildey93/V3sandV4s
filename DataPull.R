library(sswidb)
library(sswids)
library(dplyr)
library(tidyr)


sswids::connect_to_sswidb(db_version = 'PROD')
date.range <-as.Date(c("2019-01-01", "2024-12-31"))
detections <- sswidb_detections(conn, date_range = date.range)
saveRDS(detections, "./rawdetections.rds")
detections <- readRDS("./rawdetections.rds")
detections$Date <- as.Date(detections$DETECTION_DATETIME)

seasons_df <- 
  create_season_dates(
    min_date = "-01-01",
    max_date = "-12-31",
    years = c(2019,2024)
  )
grid <- "SSWI"

prec <- 0.95

Q <- query_effort(conn = conn, prec = prec, grid = grid, daterange = seasons_df, remove0Timelapse = TRUE)
#removes location in UP, location in middle of lake and locations without needed precision
Q2 <- rm_bad_locations(locationeffort = Q, coordinate_precision = 4)
#assigns camsite id, creates average location coordinates, removes overlapping effort of more than 1 day
Q3 <- merge_nearby_cameras(locationeffort = Q2, cam_distance = 20)
longerdelim <- Q3%>%unnest(cols=c(effort))#separate_longer_delim(., camera_location_seq_no, delim = ",")%>%distinct()
longerdelim$prop_classified[is.na(longerdelim$prop_classified)] <- 1
detectionseffort <- right_join(detections, longerdelim, by=join_by(CAMERA_LOCATION_SEQ_NO == camera_location_seq_no, Date == final_date ))

#testing
table(is.na(detectionseffort$prop_classified))
NAlongerdelim <- longerdelim[is.na(longerdelim$prop_classified),]
table(NAlongerdelim$motion_trigger_count)
table(NAlongerdelim$class_final_trigger_count)

detectionseffort2 <- detectionseffort%>%filter(prop_classified >= 0.95)



cameraLU <- DBI::dbGetQuery(conn, "SELECT
    g83100.sswi_camera_location.camera_location_seq_no,
    g83100.sswi_camera.camera_seq_no,
    g83100.sswi_camera.camera_type_code
FROM
    g83100.sswi_camera_location
INNER JOIN g83100.sswi_camera
ON g83100.sswi_camera.camera_seq_no =
g83100.sswi_camera_location.camera_seq_no;")
cameraLU <- cameraLU%>%mutate(version=case_when(CAMERA_TYPE_CODE == "BUSHNELL119949WI" ~ "V4",
                                                      CAMERA_TYPE_CODE == "BUSHNELL119837WI" ~ "V3",
                                                      CAMERA_TYPE_CODE == "BUSHNELL119836WI" ~ "V2",
                                                      CAMERA_TYPE_CODE == "BUSHNELL119636WI" ~ "V1"))

unique(sswi_camera$CAMERA_TYPE_CODE)
table(sswi_camera$version)
detects.version <- left_join(detectionseffort2, cameraLU, by="CAMERA_LOCATION_SEQ_NO")

detectsfinal <- detects.version%>%select("TRIGGER_SEQ_NO", "SPECIES", "CLASS_KEY", "HIGHEST_USER_CODE", "COUNT", "DETECTION_DATETIME", "Date",
                                         "CAMERA_LOCATION_SEQ_NO", "BATCH_SEQ_NO", "GRID_SEQ_NO", "cam_site_id",
                                         "motion_trigger_count","time_lapse_trigger_count", "class_final_trigger_count", "prop_classified":"version")
saveRDS(detectsfinal, "./detectsfinal.rds")
  

weightdb <- tr_ernest(read = TRUE)[[1]]%>%select("genus", "species", "common_name", "adult_body_mass_g")
species <- sswidb::sswidb_species(conn)
write.csv(species, "species.csv")
species2 <- read.csv("./species.csv")
specieswts <- left_join(species2, weightdb, by = c("genus", "species"))
specieswts <- specieswts[!is.na(specieswts$adult_body_mass_g),]
specieswts$kg <- specieswts$adult_body_mass_g/1000
specieswts <- specieswts%>%mutate(size=case_when(kg < 4 ~ "small",
                                                 kg > 4 & kg < 12 ~ "medium",
                                                 kg > 12 ~ "large"))

detectsNA <- detects[is.na(detects.version$CAMERA_TYPE_CODE),]
CamTypeLU <- detects%>%select(CAMERA_LOCATION_SEQ_NO, CAMERA_TYPE_CODE, version)%>%distinct(CAMERA_LOCATION_SEQ_NO, .keep_all = TRUE)



######################################scrap#########################################
sswi_camera<- DBI::dbGetQuery(conn, "SELECT
g83100.sswi_camera.camera_type_code,
g83100.sswi_camera.camera_seq_no
FROM
g83100.sswi_camera")
sswi_camera <- sswi_camera%>%mutate(version=case_when(CAMERA_TYPE_CODE == "BUSHNELL119949WI" ~ "V4",
                                                      CAMERA_TYPE_CODE == "BUSHNELL119837WI" ~ "V3",
                                                      CAMERA_TYPE_CODE == "BUSHNELL119836WI" ~ "V2",
                                                      CAMERA_TYPE_CODE == "BUSHNELL119636WI" ~ "V1"))

BadCamSeqNo <- detects.version[which(detects.version$CAMERA_SEQ_NO.x != detects.version$CAMERA_SEQ_NO.y),]
BadCamSeqNo <- BadCamSeqNo[,c(20,21,36,28)]
saveRDS(BadCamSeqNo, "./BadCamSeqNo.rds")

cameraLU%>%group_by(CAMERA_LOCATION_SEQ_NO)%>%summarise(N=n())%>%filter(N > 1)
cameraLU%>%group_by(CAMERA_SEQ_NO)%>%summarise(N=n())%>%filter(N > 1)
