library(shiny)
library(reticulate)
library(ggplot2)
library(tibble)
library(dplyr)
library(kableExtra)
library(knitr)
library(tinytex)

# Fix for using Homebrew installed python on OSX laptops.
use_python("/usr/local/bin/python3")

source_python("ichooseyou_sep.py")

prepGenderTable <- function(x) {
  pie <- create_dataset(x)
  colnames(pie)[1] <- "UniqueID"
  pie$UniqueID <- as.numeric(pie$UniqueID)
  pie$UniqueID <- round(pie$UniqueID)
  pie$Percent_contribution <- as.numeric(pie$`FounderContribution(%)`)
  pie$UniqueID <- as.factor(pie$UniqueID)
  df <- mutate(pie, UniqueID = factor(UniqueID, unique(UniqueID)))
  return(df)
}

baseFounderPlot <- function(chosen_data){
  p <- ggplot(chosen_data, aes(x = Founder, y = Percent_contribution)) +
    geom_col(aes(fill = Founder), colour = "black", width = 1) +
    ylab("Percentage representation") +
    ggtitle("Founder representation of the individuals recommended for reintroduction (coloured bars) 
                compared to the founder representation in current population (black line) ") +
    theme(
      plot.title = element_text(margin = margin(15, 0, 30, 0), hjust = 0.5, family = "Times"),
      legend.title = element_text(family = "Times"),
      legend.text = element_text(family = "Times"),
      axis.ticks.x = element_blank(),
      axis.text.x = element_blank(),
      axis.title.y = element_text(family = "Times"),
      panel.grid.major.x = element_blank()
    ) +
    facet_wrap(~UniqueID)
  return(p)
}

shinyServer(
  function(input, output, session) {
    # We will store the data tables the user is going to use for the analysis
    # as reactive values. This thing is where they will be stored.
    state <- reactiveValues()
    
    # Observes for when the studbook file selector is updated.
    # When it is, this thing reads the data from it, updates the apps dataframes,
    # and updates the options in the prior release dropdown.
    observeEvent(input$sbdata$datapath, {
      message("User uploaded studbook file")
      state$sbdata <- create_data_file(input$sbdata$datapath) # makes sbdata reactive so that the other parts of the app need it they will react if it was not reactive they would not know
      message("Done reading in all studbook data from datapath")
      updateSelectInput(
        session, "id",
        label = "Select studbook IDs of prior releases",
        choices = sort(state$sbdata[,1])
      )
      message("Done updating the options in the dropdown")
    })
    
    # This chosendata reactive expression reduces the amount of repetition that
    # was going on in the app. Both the renderTable and renderPlot were running
    # this code so the work effectively got done twice, and there were two places
    # bugs might appear. So we turn it into a single reactive expression, which only
    # runs once, and then the tables and the plots output use the cached result.
    chosendata <- reactive({
      # Let's validate the needed input parameters
      validate(
        need(input$sbdata$datapath != "", "Please load a genetic information file."),
        need(input$kindata$datapath != "", "Please load a kinship matrix file."),
        need((input$numF + input$numM) > 0, "Please set either 'Number of males needed' or 'Number of females needed' (or both) to a value larger than or equal to 0.")
      )
      
      if (is.null(input$id)) {
        chosentable <- chosen_ones_tables(
          input$sbdata$datapath,
          input$kindata$datapath,
          input$thold,
          input$numM,
          input$numF
        )
     } else {
        chosentable <- chosen_table_with_prior(
          input$sbdata$datapath,
          input$kindata$datapath,
          input$thold,
          input$numM,
          input$numF,
          input$id
        )
     }
     message("ICY has chosen individuals according to users updated parameters")
     
     validate(
       need(sum(chosentable$Sex == "Male") == input$numM, "ICY could not find enough males that satisfied user parameters."),
       need(sum(chosentable$Sex == "Female") == input$numF, "ICY could not find enough females that satisfied user parameters.")
      )
     
     if (nrow(chosentable) == 0 && input$numM > 0 && input$numF > 0) {
       message("There are no individuals that satisfy the users parameters")
     }
     return(chosentable[, c(12, 1, 2, 3, 4, 5, 6, 9, 11)])
    })
    
    # Display the table of individuals chosen by the python chooser.
    output$chosentable <- renderTable(
      {
        return(chosendata())
      },
      caption = "These individuals form a recommended group for reintroduction based on ICYs calculations. Rank is how they were ranked out of all the individuals in the file provided; F is the inbreeding coefficient (a measure of how inbred the bird is 0-1);
   MK is the mean kinship coefficient which is a measure of, on average, how related that individual is to all the others in the file provided; fe stands for the founder equivalents this is a measure of theoretical genetic diversity that takes in to account the number of founders genomes that are represented in the individual and how evenly those genomes are represented. If an individual's Fe value was equal to the number of founders in the population that would imply it has retained as much genetic diversity as possible ",
      caption.placement = getOption("xtable.caption.placement", "top"),
      striped = TRUE,
      rownames = FALSE
    )
    
    # Create and display a plot of the founder representation, for the chosen
    # individuals.
    output$chosenplot <- renderPlot({
      chosentable <- chosendata()
      # Require that the studbook data is loaded, and that there are actually some
      # chosen individuals.
      validate(
        need(nrow(chosentable) > 0, "There are no individuals satisfying your parameters")
      )
      
      message("ICY is plotting founder representation for the chosen individuals...")
      female_df <- prepGenderTable(female_data_format_df(state$sbdata))
      male_df <- prepGenderTable(male_data_format_df(state$sbdata))
      All_ind <- rbind(female_df, male_df)
      chosen_ind <- as.numeric(chosentable[[2]])
      chosen_graph <- subset(All_ind, All_ind$UniqueID %in% chosen_ind)
      
      if (is.null(input$founder)) {
        baseFounderPlot(chosen_graph)
      } else {
        chosen_graph$Founder <- as.factor(chosen_graph$Founder)
        
        fplot <- baseFounderPlot(chosen_graph)
        
        # Now we have the base founder plot, the additions and tweaks to add the
        # comparrison to the population can be applied.
        
        founder_pie <- read.csv(input$founder$datapath)
        founder_pie$UniqueID <- gsub(" ", "", founder_pie$UniqueID, fixed = "TRUE")
        founder_pie <- founder_pie[order(-founder_pie$Representation), ]
        number_founders <- length(founder_pie$UniqueID)
        equal_rep <- round((100 / number_founders), digits = 2)
        gg_color_hue <- function(n) {
          hues <- seq(15, 375, length = n + 1)
          hcl(h = hues, l = 65, c = 100)[1:n]
        }
        mycols <- gg_color_hue(length(unique(founder_pie$UniqueID)))
        names(mycols) <- unique(founder_pie$UniqueID)
        mycols["Unk"] <- "black"
        names(founder_pie)[names(founder_pie) == "UniqueID"] <- "Founder"
        
        fplot +
          scale_fill_manual(values = mycols) +
          geom_line(data = founder_pie, aes(x = Founder, y = Contribution, group = 1), size = 1)
      }
    })
    
    observeEvent(input$button, {
      shinyjs::toggle("id")
    })
    
    output$relatedness_example <- renderTable({
      Relatedness <- as.factor(c("0.0000", "0.0313", "0.0625", "0.1250", "0.2500", "0.5000", "1.000"))
      Relationship <- c(
        "Unrelated", "Second-cousins", "Half-cousins, cousins-once-removed", "Cousins, great-grandparents",
        "Half-siblings, grandparents, uncle/aunt", "Siblings, parent", "Clone"
      )
      df <- data.frame(Relatedness, Relationship)
    },
    caption = "When choosing the relatedness threshold it can help to think in terms of familial relationships. If no individuals are returned at a certain threshold try increasing the threshold thereby allowing more related individuals to be selected.",
    striped = TRUE, rownames = FALSE
    )

    output$report <- downloadHandler(
      filename = "ICY_report.pdf",
      content = function(file) {
        withProgress(message = "Generating report. Please wait...", value = 1, {
          src <- normalizePath("ICY.Rmd")
          
          owd <- setwd(tempdir())
          on.exit(setwd(owd))
          file.copy(src, "ICY.Rmd", overwrite = TRUE)
          
          parameters <- list(
            all_data = input$sbdata$datapath,
            kinship = input$kindata$datapath,
            founder = input$founder$datapath,
            numbFem = input$numF,
            numbMal = input$numM,
            threshold = input$thold,
            prior = input$id
          )
          
          rmarkdown::render(
            src, clean = TRUE,
            params = parameters,
            envir = new.env(),
            output_format = "pdf_document",
            output_file = file
          )
        })
      })
    
    output$keep_alive <- renderText({
      req(input$alive_count)
      input$alive_count
    })
  }
)

