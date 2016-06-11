

library(shiny)
library(qicharts)
library(DBI)
library(dplyr)


source("R/MySQL_config.R")

con <-  dbConnect(RMySQL::MySQL(), 
                  username = .mysql_username, 
                  password = .mysql_password,
                  host = .mysql_host, 
                  port = 3306, 
                  dbname = .mysql_dbname
)

all_data <- dbGetQuery(con, "SELECT * FROM monthly_data;")

#monthly_data <- all_data 

metric_details <- dbGetQuery(con, "SELECT * FROM metric_details;")
metadata <- dbGetQuery(con, "SELECT * FROM metadata;")

dbDisconnect(con)

metric_comps <- function(name = "Neonatal Capnography") {
    vars <- filter(metric_details, grepl(name, short_name)) %>%
        as.character()
    
    comp_data <- 
        select_(monthly_data, .dots = c("month", vars[5:6])) %>%
        filter(.[, 2]/.[, 3] <= 1) %>%
        group_by(month) %>%
        summarise_each(funs(sum(., na.rm = TRUE))) %>%
        filter(row_number() > n()-12) %>%
        select(-month) %>%
        summarize_each(funs(sum)) %>%
        data.frame()

    comp_data$avg <- round(comp_data[, 1]/comp_data[, 2],2)
    
    comp_data$benchmark <- "Under construction"

    return(comp_data)
    
}


qic_data <- function(name = "Neonatal Capnography", 
                     program_name  = NULL) {
    vars <- filter(metric_details, grepl(name, short_name)) %>%
    as.character()

    mydata <- monthly_data
    
    #if(!is.null(program_name)) {
        mydata <- filter(mydata, program_name == program_name)
        #} 
        
    qd <- 
        select_(mydata, .dots = c("month", vars[5:6])) %>%
        filter(.[, 2]/.[, 3] <= 1) %>%
        group_by(month) %>%
        summarise_each(funs(sum(., na.rm = TRUE))) %>%
        ungroup() %>%
        mutate(month = as.Date(month)) %>%
        data.frame()
    
    qd$metric = round(qd[, 2]/qd[, 3],2)
    
    return(qd)
    
}
        



qic_plot <- function(metric_name = "Pediatric Capnography", 
                     chart = "run", 
                     program_name = NULL) {
   
    qd <- qic_data(metric_name, program_name = program_name) 
    names(qd) <- c("month", "y", "n", "metric") 
    
    plot_result <- 
        qic(
        y = y, #unintended_hypothermia, 
        n = n, 
        x = month,
        x.format = "%b %Y",
        main = paste(program_name, ": ", metric_name), 
        direction = 1, 
        data = qd,
        chart = chart,
        multiply = 100,
        #target = .94,
        xlab = "",
        ylab = "Percent",
        #ylab = paste(total_count()$metric_ylab),
        #ylim = c(0,100),
        cex = 1.0,
        las = 2,
        nint = 12,
        freeze = 12,
        print = FALSE
        #plot = TRUE 
        #runvals = TRUE
        #sub = "subtitle"
        
        )
    
    results <- list(plot_result = plot_result, data = qd)
    invisible(results)
    
}

