

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

monthly_data <- dbGetQuery(con, "SELECT * FROM monthly_data;")

metric_details <- dbGetQuery(con, "SELECT * FROM metric_details;")

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
    
    comp_data$benchmark <- "benchmark"

    return(comp_data)
    
}


qic_data <- function(name = "Neonatal Capnography") {
    vars <- filter(metric_details, grepl(name, short_name)) %>%
    as.character()

    qd <- 
        select_(monthly_data, .dots = c("month", vars[5:6])) %>%
        filter(.[, 2]/.[, 3] <= 1) %>%
        group_by(month) %>%
        summarise_each(funs(sum(., na.rm = TRUE))) %>%
        ungroup() %>%
        mutate(month = as.Date(month)) %>%
        data.frame()
    
    qd$metric = round(qd[, 2]/qd[, 3],2)
    
    return(qd)
    
}
        



qic_plot <- function(metric_name = "Pediatric Capnography") {
   
    qd <- qic_data(metric_name) 

    plot_result <- 
        tcc(
        n = metric, 
        x = month,
        date.format = "%b %Y",
        main = paste(metric_name), 
        direction = 1, 
        data = qd,
        multiply = 100,
        xlab = "",
        #ylab = paste(total_count()$metric_ylab),
        #ylim = c(0,100),
        cex = 1.25,
        las = 2,
        print = FALSE
        #plot = TRUE 
        #runvals = TRUE
        #sub = "subtitle"
        
        )
    
    results <- list(plot_result = plot_result, data = qd)
    invisible(results)
    
}

