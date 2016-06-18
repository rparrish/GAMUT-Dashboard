

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
        select_(all_data, .dots = c("month", vars[5:6])) %>%
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

    qd <- 
        select_(all_data, .dots = c("month", "program_name", vars[c(5:6)])) %>%
        filter(.[, 3]/.[, 4] <= 1) %>%
        group_by(program_name, month) %>%
        summarise_each(funs(sum(., na.rm = TRUE))) %>%
        ungroup() %>%
        mutate(month = as.Date(month)) %>%
        data.frame()
    
    qd$metric = round(qd[, 3]/qd[, 4],2)

    qd <- qd[qd$program_name == program_name,]
    
    return(qd)
    
}
        



qic_plot <- function(metric_name = "Pediatric Capnography", 
                     chart = "run", 
                     program_name = NULL) {
   
    qd <- qic_data(metric_name, program_name = program_name) 
    names(qd) <- c("program_name", "month", "y", "n", "metric") 
    
    if(nrow(qd) > 6) {
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
        target = .94,
        llabs = c("LCL", "CL", "UCL", "Bench"),
        xlab = "",
        ylab = "Percent",
        #ylab = paste(total_count()$metric_ylab),
        #ylim = c(0,100),
        cex = 1.0,
        las = 2,
        nint = 3,
        #freeze = 12,
        print.out = TRUE,
        plot.chart = TRUE 
        #runvals = TRUE
        #sub = "subtitle"
        
        ) } else {
           #  http://stackoverflow.com/questions/19918985/r-plot-only-text
            plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
            text(x = 0.5, y = 0.5, paste("Insufficient data"), 
                 cex = 1.6, col = "black")
            
        }
   
    results <- list(plot_result = plot_result, data = qd)
    invisible(results)
    
}

