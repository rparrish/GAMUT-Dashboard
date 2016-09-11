
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

# load functions

library(GAMUT)
source("functions.R")
#source("R/send_to_mysql.R")

# metric data (static#) ------------------
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
output$program_name <- renderUI({

        
    selectInput(
    inputId = "program_name",
    label = "Program Name",
    choices = { 
        programs <- all_data
        if(dag_name2() != "") {
        programs <- filter(programs, redcap_data_access_group == dag_name2()) %>%
            droplevels()
        }
        
        levels(as.factor(programs$program_name))
        },
    selectize = FALSE
    )
})


# metric data (reactive) -------------#-----
# 
 mydata_agg <-  reactive({
    mydata_agg_static     
 })
#     
 
dag_name2 <- reactive({
    url_search <- session$clientData$url_search 
    dag <- substring(url_search, 6)
    dag_name <- URLdecode(dag) 
    paste(dag_name)
})
    
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

    if(refreshed > 3) {
    #observeEvent(input$send_to_mysql, {
        #send_to_mysql()
    }
    #})
# runchart -----------------------------

  output$runchart <- renderPlot({
      #check if foo was passed, if it is add the UI elements
      query <- parseQueryString(session$clientData$url_search)
      validate(need(!is.null(query$dag), "Please access via REDCap"))
      runchart_plot <- 
          qic_plot(input$metric_name, input$chart, program_name = input$program_name)
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

# Benchmarks -----

  # Program average ------------------------------
  output$program <- renderInfoBox(
      infoBox(title = "Program Avg", 
              subtitle = "testing",
              #fill = TRUE,
              value = 20,#paste(
                  #program_avg(input$metric_name, input$program_name),#$program_avg,#*100,"%"),
              icon = icon("flag"))
  ) # end average

  # GAMUT average -----------------------------
  output$gamut_average <- renderInfoBox(
      infoBox(title = "GAMUT Avg", 
              #subtitle = "testing",
              value =  paste(metric_comps(input$metric_name)$gamut_avg*100,"%"),
              href = "http://127.0.0.1:6123/#shiny-tab-testing",
              fill = TRUE,
              icon = icon("star-half-full"))
  ) # end average

  # benchmark ----------------------------- 
  output$benchmark <- renderInfoBox(
      infoBox(title = "Benchmark (ABC)", 
              subtitle = "testing",
              value = paste0(round(benchmark(input$metric_name),3)*100,"%"),
              icon  = icon("flag-checkered"))
  ) # end benchmark

 
  # footer ---------------------------------
  output$footer <- renderText({paste(metric_info()$full_name)})


  # data table ---------------------------- 
output$program_month_table <- 
    renderDataTable(
        program_data(metric = input$metric_name, 
                     program = input$program_name)$program_month_table,
          options = list(searching = FALSE, paging = FALSE, ordering = FALSE, info = FALSE)

    )


output$program_avg_table <- 
      renderDataTable(
        program_data(metric = input$metric_name, 
                     program = input$program_name)$program_avg_table,
          options = list(searching = FALSE, paging = FALSE, ordering = FALSE, info = FALSE)
      )

  output$data_table <- 
      renderDataTable(
          qic_plot(input$metric_name, program_name = input$program_name)$data %>%
              rename(`Program Name` = program_name, `Month` = month, 
                     `Numerator` = y, `Denominator` = n, `Rate` = metric ), # plot data
          options = list(searching = FALSE, paging = FALSE, ordering = FALSE)
      )

  # benchmark data tables ---------------------------- 
  output$gamut_month_table <- 
      renderDataTable(
          metric_comps(input$metric_name)$gamut_month_table, #GAMUT monthly data table
          options = list(searching = FALSE, paging = FALSE, ordering = FALSE, info = FALSE)
      )

  output$gamut_avg_table <- 
      renderDataTable(
          metric_comps(input$metric_name)$gamut_avg_table, #GAMUT Average table
          options = list(searching = FALSE, paging = FALSE, ordering = FALSE, info = FALSE)
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
  
  # get the DAG from clientData
  output$dag <- renderText({
      url_search <- session$clientData$url_search 
      dag <- substring(url_search, 6)
      dag_name <- URLdecode(dag) 
      paste(dag_name)
      
      
  })
  output$DAG <- renderInfoBox({      
      infoBox(title = "Benchmark",  
              value = dag_name2(),
              icon  = icon("flag-checkered"))
  })
})
