
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(qicharts)
library(DBI)
library(dplyr)

# load data --------------------------------
# Connect to MySQL database 
# http://stackoverflow.com/questions/24948549/access-local-mysql-server-with-shiny-io

source("R/MySQL_config.R")

con <-  dbConnect(RMySQL::MySQL(), 
                  username = .mysql_username, 
                  password = .mysql_password,
                  host = .mysql_host, 
                  port = 3306, 
                  dbname = .mysql_dbname
)

mydata <- 
    dbGetQuery(con, "SELECT * FROM monthly_data;")

dbDisconnect(con)
 
# saveRDS(mydata, file = "mydata.RData")

# readRDS(file = "mydata.RData")

# metric data (static) ------------------

mydata_agg_static <-  
    mydata %>%
    #filter(program_name == program_select()) %>%
    select(month, total_patients:unintended_hypothermia) %>%
    group_by(month) %>%
    summarise_each(funs(sum(., na.rm = TRUE))) %>%
    data.frame()


mydata_agg_last <- 
    mydata_agg_static %>%
    filter(row_number() > n()-12) %>%
    select(-month) %>%
    summarize_each(funs(sum)) %>%
    data.frame()


# Shiny server ----------------------------
shinyServer(function(input, output) {

# program select --------------------------
program_select <- reactive({
    a <- ifelse(input$program_name == "(please assign)", NULL, input$program_name)
    a
})


# metric data (reactive) ------------------
# 
 mydata_agg <-  reactive({
    mydata_agg_static     
#     mydata %>%
#     #filter(program_name == program_select()) %>%
#     select(month, total_patients:unintended_hypothermia) %>%
#     group_by(month) %>%
#     summarise_each(funs(sum(., na.rm = TRUE))) %>%
#     data.frame()
 })
#     
       
    
# counts ---------------------------------
    total_count <- reactive({
        counts <- switch(input$metric_name, 
                    
                    `Neonatal Capnography` = {list(
                        patient_count = mydata_agg_last$neo_adv_airway_cases,
                        average     = paste(round(mydata_agg_last$neo_adv_airway_capno/mydata_agg_last$neo_adv_airway_cases*100,1),"%"),
                        benchmark   = "in development"
                        )},
                    
                    `Pediatric Capnography` = {list(
                        patient_count = mydata_agg_last$ped_adv_airway_cases,
                        average     = paste(round(mydata_agg_last$ped_adv_airway_capno/mydata_agg_last$ped_adv_airway_cases*100,1),"%"),
                        benchmark   = "in development"
                        )},
        
                    `Adult Capnography` = {list(
                        patient_count = mydata_agg_last$adult_adv_airway_cases,
                        average     = paste(round(mydata_agg_last$adult_adv_airway_capno/mydata_agg_last$adult_adv_airway_cases*100,1),"%"),
                        benchmark   = "in development"
                        )},
                    
                    
                            `Total Patients` = sum(mydata_agg()$total_patients), 
                            `Total Neonatal Patients` = sum(mydata_agg()$total_neo_patients),
                            `Total Pediatric Patients` = sum(mydata_agg()$total_peds_patients),
                            `Total Adult Patients` = sum(mydata_agg()$total_adult_patients)
                        ) 
        counts       
    })
    
# metric details ---------------------------------
    metric_details <- reactive({
        details <- switch(input$metric_name, 
                    
                    `Neonatal Capnography` = {list(
                        metric_title  = "Neonatal Capnography",
                        metric_footer  = "this is the full title plus some info",
                        metric_ylab   = "Percent"
                    )},
                    `Pediatric Capnography` = {list(
                        metric_title  = "Pediatric Capnography",
                        metric_footer  = "this is the full title plus some info",
                        metric_ylab   = "Percent"
                    )},
                     `Adult Capnography` = {list(
                        metric_title  = "Adult Capnography",
                        metric_footer  = "this is the full title plus some info",
                        metric_ylab   = "Percent"
                    )} 
                     
                    
                    )
       details
    })
     
# runchart ------------------------------
  output$runchart <- renderPlot({
    metric_column <- 
        switch(input$metric_name,
               `Neonatal Capnography` = mydata_agg()$neo_adv_airway_capno/mydata_agg()$neo_adv_airway_cases, 
               `Pediatric Capnography` = mydata_agg()$ped_adv_airway_capno/mydata_agg()$ped_adv_airway_cases, 
               `Adult Capnography` = mydata_agg()$adult_adv_airway_capno/mydata_agg()$adult_adv_airway_cases, 
               
               `Total Patients` = mydata_agg()$total_patients, 
               `Total Neonatal Patients` = mydata_agg()$total_neo_patients,
               `Total Pediatric Patients` = mydata_agg()$total_peds_patients,
               `Total Adult Patients` = mydata_agg()$total_adult_patients
               )

    
    qic(y = metric_column, 
        x = format(as.Date(mydata_agg()$month), "%b %y"),
        main = paste(input$metric_name, "by month"), 
        direction = 1, 
        multiply = 100,
        xlab = "",
        ylab = paste(total_count()$metric_ylab),
        ylim = c(0,100),
        cex = 1.25,
        las = 2
        #sub = "subtitle"
       # runvals = TRUE
        )
  }) # end runchart
 
 # tcc runchart ------------------------------
  output$tcc_runchart <- renderPlot({
    tcc_metric_column <- 
        switch(input$metric_name,
               `Neonatal Capnography` = mydata_agg()$neo_adv_airway_capno/mydata_agg()$neo_adv_airway_cases, 
               `Pediatric Capnography` = mydata_agg()$ped_adv_airway_capno/mydata_agg()$ped_adv_airway_cases, 
               `Adult Capnography` = mydata_agg()$adult_adv_airway_capno/mydata_agg()$adult_adv_airway_cases, 
               
               `Total Patients` = mydata_agg()$total_patients, 
               `Total Neonatal Patients` = mydata_agg()$total_neo_patients,
               `Total Pediatric Patients` = mydata_agg()$total_peds_patients,
               `Total Adult Patients` = mydata_agg()$total_adult_patients
               )

    
    tcc(n = tcc_metric_column, 
        #sum.n = TRUE,
        x = as.Date(mydata_agg()$month),
        main = paste(metric_details()$metric_title), 
        direction = 1, 
        multiply = 100,
        xlab = "",
        date.format = "%b %Y",
        ylab = paste(metric_details()$metric_ylab),
        ylim = c(0,100),
        cex = 1.5,
        pex = .8,
        dec = 1,
        las = 2
        #sub = "subtitle"
       # runvals = TRUE
        )
  }) # end tcc runchart
  
  # patient count -------------------------
  output$patient_count <- renderInfoBox(
      infoBox(title = "Total Patients", 
              value = total_count()$patient_count,
              icon  = icon("dashboard"))
  ) 
  # end patient count 
  
  # program count --------------------------
  output$program_count <- renderInfoBox(
      infoBox(title = "Total Programs", 
              value = total_count()$program_count)
  ) # end program count
 
  # average ------------------------------
  output$average <- renderInfoBox(
      infoBox(title = "Rolling 12-month Avg", 
              value = total_count()$average,
              icon = icon("star-half-full"))
  ) # end average

  # benchmark ------------------------------
  output$benchmark <- renderInfoBox(
      infoBox(title = "Benchmark", 
              value = total_count()$benchmark,
              icon  = icon("flag-checkered"))
  ) # end benchmark

 
  # footer ---------------------------------
  output$footer <- renderText({paste(metric_details()$metric_footer)})

  # data table ---------------------------- 
  output$data_table <- renderDataTable({ mydata_agg_last})
})
