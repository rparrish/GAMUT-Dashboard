
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(shinydashboard)

source("functions.R")

header <- dashboardHeader(
    title = "GAMUT Database"
    #dropdownMenuOutput("messageMenu")
)

# Define the overall UI
dashboardPage(
    skin = "blue",
    header = header,
    # Sidebar ----
    dashboardSidebar(
        #HTML('<i class="fa fa-filter panelHeader"> Filters</i>'),
        
         # selectInput(
         #     inputId = "redcap_data_access_group",
         #     label = "DAG",
         #     choices = levels(as.factor(all_data$redcap_data_access_group)),
         #     selected = "Akron Childrens",
         #     selectize = FALSE
         # ),
      # radioButtons("chart", "Chart type:",
       #               c("Runchart" = "run",
       #                 "SPC p-chart" = "p")),
       #  
       # checkboxInput("showdt", "Show Data Table"),
       # #checkboxInput("showdt2", "Show Benchmark Table"),

        #HTML('<i class="fa fa-line-chart panelHeader"> Charts</i>'),
        sidebarMenu(
            menuItem("Runchart", tabName="graph_runchart", icon = icon("line-chart")),
            menuItem("benchmark_testing", tabName="testing", icon = icon("line-chart")),
            #menuItem("Measure Definitions", tabName="information", icon = icon("book")),
            #menuItem("Resources", tabName="general_links"), 
            HTML(paste("Data Refreshed:<BR>\n",
                       refreshed, 
                       "<BR>",
                       metadata[metadata$key == "GAMUT_date_loaded", "value"]
                       ))
        ),
       tags$p(),
       tags$a(href = "https://github.com/rparrish/GAMUT-Dashboard/issues",
              target="_blank",
              "Issues or Requests? Click here"),
         
         selectInput(
            inputId = "metric_name",
            label = "GAMUT Metric",
            choices = metric_details$short_name,
            selectize = FALSE
        ),
         uiOutput("program_name")
        # radioButtons("chart", "Chart type:",
        #               c("Runchart" = "run",
        #                 "SPC p-chart" = "p"))
        #  
        # checkboxInput("showdt", "Show Data Table")
        #checkboxInput("showdt2", "Show Benchmark Table")
       
       # Refresh data button 
       #actionButton("send_to_mysql", "Refresh data")
    ),

    # Dashboard Body ----
    dashboardBody(
        tabItems(
            # runchart -----
            tabItem(tabName = "graph_runchart", 
                   #h2(textOutput("dag")),

                   fluidRow(box(width = NULL, collapsible = TRUE, solidHeader = TRUE, 
                                title = "this section is still in development", #height = 100,
                        ## infoboxes 
                        #infoBoxOutput("program", width = 4),
                        infoBoxOutput("gamut_average", width = 6),
                        infoBoxOutput("benchmark", width = 6),
                        HTML(paste("Rolling 12-months including ", format(bench_end_date-1, "%b %Y")))
                        )), 
                    fluidRow(
                        ## chart box
                        box(width = 12, collapsible = FALSE,
                            footer = textOutput("footer"),
                            shiny::plotOutput(outputId = "runchart", width='100%', height='300px')
                            )
                    ),
                   fluidRow(
                       ## data table
                       box(width = 12, collapsible = TRUE,
                           #title = "Runchart Data Table", 
                           dataTableOutput("data_table"))
                   )
                   #  fluidRow(
                   #     ## data table
                   #     box(width = 12, collapsible = TRUE,
                   #         #title = "Runchart Data Table", 
                   #         dataTableOutput("benchmark_table"))
                   # )
                    
                   ), 
            # Information ----
            tabItem(
                tabName = "testing",  
                  fluidRow(
                  ## Benchmark tables
                   box(width = 12, collapsible = FALSE,
                          title = "GAMUT Avg Table", 
                          dataTableOutput("gamut_avg_table")),
                   box(width = 12, collapsible = TRUE, collapsed = TRUE,
                          #title = "GAMUT Month Table", 
                          dataTableOutput("gamut_month_table"))
                  )
                
           ),            
            # Information ----
            tabItem(
                tabName = "information",  
                HTML( 
                    "<br/>",
                    "<font color='#605CA8'>GAMUT Database Measure definitions:",
                    "  <table>",
                    "    <tr><td><code>Numerator</code></td><td>Count of ...; </td></tr>",
                    "    <tr><td><code>Denominator</code></td><td>Count of;  </td></tr>",
                    "    <tr><td><code>Exclusions</code></td><td>Explanation;  </td></tr>",
                    "  </table>",
                    "</font>" 
                    ) 
                ),  
            # General Links
            tabItem( 
                tabName = "general_links", 
                tags$h4("Resources"),
                HTML( 
                    "<br/>",
                    "  <table>",
                    "    <tr><td><A HREF='http://www.shinyapps.io'>Shinyapps.io</A></td><td> - </td><td>Dashboard infrastructure and hosting</td></tr>",
                    "    <tr><td><A HREF='https://cran.r-project.org/web/packages/qicharts/index.html'>qicharts</A></td><td> - </td><td>Generates runcharts and statistical process control charts. </td></tr>",
                    "    <tr><td><A HREF='https://github.com/rparrish/GAMUT-Dashboard'>GitHub</A></td><td> - </td><td>GAMUT Dashboard code repository</td></tr>",
                    "  </table>",
                    "</font>" 
                    ),  
                verbatimTextOutput("clientdataText") # debugging output 
                )
        ) #End the tabsetPanel
    ) #End the dashboardBody
) #End the dashboardPage
