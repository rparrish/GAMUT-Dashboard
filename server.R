
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(qicharts)
library(DBI)
library(dplyr)

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


# aggregate all programs by month

mydata_agg <- 
    mydata %>%
    select(month,  total_patients:unintended_hypothermia) %>%
    group_by(month) %>%
    summarise_each(funs(sum(., na.rm = TRUE))) %>%
    data.frame()
    
shinyServer(function(input, output) {
    
# counts
    total_count <- reactive({
        a <- switch(input$metric_name, 
                    
                            `Neonatal Capnography` = sum(mydata$neo_adv_airway_cases, na.rm = TRUE),
                            `Pediatric Capnography` = sum(mydata$ped_adv_airway_cases, na.rm = TRUE),
                            `Adult Capnography` = sum(mydata$adult_adv_airway_cases, na.rm = TRUE),
                    
                            `Total Patients` = sum(mydata_agg$total_patients), 
                            `Total Neonatal Patients` = sum(mydata_agg$total_neo_patients),
                            `Total Pediatric Patients` = sum(mydata_agg$total_peds_patients),
                            `Total Adult Patients` = sum(mydata_agg$total_adult_patients)
                        ) 
        a
         
    })
    
# metric columns 

  output$runchart <- renderPlot({
    metric_column <- switch(input$metric_name,
                            
                            `Neonatal Capnography` = mydata_agg$neo_adv_airway_capno/mydata_agg$neo_adv_airway_cases, 
                            `Pediatric Capnography` = mydata_agg$ped_adv_airway_capno/mydata_agg$ped_adv_airway_cases, 
                            `Adult Capnography` = mydata_agg$adult_adv_airway_capno/mydata_agg$adult_adv_airway_cases, 
                            
                            `Total Patients` = mydata_agg$total_patients, 
                            `Total Neonatal Patients` = mydata_agg$total_neo_patients,
                            `Total Pediatric Patients` = mydata_agg$total_peds_patients,
                            `Total Adult Patients` = mydata_agg$total_adult_patients
                        )
  # filter by data access group 
    
    qic(y = metric_column, 
        x = format(as.Date(mydata_agg$month), "%b %Y"),
        main = paste(input$metric_name, " by month"), 
        xlab = "Time",
        ylab = "Metric",
        cex = 1.25,
        las = 2
        #sub = "subtitle"
       # runvals = TRUE
        )
  }) # end runchart
  
  output$total_count <- renderInfoBox(
      infoBox(title = "Total Patients", 
              value = total_count())
  ) # end total count

})
