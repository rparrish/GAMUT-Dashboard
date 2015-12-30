
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(shinydashboard)

header <- dashboardHeader(
    title = "GAMUT Database"
    #dropdownMenuOutput("messageMenu")
)

# Define the overall UI
dashboardPage(
    skin = "blue",
    header = header,
    dashboardSidebar(
        HTML('<i class="fa fa-filter panelHeader"> Filters</i>'),
        selectInput(
            inputId = "program_name",
            label = "Program Name",
            choices = list("(please assign)", "Akron Childrens", "Cincinnati Childrens"),
            selected = "All"
        ),
         selectInput(
            inputId = "metric_name",
            label = "GAMUT Metric",
            choices = list("Total Patients", "Total Neonatal Patients", "Total Pediatric Patients", "Total Adult Patients"  
                          # "First Intubation Success", "DASH-1a", "Hypothermia"
                           ),
            selectize = FALSE,
            selected = "All"
        ),
       conditionalPanel(
            condition = "input.metric_name == 'Hypothermia'", 
            radioButtons("radio", label = "Age Group",
                     choices = list("All" = 0, "Neonatal" = 1, "Pediatric" = 2, "Adult" = 3), 
                     selected = "")
        ),

        HTML('<i class="fa fa-line-chart panelHeader"> Charts</i>'),
        sidebarMenu(
            menuItem("Runchart", tabName="graph_runchart"),
            menuItem("Measure Information", tabName="information", icon = icon("book")),
            menuItem("Links", tabName="general_links")
        )
    ),
    dashboardBody(
        shiny::tags$head(
            #includeCSS("./www/styles.css"), # Include our custom CSS
            #tags$style(HTML(tags_style))
        ),#End tags$head 
       
        
        
        tabItems( #type = "tabs",
             tabItem(
                tabName = "graph_runchart", 
        fluidRow(
            # A static infoBox
            #infoBox("Participants", 10 * 2, icon = icon("dashboard")),
            infoBoxOutput("total_count"),
            infoBox("Average", 10 * 2, icon = icon("star-half-full")),
            infoBox("Benchmark", 10 * 2, icon = icon("flag-checkered"))
            # Dynamic infoBoxes
        ),
                 shiny::plotOutput(outputId = "runchart", width='95%', height='400px'), 
                HTML("<font color='red'>{<em>Is there some explanatory text you'd like here?</em>}</font><br/>")
                
             ), 
             tabItem(
                tabName = "information", 
                #DT::dataTableOutput(outputId = "ScheduleTableUpcoming"),
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
                 HTML("<font color='red'>{<em>Is there some explanatory text you'd like here?</em>}</font><br/>"),
                htmlOutput(outputId='redcap_outlooks'),
                htmlOutput(outputId='table_file_info')
            )
        ) #End the tabsetPanel
    ) #End the dashboardBody
) #End the dashboardPage
