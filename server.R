
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
    observeEvent(input$send_to_mysql, {
        send_to_mysql()
    })
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
 
  # average ------------------------------
  output$average <- renderInfoBox(
      infoBox(title = "GAMUT Rolling 12-month Avg", 
              value = paste(total_count()$avg*100,"%"),
              icon = icon("star-half-full"))
  ) # end average

  # benchmark ------------------------------
  output$benchmark <- renderInfoBox(
      infoBox(title = "Achievable Benchmark of Care (ABC)", 
              value = paste0(round(benchmark(input$metric_name),3)*100,"%"),
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

  
# heatmap -----------------------------
  output$heatmap <- renderD3heatmap({
      #check if foo was passed, if it is add the UI elements
      
      heat_data <- 
          monthly_data %>%
          select(1:58) %>%
          filter(month >= as.Date("2015-07-01")) %>%
          group_by(program_name) %>%
          summarise_each(funs(sum(. >= 0, na.rm = TRUE))) %>%
          arrange(program_name) %>%
          data.frame() 
      
      rownames(heat_data) <- heat_data$program_name
      heat_data <- heat_data[,-c(1:4)]
      
      heatmap_plot <- d3heatmap(heat_data, dendrogram = 'none')
      heatmap_plot
      
  })
 })



