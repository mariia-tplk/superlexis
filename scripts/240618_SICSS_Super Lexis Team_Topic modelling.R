#install.packages('stm')
#install.packages('tidyverse')
#install.packages('tm')
#install.packages('quanteda')
#install.packages("igraph")

library(igraph)
library(quanteda)
library(stm)
library(tidyverse)

# Load the cleaned data
df <- read.csv('majestic_data.csv')

# Define the lists of left- and right-leaning news sources
left_leaning <- c("libération", "der spiegel", "el pais", "la stampa", "nrc handelsblad", "the guardian")
right_leaning <- c("le figaro", "allgemeine zeitung", "el mundo", "italiaoggi",
                   "de telegraaf", "the daily telegraph")
# Create the new column based on the news_source
df <- df %>%
  mutate(political_orientation = case_when(
    news_source %in% left_leaning ~ "Left",
    news_source %in% right_leaning ~ "Right",
    TRUE ~ "NA"
  ))



# Create a corpus
corpus <- corpus(df, text_field = 'translated')

# Tokenize the corpus
tokens <- tokens(corpus, remove_punct = TRUE, remove_symbols = TRUE, remove_numbers = TRUE)

# Create a document-feature matrix
dfm <- dfm(tokens)

# Remove stopwords
dfm <- dfm_remove(dfm, pattern = stopwords("english"))

# Convert to STM format
stm_data <- convert(dfm, to = "stm", docvars = df)

# Fit the STM model
model_political_orientation <- stm(documents = stm_data$documents, vocab = stm_data$vocab, K = 20, prevalence = ~ political_orientation, data = stm_data$meta)

# Summary of the model
summary(model_political_orientation)

label_topics <- labelTopics(model_political_orientation, n = 10)
print(label_topics)

effect_political_orientation <- estimateEffect(1:20 ~ political_orientation, model_political_orientation, meta = stm_data$meta)
summary(effect_political_orientation)

# Reset graphical parameters
par(mfrow=c(1,1))

plot(model_political_orientation, type = "summary", n = 20)

# Calculate topic correlation
topic_correlation_political_orientation <- topicCorr(model_political_orientation)

# Plot topic correlation
plot(topic_correlation_political_orientation)

# Re-running for country instead of political orientation
# Fit the STM model
model_country <- stm(documents = stm_data$documents, vocab = stm_data$vocab, K = 20, prevalence = ~ country, data = stm_data$meta)

# Summary of the model
summary(model_country)

plot(model_country, type = "summary", n = 10)

# Estimate the effect of country on topic prevalence
effect_country <- estimateEffect(1:20 ~ country, model_country, meta = stm_data$meta)

# Summary of the effects
summary(effect_country)

# Plot the effect of country on a specific topic (e.g., Topic 1)
plot(effect_country, covariate = "country", topics = 5, model = model_country, method = "difference", 
     main = "Effect of Country on Topic 5 Prevalence - energy/climate/environment")

### DID NOT RUN
# Plot the effect of political orientation on all topics
par(mfrow = c(5, 4)) # Adjust layout to show multiple plots

for (i in 1:20) {
  plot(effect, covariate = "country", topics = i, model = model_country, method = "difference", 
       cov.value1 = "left", cov.value2 = "right", main = paste("Topic", i))
}
####

# Excluding topics that were not relevant and those that are country-specific
topics_to_exclude <- c(15, 3, 16, 12, 6, 4, 14, 19, 7, 20, 13)

# Subset the STM model to exclude specified topics
model_subset_political_orientation <- model_political_orientation[setdiff(1:K(model_political_orientation), topics_to_exclude)]

# Plot the effect of political orientation on remaining topics
par(mfrow = c(3, 4)) # Adjust layout to show remaining plots

for (i in 1:K(model_subset)) {
  plot(effect, covariate = "political_orientation", topics = i, model = model_subset_political_orientation, method = "difference", 
       cov.value1 = "Left", cov.value2 = "Right", main = paste("Topic", i))
}


# Generating summary for only the relevant topics

# Specify the topics of interest
topics_of_interest <- c(8, 11, 5, 17)

# Estimate the effects of political orientation on these topics
effect <- estimateEffect(topics_of_interest ~ political_orientation, model_political_orientation, meta = stm_data$meta)

# Extract summary statistics for the effects
summary_table <- summary(effect)

# Display the summary table
print(summary_table)


# Making a stargazer table for the topics of interest

install.packages("stargazer")

library(stargazer)

# Prepare data for stargazer
summary_df <- data.frame(
  Topic = rownames(summary_table$summary),
  summary_table$summary
)

print(summary_df)

# Remove rownames
rownames(summary_df) <- NULL

# Print summary table using stargazer
stargazer(summary_df, type = "text")
