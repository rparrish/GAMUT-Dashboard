
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(qicharts)
library(DBI)
library(dplyr)

source("MySQL_config.R")

con <-  dbConnect(RMySQL::MySQL(), 
                  username = mysql_username, 
                  password = mysql_password,
                  host = mysql_host, 
                  port = 3306, 
                  dbname = mysql_dbname
)

mydata <- 
    dbGetQuery(con, "SELECT * FROM monthly_data;")
dbDisconnect(con)


# aggregate all programs by month

mydata_agg <- 
    mydata %>%
    select(month, total_patients:unintended_hypothermia) %>%
    group_by(month) %>%
    summarise_each(funs(sum)) %>%
    data.frame()
    
   
shinyServer(function(input, output) {

  output$distPlot <- renderPlot({

    # generate bins based on input$bins from ui.R
    x    <- mydata_agg[, "total_patients"]
    #bins <- seq(min(x), max(x), length.out = input$bins + 1)

    # draw the histogram with the specified number of bins
    # hist(x, breaks = bins, col = 'darkgray', border = 'white')
    tcc(n = x, 
        x = mydata_agg[, "month"],
        main = "Run chart of GAMUT volumes by month - all patient contacts"
        )
  })

})
