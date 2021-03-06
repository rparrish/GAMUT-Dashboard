

library(shiny)
library(qicharts2)
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

metric_details <- dbGetQuery(con, "SELECT * FROM metric_details;") %>%
    filter(!measure_id %in% c("TM-1", "TM-2a", "TM-2b"))

metadata <- dbGetQuery(con, "SELECT * FROM metadata;")
refreshed <- difftime(Sys.time(), 
                           as.Date(metadata[metadata$key == "GAMUT_date_loaded", "value"]),
                           units = "mins") %>% as.numeric() #%>% format()

dbDisconnect(con)

metric_comps <- function(name = "Neonatal Capnography") {
    vars <- filter(metric_details, grepl(name, short_name)) %>%
        as.character()
   
    #gamut_avg_table 
    comp_data <- 
        select_(all_data, .dots = c("month", vars[5:6])) %>%
        filter(.[, 2]/.[, 3] <= 1) %>%
        group_by(month) %>%
        summarise_each(funs(sum(., na.rm = TRUE))) %>%
        filter(row_number() > n()-14 & row_number() < n()-1) %>%
        #select(-month) %>%
        #summarize_each(funs(sum)) %>%
        data.frame()

    #comp_data$avg <- round(comp_data[, 1]/comp_data[, 2],2)
    comp_data$avg <- round(comp_data[, 2]/comp_data[, 3],2)
   
    # gamut_avg_table
    gamut_avg_table <- comp_data %>%
        select(-month) %>%
        summarize_each(funs(sum)) %>%
        mutate(avg = round(.[,1]/.[,2],2)) %>%
        data.frame()
    # gamut_avg
    gamut_avg <- gamut_avg_table$avg 
    
    # abc_benchmark
    abc_benchmark <- "under construction"


    results <- list(gamut_month_table = comp_data,
                    gamut_avg_table = gamut_avg_table, 
                    gamut_avg = gamut_avg) 
   
    return(results)
    
}


# calculate the target benchmark for the specified metric
bench_start_date <- lubridate::floor_date(Sys.Date()-(30+365), unit = "month")
bench_end_date <- lubridate::floor_date(Sys.Date()-60, unit = "month")

benchmark_table <- function(name = "Neonatal Hypothermia", 
                      #method = list("mean_top_pop", "top_decile"),
                      bench_start = bench_start_date, 
                      bench_end =  bench_end_date) {
    vars <- filter(metric_details, grepl(name, short_name)) %>%
        as.character()
    
    bench_data <- 
        select_(all_data, .dots = c("month", "program_name", vars[c(5:6)])) %>%
        select(month, program_name, num = 3, den = 4) %>%
        filter(num/den <= 1) %>%
        filter(as.Date(month) >= as.Date(bench_start), 
               as.Date(month) <= as.Date(bench_end)) %>%
        #filter(substr(month,1,4) == "2015") %>%
        filter(complete.cases(.)) %>%
        group_by(program_name) %>%
        summarise(n = n(), 
                  numerator = sum(num, na.rm = TRUE), 
                  denominator = sum(den, na.rm = TRUE), 
                  rate = numerator/denominator) %>%
        #filter(n >= 9) %>%
        filter(denominator >= 5) %>%
        mutate(abc_rank = (numerator +1)/(denominator + 1)) %>%
        arrange(desc(abc_rank), desc(denominator))
    
    if (vars[7] == "Lower") {
        bench_data <- arrange(bench_data, abc_rank)
    }
   
    bench_data <- mutate(bench_data, 
           rank  = row_number(),
           cusum = cumsum(denominator), 
           perc_population = cusum/sum(bench_data$denominator)
           )
    
    top_pop_all <- 
        bench_data #%>% filter(perc_population <= .1) 
 
    top_pop <- 
        bench_data %>% filter(rank == 1 | perc_population <= .1) 
    
    mean_top_pop <- 
        top_pop %>%
        summarize(value = sum(numerator)/sum(denominator))
    
    top_pop_avg <-
        top_pop %>%
        summarise(numerator = sum(numerator), 
                  denominator = sum(denominator), 
                  abc_avg = round(numerator/denominator,3)) %>%
        mutate(from = bench_start_date, to = bench_end_date) %>%
        select(from, to, numerator, denominator, abc_avg )
    
    abc_value <- top_pop_avg$abc_avg
   
    abc_value <- ifelse(is.finite(abc_value), 
                        paste(round(abc_value,3)*100,"%"), 
                        "insufficient data")
    
    results <- list(top_pop_all = top_pop_all, 
                    top_pop_table = top_pop, 
                    top_pop_avg = top_pop_avg, 
                    abc_value = abc_value)
                    
    return(results)
}


