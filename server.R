library(shiny)
library(reticulate)
library(ggplot2)
library(tibble)
library(dplyr)
library(kableExtra)
library(knitr)
library(tinytex)

source_python("ichooseyou_sep.py")

shinyServer(
  function(input, output, session) {
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

    output$chosenplot <- renderPlot({
      inFile1 <- input$sbdata
      if (is.null(inFile1)) {
        return(NULL)
      }

      inFile2 <- input$kindata
      if (is.null(inFile2)) {
        return(NULL)
      }

      if (input$numM == 0 & input$numF == 0) {
        return(NULL)
      }

      female_data <- female_data_format(input$sbdata$datapath)
      male_data <- male_data_format(input$sbdata$datapath)
      female_pie <- create_dataset(female_data)
      male_pie <- create_dataset(male_data)
      colnames(female_pie)[1] <- "UniqueID"
      colnames(male_pie)[1] <- "UniqueID"
      female_pie$UniqueID <- as.numeric(female_pie$UniqueID)
      male_pie$UniqueID <- as.numeric(male_pie$UniqueID)
      female_pie$UniqueID <- round(female_pie$UniqueID)
      male_pie$UniqueID <- round(male_pie$UniqueID)
      female_pie$Percent_contribution <- as.numeric(female_pie$`FounderContribution(%)`)
      male_pie$Percent_contribution <- as.numeric(male_pie$`FounderContribution(%)`)
      female_pie$UniqueID <- as.factor(female_pie$UniqueID)
      male_pie$UniqueID <- as.factor(male_pie$UniqueID)
      female_df <- mutate(female_pie, UniqueID = factor(UniqueID, unique(UniqueID)))
      male_df <- mutate(male_pie, UniqueID = factor(UniqueID, unique(UniqueID)))

      chosentables <- chosen_ones_tables(
        input$sbdata$datapath,
        input$kindata$datapath, input$thold, input$numM, input$numF
      )
      chosentable <- chosentables[, c(12, 1, 2, 3, 4, 5, 6, 9, 11)]

      chosen_ind <- as.numeric(chosentable[[2]])
      All_ind <- rbind(female_df, male_df)
      chosen_graph <- subset(All_ind, All_ind$UniqueID %in% chosen_ind)

      if (is.null(input$founder)) {
        ggplot(chosen_graph, aes(x = Founder, y = Percent_contribution)) +
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
      }
      else {
        founder_pie <- read.csv(input$founder$datapath)
        founder_pie$UniqueID <- gsub(" ", "", founder_pie$UniqueID, fixed = "TRUE")
        founder_pie <- founder_pie[order(-founder_pie$Representation), ]
        number_founders <- length(founder_pie$UniqueID)
        equal_rep <- round((100 / number_founders), digits = 2)

        gg_color_hue <- function(n) {
          hues <- seq(15, 375, length = n + 1)
          hcl(h = hues, l = 65, c = 100)[1:n]
        }

        chosen_graph$Founder <- as.factor(chosen_graph$Founder)

        mycols <- gg_color_hue(length(unique(founder_pie$UniqueID)))
        names(mycols) <- unique(founder_pie$UniqueID)
        mycols["Unk"] <- "black"
        names(founder_pie)[names(founder_pie) == "UniqueID"] <- "Founder"
        chosen_graph
        ggplot(chosen_graph, aes(x = Founder, y = Percent_contribution)) +
          geom_col(aes(fill = Founder), colour = "black", width = 1) +
          geom_hline(yintercept = equal_rep, linetype = "dashed", size = 0.75) +
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
          scale_fill_manual(values = mycols) +
          facet_wrap(~UniqueID) +
          geom_line(data = founder_pie, aes(x = Founder, y = Contribution, group = 1), size = 1)
      }
    })
    output$chosentable <- renderTable({
      inFile1 <- input$sbdata
      if (is.null(inFile1)) {
        return(NULL)
      }

      inFile2 <- input$kindata
      if (is.null(inFile2)) {
        return(NULL)
      }



      chosentables <- chosen_ones_tables(
        input$sbdata$datapath,
        input$kindata$datapath, input$thold, input$numM, input$numF
      )

      chosendata <- chosentables[, c(12, 1, 2, 3, 4, 5, 6, 9, 11)]
    },
    caption = "These birds form a recommended group for reintroduction based on ICYs calculations. Rank is how they were ranked out of all the individuals in the file provided; F is the inbreeding coefficient (a measure of how inbred the bird is 0-1);
   MK is the mean kinship coefficient which is a measure of, on average, how related that individual is to all the others in the file provided; fe stands for the founder equivalents this is a measure of theoretical genetic diversity that takes in to account the number of founders genomes that are represented in the individual and how evenly those genomes are represented. If an individual's Fe value was equal to the number of founders in the population that would imply it has retained as much genetic diversity as possible ",
    caption.placement = getOption("xtable.caption.placement", "top"), striped = TRUE, rownames = FALSE
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
            threshold = input$thold
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

