# ORG ####

## Packages ####

library(tidyverse)
library(dplyr)
library(stringr) 
library(tokenizers)
library(striprtf)
library(readr)

options(scipen = 10) 


## Working directory ####
### function to set working directory ####

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

try_wd("/Users/mariateplyakova/Nextcloud/project in R/raw_data/LexisNexis")

# General function to load a specific file
load_file <- function(file_path) {
  extension <- tools::file_ext(file_path)
  data <- switch(extension,
                 "csv" = read.csv(file_path),
                 "rds" = readRDS(file_path),
                 "xlsx" = read_excel(file_path),
                 stop("Unsupported file type"))
  return(data)
}


file_path <- "source_data/supreme_data2.csv"

data <- load_file(file_path)

# Add an ideology variable ####

# Extract all unique news_source values
unique_news_sources <- unique(data$news_source)

# Print unique news sources to help create the mapping dictionary
print(unique_news_sources)

## Define the lists of left- and right-leaning news sources ####
left_leaning <- c("libération", "der spiegel", "el pais", "la stampa", "nrc handelsblad", "the guardian")
right_leaning <- c("le figaro", "allgemeine zeitung", "el mundo", "italiaoggi",
                   "de telegraaf", "the daily telegraph")


# Create the new column based on the news_source
data <- data %>%
  mutate(political_orientation = case_when(
    news_source %in% left_leaning ~ "Left",
    news_source %in% right_leaning ~ "Right",
    TRUE ~ "NA"
  ))

head(data)

# Saving the data to the .csv file and testing that it loads correctly (yesterday ones hasn't)

write_delim(data, "supreme_data_ideology.csv", delim = ",", col_names = TRUE)
trial <- read_csv("supreme_data_ideology.csv", col_names = TRUE)
yest <- read_csv("/Users/mariateplyakova/Downloads/supreme_data_ideology_yes.csv", col_names = TRUE)

# Sentiment analysis DE ######

## Subsetting the DE data ####

DE_data <- data %>%
  filter(country == "DE") %>%
  select(X, news_source, text, translated, datePublished_clean, political_orientation)

## Testing the effects of preprocessing the DE and translated data ####

devtools::install_github("matthewjdenny/preText")
library(preText)

### german PreText ####

DE_corpus <- quanteda::corpus(DE_data$text)
DE_corpus_test <- DE_corpus[1:50,]

# preprocess DE data
preprocessed_DE <- factorial_preprocessing(
  DE_corpus_test,
  use_ngrams = TRUE,
  infrequent_term_threshold = 0.02,
  verbose = TRUE)

# run preText
preText_results <- preText(
  preprocessed_DE,
  dataset_name = "German newspaper coverage",
  distance_method = "cosine",
  num_comparisons = 100,
  verbose = TRUE)

head(preprocessed_DE$choices)

# generate preText score plot
preText_score_plot(preText_results)

# generate regression results
regression_coefficient_plot(preText_results,
                            remove_intercept = TRUE)

### translated preText ####
DE_corpus_tr <- quanteda::corpus(DE_data$translated)
DE_corpus_tr_test <- DE_corpus[1:50,]

# preprocess data
preprocessed_DE_tr <- factorial_preprocessing(
  DE_corpus_tr_test,
  use_ngrams = TRUE,
  infrequent_term_threshold = 0.02,
  verbose = TRUE)

# run preText
preText_results_tr <- preText(
  preprocessed_DE_tr,
  dataset_name = "German newspaper coverage in ENG",
  distance_method = "cosine",
  num_comparisons = 100,
  verbose = TRUE)

head(preprocessed_DE_tr$choices)

# generate preText score plot
preText_score_plot(preText_results_tr)

# generate regression results
regression_coefficient_plot(preText_results_tr,
                            remove_intercept = TRUE)

## Preprocessing the DE data ####

DE_data <- DE_data %>%
  mutate(cleaned_text = text %>%
           tolower() %>%  # Convert to lowercase
           removePunctuation() %>%  # Remove punctuation
           removeNumbers() %>%  # Remove numbers
           removeWords(stopwords("en")) %>%  # Remove English stopwords
           stripWhitespace()  # Strip whitespace
  )

DE_corpus <- quanteda::corpus(DE_data$cleaned_text)
docvars(DE_corpus, "index") <- DE_data$X
docvars(DE_corpus, "news_source") <- DE_data$news_source
docvars(DE_corpus, "datePublishedclean") <- DE_data$datePublished_clean
docvars(DE_corpus, "political_orientation") <- DE_data$political_orientation

# Inspect the corpus
summary(head(DE_corpus))

#DE_data$text <- str_to_lower(DE_data$text) # lowercasing
#DE_data$text <- str_remove(DE_data$text, "<.*>") #cleaning the corpus of HTML tags between <>
#DE_data$text <- gsub("[[:punct:]]", " ", DE_data$text)  # Remove punctuation
#DE_data$text <- str_squish(DE_data$text) # removes multiple white spaces, as well as surrounding white spaces

DE_corpus %>%
  tokens(remove_punct = TRUE, remove_numbers = TRUE) %>%
  tokens_remove(stopwords("de"), padding = TRUE) %>% # padding if TRUE, leave an empty string where the removed tokens previously existed, i
  textstat_collocations(min_count = 10) %>%
  arrange(-lambda) # the higher the lambda score, the more surprising the collocation is

## POS tagging ####

# using the `udpipe` package for lemmatization
ud_model <- udpipe_download_model(language = "german")

# Load the German model
ud_model <- udpipe_load_model(ud_model$file_model)

# Annotate the text data
ud_annotated <- udpipe_annotate(ud_model, x = DE_data$cleaned_text)
annotated_df <- as.data.frame(ud_annotated)

