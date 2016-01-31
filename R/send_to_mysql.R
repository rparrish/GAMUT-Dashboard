

# send_redcap_to_mysql.R


library(RMySQL)
library(REDCapR)
library(dplyr)

send_to_mysql <- function() {
    source("R/MySQL_config.R")
    source("R/.REDCap_config.R")
    
    metric_details <- tbl_df(
        redcap_read_oneshot(
            redcap_uri = uri,
            token = metric_details_token,
            export_data_access_groups = FALSE,
            raw_or_label = "label"
        )$data
    )
     
    GAMUT_data <- tbl_df(
        redcap_read_oneshot(
            redcap_uri = uri,
            token = GAMUT_token,
            export_data_access_groups = TRUE,
            raw_or_label = "label"
        )$data
    )
     AIM_data <- tbl_df(
        redcap_read_oneshot(
            redcap_uri = uri,
            token = AIM_token,
            export_data_access_groups = TRUE,
            raw_or_label = "label"
        )$data
    )
    
    AEL_data <- tbl_df(
        redcap_read_oneshot(
            redcap_uri = uri,
            token = AEL_token,
            export_data_access_groups = TRUE,
            raw_or_label = "label"
        )$data
    )
    
    redcap_data <-
        bind_rows(GAMUT_data, AIM_data, AEL_data)
    
    metadata <-
        data.frame(key = c("GAMUT_date_loaded"),
                   value = Sys.time())
    
## Send to MySQL    
    conn <-  dbConnect(
        RMySQL::MySQL(),
        username = .mysql_username,
        password = .mysql_password,
        host = .mysql_host,
        port = 3306,
        dbname = .mysql_dbname
    )
    
    
    dbWriteTable(
        conn,
        name = "metric_details",
        value = data.frame(metric_details),
        overwrite = TRUE
    )
    dbWriteTable(
        conn,
        name = "GAMUT_data",
        value = data.frame(GAMUT_data),
        overwrite = TRUE
    )
    dbWriteTable(
        conn,
        name = "AEL_data",
        value = data.frame(AEL_data),
        overwrite = TRUE
    )
    dbWriteTable(
        conn,
        name = "AIM_data",
        value = data.frame(AIM_data),
        overwrite = TRUE
    )
    dbWriteTable(
        conn,
        name = "redcap_data",
        value = data.frame(redcap_data),
        overwrite = TRUE
    )
    dbWriteTable(
        conn,
        name = "metadata",
        value = data.frame(metadata),
        overwrite = TRUE
    )
    dbWriteTable(
        conn,
        name = "monthly_data",
        value = data.frame(monthly_data),
        overwrite = TRUE
    )
     
    dbDisconnect(conn)
    
    
}



