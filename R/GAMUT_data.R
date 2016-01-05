#'
#' GAMUT_Data
#'
#' get GAMUT data from REDCap, transform/aggregate by
#' individual program. Save as metricData to
#' GAMUT.Rdata file in the data folder
#'
#' @author Rollie Parrish
#' @export
#' 


GAMUT_data <- function(file="data/GAMUT.Rdata") {
    ## load data
    source("R/.REDCap_config.R")
    source("R/anonymize.R")

    GAMUT_data <- tbl_df(redcap_read_oneshot(redcap_uri=uri,
                                      token=GAMUT_token,
                                      export_data_access_groups=TRUE,
                                      raw_or_label = "label")$data)

    AIM_data <- tbl_df(redcap_read_oneshot(redcap_uri=uri,
                                    token=AIM_token,
                                    export_data_access_groups=TRUE,
                                    raw_or_label = "label")$data)

    AEL_data <- tbl_df(redcap_read_oneshot(redcap_uri=uri,
                                    token=AEL_token,
                                    export_data_access_groups=TRUE,
                                    raw_or_label = "label")$data)

    redcap_data <- bind_rows(GAMUT_data, AIM_data, AEL_data)

    mydata <- redcap_data %>%
        mutate(program_name = as.factor(program_name),
               redcap_event_name = as.factor(redcap_event_name),
               redcap_data_access_group = as.factor(redcap_data_access_group),
               program_info_complete = as.factor(program_info_complete),
               monthly_data_complete = as.factor(monthly_data_complete)
               )

    program_info <- mydata %>%
        filter(redcap_event_name == "Initial") %>%
        select(program_name,redcap_data_access_group:program_info_complete)

    ID.lookup <- data.frame(
        program_name = levels(mydata$program_name)
        , ID = anonymize(as.factor(mydata$program_name))
    )

    # ## Bedside STEMI Times
    # bedside_stemi <- plyr::ddply(mydata[mydata$stemi_cases > 0, c(1,2,39,40,41,42)], .(program_name, ID),
    #                        function(x) data.frame(
    #                            bedside_stemi.wavg=weighted.mean(x$mean_bedside_stemi, x$stemi_cases, na.rm=TRUE)
    #                        )
    # )

    mydata <- mydata %>% inner_join(ID.lookup)

    monthly_data <- 
        mydata %>%
        filter(redcap_event_name != "Initial") %>%
        droplevels() %>%
        filter(!is.na(total_patients)) %>%
        mutate(month = as.Date(paste("01", as.character(monthly_data$redcap_event_name)), format = "%d %b %Y")) %>%
        select(program_name, ID, month, redcap_data_access_group, total_patients:monthly_data_complete)

    metricData_count <- monthly_data %>%
        group_by(program_name) %>%
        summarise(months_reported = n())

    metric_data <- monthly_data %>%
        group_by(redcap_data_access_group, ID, program_name) %>%
        summarise_each(funs(sum(., na.rm=TRUE)), -month, -monthly_data_complete)

    GAMUT_date_loaded <- date()

    save(redcap_data, mydata,
         program_info, ID.lookup, monthly_data,
         GAMUT_date_loaded,
         file=file)
}
