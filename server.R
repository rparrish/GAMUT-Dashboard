
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

# load functions

source("functions.R")
source("R/send_to_mysql.R")

# metric data (static) ------------------
# 
# mydata_agg_static <-  
#     monthly_data %>%
#     #filter(program_name == program_select()) %>%
#     select(month, total_patients:unintended_hypothermia) %>%
#     group_by(month) %>%
#     summarise_each(funs(sum(., na.rm = TRUE))) %>%
#     data.frame()
# 
# 
# mydata_agg_last <- 
#     mydata_agg_static %>%
#     filter(row_number() > n()-12) %>%
#     select(-month) %>%
#     summarize_each(funs(sum)) %>%
#     data.frame()


# Shiny server ----------------------------
shinyServer(function(input, output, session) {

# program select --------------------------
program_select <- reactive({
    a <- ifelse(input$program_name == "(please assign)", NULL, input$program_name)
    a
})


# metric data (reactive) ------------------
# 
 mydata_agg <-  reactive({
    mydata_agg_static     
 })
#     
       
    
# counts ---------------------------------
    total_count <- reactive({
        comps <- metric_comps(input$metric_name) 
        comps
    })
    
# metric info ---------------------------------
    metric_info <- reactive({
        
        details <- 
            metric_details %>%
            filter(short_name == input$metric_name)
 
       details
    })
    
# refresh data -----------------------------
    observeEvent(input$send_to_mysql, {
        send_to_mysql()
    })
# runchart -----------------------------

  output$runchart <- renderPlot({
      
      runchart_plot <- 
          qic_plot(input$metric_name, input$chart)
  })
 
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
              value = paste(total_count()$avg*100,"%"),
              icon = icon("star-half-full"))
  ) # end average

  # benchmark ------------------------------
  output$benchmark <- renderInfoBox(
      infoBox(title = "Benchmark", 
              value = total_count()$benchmark,
              icon  = icon("flag-checkered"))
  ) # end benchmark

 
  # footer ---------------------------------
  output$footer <- renderText({paste(metric_info()$full_name)})


  # data table ---------------------------- 
  output$data_table <- 
      renderDataTable(
          qic_plot(input$metric_name)$data, # plot data
          options = list(searching = FALSE, paging = FALSE, ordering = FALSE)
      )

  # data table ---------------------------- 
  output$benchmark_table <- 
      renderDataTable(
          metric_comps(input$metric_name), #benchark data
          options = list(searching = FALSE, paging = FALSE, ordering = FALSE)
      )

  # client data ---------------------------- 
  # Store in a convenience variable
  cdata <- session$clientData
  
  # Values from cdata returned as text
  output$clientdataText <- renderText({
      cnames <- names(cdata)
      
      allvalues <- lapply(cnames, function(name) {
          paste(name, cdata[[name]], sep=" = ")
      })
      paste(allvalues, collapse = "\n")
  })
})
