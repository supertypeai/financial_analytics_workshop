#caninstall.packages(c("httr", "jsonlite", "tidyverse", "gganimate"))

library(httr)
library(jsonlite)
library(dplyr)
library(ggplot2)
library(gganimate)
library(scales)
library(tidyr)

# Read API key
readRenviron(".env")
api_key = Sys.getenv("api_key")

# Import Custom Theme
custom_theme <- theme(
  axis.line=element_blank(),
  axis.text.x=element_text(color="white",size=10),  # Set x-axis labels to white
  axis.text.y=element_text(color="white",size=10),
  axis.ticks=element_blank(),
  axis.text = element_text(color="white",size=6),
  axis.title.x=element_text(color="white",size=15),
  axis.title.y=element_text(color="white",size=15),
  panel.background=element_rect(fill="black"), # Black background
  panel.border=element_blank(),
  panel.grid.major=element_blank(),
  panel.grid.minor=element_blank(),
  panel.grid.major.x = element_line( size=.1, color="grey" ),
  panel.grid.minor.x = element_line( size=.1, color="grey" ),
  plot.title=element_text(size=25, hjust=0.5, face="bold", colour="white", vjust=-1.5, margin=margin(t=2, unit="line")),
  plot.subtitle=element_text(size=18, hjust=0.5, vjust=0,face="italic", color="grey"),
  plot.caption =element_text(size=12, hjust=0.5, face="italic", color="grey"),
  plot.margin = margin(1,1, 1, 1, "cm"),
  plot.background=element_rect(fill="black"),
  legend.background = element_rect(fill = "black"),
  legend.text = element_text(color='white',size=15),
  legend.title = element_text(color='white',size=18),
  legend.key.size = unit(1.5, "lines"),
  legend.key = element_rect(fill="black")
)

# Value Investing Part

## Data fetching
fetch_company_valuation_data <- function(stock_list){
  df_finance <- data.frame()
  
  for (i in stock_list) {
    # Replace the URL with a URL from the Available Endpoints section
    url <- paste0("https://api.sectors.app/v1/company/report/", i, "/?sections=valuation")
    
    headers <- c(Authorization = api_key)
    
    response <- GET(url, add_headers(headers))
    
    if (status_code(response) == 200) {
      df <- fromJSON(content(response, "text", encoding="utf-8"),flatten=TRUE)
      df <- df$valuation$historical_valuation
      df$symbol <- i
      
      df_finance <- rbind(df_finance,df)
    } else {
      # Handle error
      cat("Error:", status_code(response), "\n")
      next
    }
  }
  return(df_finance)
}

## Data Cleansing

finance_data_cleansing <- function(df_finance){
  # Get the subsector pe and pbv value from result dataframe as subsec
  subsec <- df_finance %>%
    select(c("year","pb_peer_avg","pe_peer_avg")) %>%
    distinct(year,pb_peer_avg,pe_peer_avg) %>%
    mutate("symbol" = "Banks (Sectors Average)") %>%
    rename(pb=pb_peer_avg, pe = pe_peer_avg) %>%
    select(c(symbol,year,pe,pb))
  
  # Merge (row bind) the data for sub-sector financials data into ticker data and select only "symbol","year","pe", and "pb" columns
  df <- rbind(subsec,df_finance %>% select(symbol,year,pe,pb))
  
  return(df)
}

# Dividend Investing Strategy

## Data Fetching
fetch_company_dividend_data <- function(stock_list) {
  
  df_div <- data.frame()
  
  for (i in stock_list) {
    # Replace the URL with a URL from the Available Endpoints section
    url <- paste0("https://api.sectors.app/v1/company/report/", i, "/?sections=dividend")
    
    headers <- c(Authorization = api_key)
    
    response <- GET(url, add_headers(headers))
    
    if (status_code(response) == 200) {
      df <- fromJSON(content(response, "text", encoding="utf-8"),flatten=TRUE)
      df <- df$dividend$historical_dividends
      df$symbol <- i
      
      df <- df %>% select(symbol,year,total_dividend)
      
      df_div <- rbind(df_div,df)
    } else {
      # Handle error
      cat("Error:", status_code(response), "\n")
      next
    }
  }
  
  return(df_div)
}

## Data Cleansing & Processing
dividend_data_cleansing <- function(df_div){
  df_div <- df_div %>%
    group_by(symbol) %>%
    mutate(shifted_value = lag(total_dividend)) %>% 
    mutate(percentage_growth = round(((total_dividend-shifted_value)/shifted_value)*100,2)) %>% 
    drop_na()
  
  return(df_div)
}