head(annotated_df)

# filter for specific POS tags
relevant_pos <- c("ADJ", "ADV", "NOUN", "VERB")
udpipe_df <- annotated_df %>%
  filter(upos %in% relevant_pos)

## Sentiment with quanteda library ####
remotes::install_github("quanteda/quanteda.sentiment")
library(quanteda.sentiment)

print(data_dictionary_Rauh, max_nval = 8)

# Perform sentiment analysis using the Rauh political dictionary
sentiment_results <- DE_corpus %>%
  textstat_polarity(dictionary = data_dictionary_Rauh)

# Rename sentiment column
sentiment_results <- sentiment_results %>%
  rename(sentiment_score = sentiment)

# Add sentiment results to the data
DE_data <- cbind(DE_data, sentiment_score = sentiment_results$sentiment_score)

## Plotting ####

DE_data <- DE_data %>%
  mutate(date_transformed = as.Date(datePublished_clean, format = "%d/%m/%Y"))

# Extract year and month
DE_data <- DE_data %>%
  mutate(year = year(date_transformed),
         month = month(date_transformed, label = TRUE, abbr = TRUE))

# Aggregate sentiment by year, month, and political orientation
sentiment_summary <- DE_data %>%
  group_by(year, month, political_orientation) %>%
  summarize(mean_sentiment = mean(sentiment_score, na.rm = TRUE)) %>%  # Use 'sentiment_score' instead of 'sentiment_results$sentiment'
  ungroup() %>%
  mutate(year_month = paste(year, month, sep = "-"))

# Check the first few rows to ensure the aggregation is correct
head(sentiment_summary)

# Plot the results
ggplot(sentiment_summary, aes(x = as.Date(paste(year, month, "01", sep = "-"), "%Y-%b-%d"), y = mean_sentiment, color = political_orientation, group = political_orientation)) +
  geom_line() +
  geom_point() +
  scale_x_date(date_labels = "%Y-%b", date_breaks = "1 month") +
  labs(title = "Mean Sentiment by Political Orientation (Germany, Rauh Political dictionary)",
       x = "",
       y = "Mean Sentiment",
       color = "Political Orientation") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
  #coord_cartesian(ylim = c(-1, 2))  # Adjust y-axis limits here


## Sentiment analysis DE tr ####

### subsetting data ####
DE_data_tr <- data %>%
  filter(country == "DE") %>%
  select(X, news_source, translated, datePublished_clean, political_orientation)

### cleaning data ####
DE_data_tr <- DE_data_tr %>%
  mutate(cleaned_text = translated %>%
           tolower() %>%  # Convert to lowercase
           removePunctuation() %>%  # Remove punctuation
           removeNumbers() %>%  # Remove numbers
           removeWords(stopwords("en")) %>%  # Remove English stopwords
           stripWhitespace()  # Strip whitespace
  )

### creating a corpus and adding docvars ####

DE_corpus_tr <- quanteda::corpus(DE_data_tr$cleaned_text)
docvars(DE_corpus, "index") <- DE_data$X
docvars(DE_corpus, "news_source") <- DE_data$news_source
docvars(DE_corpus, "datePublishedclean") <- DE_data$datePublished_clean
docvars(DE_corpus, "political_orientation") <- DE_data$political_orientation

### working on the corpus

DE_corpus_tr %>%
  tokens(remove_punct = TRUE, remove_numbers = TRUE) %>%
  tokens_remove(stopwords("en"), padding = TRUE) %>% # padding if TRUE, leave an empty string where the removed tokens previously existed, i
  textstat_collocations(min_count = 10) %>%
  arrange(-lambda) # the higher the lambda score, the more surprising the collocation is

### running sentiment with quanteda library ####

library(quanteda.sentiment)

print(data_dictionary_NRC, max_nval = 8)

# Perform sentiment analysis using the Rauh political dictionary
sentiment_results <- DE_corpus_tr %>%
  textstat_polarity(dictionary = data_dictionary_NRC)

# Rename sentiment column
sentiment_results <- sentiment_results %>%
  rename(sentiment_score = sentiment)

# Add sentiment results to the data
DE_data_tr <- cbind(DE_data_tr, sentiment_score = sentiment_results$sentiment_score)

### plotting ####

DE_data_tr <- DE_data_tr %>%
  mutate(date_transformed = as.Date(datePublished_clean, format = "%d/%m/%Y"))

# Extract year and month
DE_data_tr <- DE_data_tr %>%
  mutate(year = year(date_transformed),
         month = month(date_transformed, label = TRUE, abbr = TRUE))

# Aggregate sentiment by year, month, and political orientation
sentiment_summary_tr <- DE_data_tr %>%
  group_by(year, month, political_orientation) %>%
  summarize(mean_sentiment = mean(sentiment_score, na.rm = TRUE)) %>%  # Use 'sentiment_score' instead of 'sentiment_results$sentiment'
  ungroup() %>%
  mutate(year_month = paste(year, month, sep = "-"))

# Check the first few rows to ensure the aggregation is correct
head(sentiment_summary_tr)

# Plot the results
ggplot(sentiment_summary_tr, aes(x = as.Date(paste(year, month, "01", sep = "-"), "%Y-%b-%d"), y = mean_sentiment, color = political_orientation, group = political_orientation)) +
  geom_line() +
  geom_point() +
  scale_x_date(date_labels = "%Y-%b", date_breaks = "1 month") +
  labs(title = "Mean Sentiment Over Time by Political Orientation (Germany, Translated, NRC dictionary)",
       x = "",
       y = "Mean Sentiment",
       color = "Political Orientation") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
  #coord_cartesian(ylim = c(-1, 1))  # Adjust y-axis limits here



