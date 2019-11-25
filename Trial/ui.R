library(shiny)
library(shinythemes)
library(shinyjs)

shinyUI(
  fluidPage(

    
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
            numericInput(
              "thold",
              "Relatedness threshold",
              0,
              min = 0,
              max = 1,
              step = 0.0625
            ),
            br(),
            tableOutput("relatedness_example"),
            br(),
            numericInput("numM", "Number of males needed", 0),
            numericInput("numF", "Number of females needed", 0),
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
      )

    )
))
