
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
    dashboardSidebar(
        sidebarMenu(
            menuItem("Runchart", tabName="graph_runchart", icon = icon("line-chart")),
        #HTML('<i class="fa fa-filter panelHeader"> Filters</i>'),
        
         # selectInput(
         #     inputId = "redcap_data_access_group",
         #     label = "DAG",
         #     choices = levels(as.factor(all_data$redcap_data_access_group)),
         #     selected = "Akron Childrens",
         #     selectize = FALSE
         # ),
         
         uiOutput("program_name"),
         selectInput(
            inputId = "metric_name",
            label = "GAMUT Metric",
            choices = metric_details$short_name,
            selectize = FALSE
        ),
       #radioButtons("chart", "Chart type:",
       #             c("Runchart" = "run",
       #               "SPC p-chart" = "p")),
        
       checkboxInput("showdt", "Show Data Table"),
       #checkboxInput("showdt2", "Show Benchmark Table"),

        #HTML('<i class="fa fa-line-chart panelHeader"> Charts</i>'),
            #menuItem("Measure Definitions", tabName="information", icon = icon("book")),
            #menuItem("Resources", tabName="general_links"), 
            HTML(paste("Data Refreshed:\n", 
                       metadata[metadata$key == "GAMUT_date_loaded", "value"]
                       ))
        ),
       tags$p(),
       tags$a(href = "https://github.com/rparrish/GAMUT-Dashboard/issues",
              target="_blank",
              "Issues or Requests? Click here")
       
       # Refresh data button 
       #actionButton("send_to_mysql", "Refresh data")
    ),
    dashboardBody(
        tabItems(
             tabItem(
                tabName = "graph_runchart", 
       h2(textOutput("dag")),
        fluidRow(
            infoBoxOutput("average", width = 6),
            infoBoxOutput("benchmark", width = 6)
        ),
        fluidRow(
#             box(title = "qic",
#                 footer = "Testing data only",
#                  shiny::plotOutput(outputId = "runchart", width='95%', height='400px'),
#                 width = 6
#                  ),
             box(#title = textOutput("title"),
                footer = textOutput("footer"),
                 shiny::plotOutput(outputId = "runchart", width='95%', height='400px'),
                width = 12
                 ),
             conditionalPanel(
               condition = "input.showdt1 == true", 
                 box( dataTableOutput("data_table"), width = 6 )
             ),
              conditionalPanel(
               condition = "input.showdt == true", 
                 box( DT::dataTableOutput("dt_data_table"), width = 8)
             )
        )
             #   HTML("<font color='red'>{<em>Is there some explanatory text you'd like here?</em>}</font><br/>")  ), 
             ),
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
                verbatimTextOutput("clientdataText")
             )

        ) #End the tabsetPanel
    ) #End the dashboardBody
) #End the dashboardPage
