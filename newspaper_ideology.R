# Packages

library(tidyverse)
library(dplyr)
library(stringr) 
library(tokenizers)
library(striprtf)

options(scipen = 10) 


######### set working directory ##########
## function to set working directory:
try_wd <- function(wd){
  
  tryCatch(                       
    
    expr = {
      
      setwd(wd)
      
      # Message if no error:
      message("WD set")
      
    },
    error = function(e){        
      
      # Warning message
      message("Warning: wd not set!")
    }
  )
  
  
}


# set wd (WHERE THE DATA IS STORED)  JUST ENTER THE PATH where your files are stored into the functioN try_wd(..)
# you dont have to delete the other try_wd() commands... :-)
try_wd("/Users/mariateplyakova/Nextcloud/project in R/raw_data/LexisNexis")

data <- read.csv("merged_cleaned.csv")

# Extract all unique news_source values
unique_news_sources <- unique(data$news_source)

# Print unique news sources to help create the mapping dictionary
print("Unique news sources:")
print(unique_news_sources)

standardization_mapping <- list(
  'The Daily Telegraph (London)' = 'The Daily Telegraph',
  'THE DAILY TELEGRAPH(LONDON)' = 'The Daily Telegraph',
  'The Daily Telegraph (LONDON)' = 'The Daily Telegraph',
  'El Pais' = 'El País')

# Function to standardize news source names
standardize_news_source <- function(news_source) {
  return(standardization_mapping[[news_source]] %||% news_source)
}

# Standardize the news_source names
data <- data %>%
  mutate(standardized_news_source = sapply(news_source, standardize_news_source))


# Define the lists of left- and right-leaning news sources
left_leaning <- c("Libération", "Der Spiegel", "El País", "La Stampa", "NRC Handelsblad", "The Guardian")
right_leaning <- c("Le Figaro", "Frankfurter Allgemeine Zeitung", "El Mundo", "ItaliaOggi",
                   "De Telegraaf", "The Daily Telegraph")


# Create the new column based on the news_source
data <- data %>%
  mutate(political_orientation = case_when(
    standardized_news_source %in% left_leaning ~ "Left",
    standardized_news_source %in% right_leaning ~ "Right",
    TRUE ~ "NA"
  ))

head(data)