benchmark <- function(name = "Neonatal Hypothermia", 
                      #method = list("mean_top_pop", "top_decile"),
                      bench_start = bench_start_date, 
                      bench_end =  bench_end_date) {
    vars <- filter(metric_details, grepl(name, short_name)) %>%
        as.character()
    
    bench_data <- 
        select_(all_data, .dots = c("month", "program_name", vars[c(5:6)])) %>%
        select(month, program_name, num = 3, den = 4) %>%
        filter(num/den <= 1) %>%
        filter(as.Date(month) >= as.Date("2014-05-01"), #bench_start), 
               as.Date(month) <= as.Date(bench_end)) %>%
        filter(substr(month,1,4) == "2015") %>%
        group_by(program_name) %>%
        summarise(n = n(), 
                  numerator = sum(num), 
                  denominator = sum(den), 
                  rate = numerator/denominator) %>%
        filter(n == 12) %>%
        mutate(abc_rank = (numerator +1)/(denominator + 1)) %>%
        arrange(desc(abc_rank))
   
    decile = .9
    
    if (vars[7] == "Lower") {
        bench_data <- arrange(bench_data, abc_rank)
        decile = .1
    }
   
    bench_data <- mutate(bench_data, 
           rank  = row_number(),
           cusum = cumsum(denominator), 
           perc_population = cusum/sum(bench_data$denominator)
           )
    
    top_decile <- 
        quantile(bench_data$rate, decile)
        
    top_pop <- 
        bench_data %>%
        filter( perc_population <= .1) 
    
    mean_top_pop <- 
        top_pop %>%
        summarize(value = sum(numerator)/sum(denominator))
        
    return(mean_top_pop$value)
}


qic_data <- function(name = "Neonatal Capnography",
                     program_name  = NULL) {
    vars <- filter(metric_details, grepl(name, short_name)) %>%
        as.character()
    
    
    qd <-
        select_(all_data, .dots = c("month", "program_name", vars[c(5:6)])) %>%
        filter(complete.cases(.)) %>%
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
        
qic_plot <- function(metric_name = NULL,
                     chart = "run",
                     program_name = NULL,
                     target = NULL) {
    par(mar = c(5, 4, 4, 2) + 0.1)
    
    qd <- qic_data(metric_name, program_name = program_name)
    names(qd) <- c("program_name", "month", "y", "n", "metric") 
    
    runchart <- plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
    text(x = 0.5, y = 0.5, paste("Insufficient data. Need at least 6 months."),
         cex = 1.6, col = "black") 
    
    if(length(qd$month) >= 6) {
        runchart <- qic(
        y = y, #unintended_hypothermia,
        n = n,
        x = month,
        x.format = "%b %Y",
        title = paste0(program_name, ": ", metric_name),
        #direction = 1,
        data = qd,
        chart = chart,
        point.size = 2.5,
        multiply = 100,
        #target = target,
        #llabs = c("LCL", "Median", "UCL", "Bench"),
        xlab = "",
        ylab = "Percent"
        #ylab = paste(total_count()$metric_ylab),
        #ylim = c(0,100),
        #cex = 1.0,
        #las = 1,
        #nint = 3,
        #freeze = 12,
        #print.out = TRUE,
        #plot.chart = TRUE
    ) +
            ggplot2::theme(text=ggplot2::element_text(size=18))
        
        } else {
        #  http://stackoverflow.com/questions/19918985/r-plot-only-text
        runchart <- plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
        text(x = 0.5, y = 0.5, paste("Insufficient data. Need at least 6 months."),
             cex = 1.6, col = "black")
    }
     
    #results <- list(data = qd, plot = runchart)
    #invisible(results)
    return(runchart)
    
}

qic_plot_old <- function(metric_name = NULL,
                     chart = "run",
                     program_name = NULL,
                     target = .9) {
    par(mar = c(5, 4, 4, 2) + 0.1)
    
    qd <- qic_data(metric_name, program_name = program_name)
    names(qd) <- c("program_name", "month", "y", "n", "metric")
   
    
    #target <-
    #benchmark(name = metric_name, bench_start_date, bench_end_date) %>%
    #round(., 3)
    
    if(nrow(qd) >= 6) {
        plot_result <-
            qic(
                y = y, #unintended_hypothermia,
                n = n,
                x = month,
                x.format = "%b %Y",
                #main = paste(program_name, ": ", metric_name),
                #direction = 1,
                data = qd,
                chart = chart,
                multiply = 100,
                target = target,
                #llabs = c("LCL", "Median", "UCL", "Bench"),
                xlab = "",
                ylab = "Percent"
                #ylab = paste(total_count()$metric_ylab),
                #ylim = c(0,100),
                #cex = 1.0,
                
                #las = 1,
                #nint = 3,
                #freeze = 12,
                
                #print.out = TRUE,
                #plot.chart = TRUE
                #runvals = TRUE
                #sub = "subtitle"
                
            ) } else {
                #  http://stackoverflow.com/questions/19918985/r-plot-only-text
                plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
                text(x = 0.5, y = 0.5, paste("Insufficient data"),
                     cex = 1.6, col = "black")
            }
    
    results <- list(data = qd)
    invisible(results)
    
}



    
