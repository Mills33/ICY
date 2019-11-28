library(shiny)
library(shinythemes)
library(shinyjs)

shinyUI(
  fluidPage(
    
    tags$head(
      HTML(
        "
      <script>
      var socket_timeout_interval
      var n = 0
      $(document).on('shiny:connected', function(event) {
          socket_timeout_interval = setInterval(function(){
            Shiny.onInputChange('alive_count', n++)
          }, 15000)
      });
      $(document).on('shiny:disconnected', function(event) {
          clearInterval(socket_timeout_interval)
      });
      </script>
      "
      ),
      tags$style(
        "
        #keep_alive {
          visibility: hidden;
        }
        "
      )
    ),
    
    theme = shinytheme("cerulean"),
    navbarPage(
      title = div(
        img(
          src = "logo.png",
          style = "margin-top: -14px; padding-right:5px;padding-bottom:5px",
          height = 55
        )
      ),
      windowTitle = "I.C.Y",
      tabPanel(
        "I.C.Y",
        sidebarLayout(
          sidebarPanel(
            fileInput(
              "sbdata",
              "Genetic information from studbook",
              placeholder = "CSV files only",
              accept = c("text/csv")
            ),
            fileInput(
              "kindata",
              "Kinship matrix from studbook",
              placeholder = "CSV files only",
              accept = c("text/csv")
            ),
            fileInput(
              "founder",
              "Founder information from studbook",
              placeholder = "CSV files only",
              accept = c("text/csv")
            ),
            numericInput("numM", "Number of males needed", 0),
            numericInput("numF", "Number of females needed", 0),
            numericInput(
              "thold",
              "Relatedness threshold",
              0,
              min = 0,
              max = 1,
              step = 0.0625
            ),
            useShinyjs(),
            checkboxInput(inputId = "button", label = "Previous releases?"),
            selectizeInput('id', "Select studbook IDs of prior releases", choices = NULL, multiple = TRUE),
            #textInput(inputId = "myBox", value = NA, label ="If known enter studbook IDs here"),
            br(),
            tableOutput("relatedness_example"),
            br(),
            br(),
            downloadButton("report", "Generate report"),
            textOutput("keep_alive")
          ),

          mainPanel(
            tabsetPanel(
              type = "tabs",
              tabPanel(
                "Table",
                tableOutput("chosentable")
              ),
              tabPanel("Plots", plotOutput("chosenplot"))
            )
          )
        )
      ),
      navbarMenu(
        "How to...",
        tabPanel("How to use ICY", includeMarkdown("Documents/HowtoUse.md")),
        tabPanel("How to generate the data", includeMarkdown("Documents/HowtoGenerate.md"))
      ),
      tabPanel("About", includeMarkdown("Documents/About.md"))
    )
    
  )
)
