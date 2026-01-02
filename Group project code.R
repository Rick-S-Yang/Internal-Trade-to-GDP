################################### Creating the Internal_trade/Gdp table ##############################


#install.packages("dplyr")          take of the # if hasnt installed hese packages
#install.packages("stargazer") 
#install.packages("ggrepel")
#install.packages("knitr")
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(readxl)
library(stargazer)
library(ggplot2)
library(knitr)
library(ggrepel)



##1. setting the years and read gdp data
years <- c("2014")
gdp_data <- read_csv("C:/Users/Shuai/Desktop/ECON 325 & 326/ECON 326/Coding/Rick's ECON 326 Project/Faiz's transfer/GDP.csv", show_col_types = FALSE, skip=4)


##2. define some constants for WIOT layout
COUNTRY_COL <- 3 
COUNTRY_ROW <- 3

DATA_START_ROW  <- 5
DATA_START_COL  <- 5
gdp_data


##3. function to pompute internal trade for a given year
internal_trade <- function(year) {
  file_path <- paste("WIOT", year, "_Nov16_ROW_add.csv",sep="")
  raw_df <- read_csv(file_path, col_names = FALSE, show_col_types = FALSE)
  countries_row <- raw_df[[COUNTRY_COL]][DATA_START_ROW:nrow(raw_df)] |> as.character()
  countries_column <- raw_df[[COUNTRY_ROW]][DATA_START_COL:ncol(raw_df)] |> as.vector() |> as.character()
  matrix <- as.matrix(raw_df[DATA_START_ROW:nrow(raw_df), DATA_START_COL:ncol(raw_df)])
  storage.mode(matrix) <- "numeric"
  matrix[is.na(matrix)] <- 0
  countries <- intersect(unique(countries_row), unique(countries_column))
  sum_same_countries <- vapply(countries, function(cty) {
    rows <- countries_row == cty
    cols <- countries_column == cty
    if(!any(rows) || !any(cols)) {
      return(0)
    }
    sum(matrix[rows, cols, drop = FALSE], na.rm = TRUE)
  }, 
  numeric(1))
  result <- data.frame(country = countries, sum_value = as.numeric(sum_same_countries))
  return(result)
}


##4. loop over years and compute IT/GDP
results <- data.frame(matrix(ncol=3,nrow=0))
colnames(results) <- c("country","year","it_gdp")
for(year in years) {
  it <- internal_trade(year)
  year_results <- list()
  gdp_country <- gdp_data[["Country Code"]]
  for(country in it[["country"]]) {
    if(country %in% gdp_country) {    
      gdp_index <- which(gdp_country == country)
      it_index <- which(it[["country"]] == country)
      it_gdp <- (it$sum_value[[it_index]] * 1000000) / gdp_data[[year]][[gdp_index]]
      results[nrow(results)+1,] = c(country,year,it_gdp)
    }
  }
}
results


##5. quick summay it/gdp

summary(as.numeric(results$it_gdp))

# Or a custom summary with only the stats you need
c(
  mean = mean(as.numeric(results$it_gdp), na.rm = TRUE),
  sd = sd(as.numeric(results$it_gdp), na.rm = TRUE),
  min = min(as.numeric(results$it_gdp), na.rm = TRUE),
  max = max(as.numeric(results$it_gdp), na.rm = TRUE)
)



##6. full descriptive stats + formatted table
my_stats <- c(
  mean = mean(as.numeric(results$it_gdp), na.rm = TRUE),
  sd = sd(as.numeric(results$it_gdp), na.rm = TRUE),
  min = min(as.numeric(results$it_gdp), na.rm = TRUE),
  Q1 = quantile(as.numeric(results$it_gdp), 0.25, na.rm = TRUE),
  median = median(as.numeric(results$it_gdp), na.rm = TRUE),
  Q3 = quantile(as.numeric(results$it_gdp), 0.75, na.rm = TRUE),
  max = max(as.numeric(results$it_gdp), na.rm = TRUE)
)

kable(as.data.frame(t(my_stats)), caption = "Summary statistics for it/gdp")


##7. rebuilding the matrix

matrix <- as.matrix(raw_df[DATA_START_ROW:nrow(raw_df), DATA_START_COL:ncol(raw_df)])
storage.mode(matrix) <- "numeric"
matrix[is.na(matrix)] <- 0


result















################ Merging all dependent and independent variables into one table for regression########


options(scipen = 999)

##1. Define country codes##
country_codes<-c(  "AUS","AUT","BEL","BGR","BRA","CAN","CHE","CHN","CYP","CZE",
                   "DEU","DNK","ESP","EST","FIN","FRA","GBR","GRC","HRV","HUN",
                   "IDN","IND","IRL","ITA","JPN","KOR","LTU","LUX","LVA","MEX",
                   "MLT","NLD","NOR","POL","PRT","ROU","RUS","SVK","SVN","SWE",
                   "TUR","USA")

##2. select the rai number for 2014 for the countries above##
rai_raw<-read_excel("C:/Users/Shuai/Desktop/ECON 325 & 326/ECON 326/Coding/Rick's ECON 326 Project/Data Downloaded/RAI.xlsx")


rai_2014<-rai_raw %>%
  filter(abbr_country %in% country_codes, year==2014) %>%
  select(Codes=abbr_country, RAI=n_RAI)



##3. select  the population for 2014 for the countries above##

pop_raw<-read_excel("C:/Users/Shuai/Desktop/ECON 325 & 326/ECON 326/Coding/Rick's ECON 326 Project/Data Downloaded/Population.xlsx", skip=3) 

pop_2014<-pop_raw %>%
  filter(`Country Code` %in% country_codes) %>%
  select(Codes=`Country Code`,Population=`2014`)




##4.select the gdp per capita for 2014 for the countries above##

gdppc_raw<-read_excel("C:/Users/Shuai/Desktop/ECON 325 & 326/ECON 326/Coding/Rick's ECON 326 Project/Data Downloaded/GDP per capita.xlsx", skip=3)

gdppc2014<-gdppc_raw %>%
  filter(`Country Code` %in% country_codes) %>%
  select(Codes=`Country Code`,`GDP per Capita` =`2014`)



##5.select the land area for 2014 for the country above##

land_raw<-read_excel("C:/Users/Shuai/Desktop/ECON 325 & 326/ECON 326/Coding/Rick's ECON 326 Project/Data Downloaded/Land Mass Data.xlsx",skip=4)

land_2014<-land_raw %>%
  filter(`Country Code` %in% country_codes) %>%
  select(Codes=`Country Code`,Land=`2014`)


##6. select the internal trade share per gdp##

itgdp_raw<-read.csv("C:/Users/Shuai/Desktop/ECON 325 & 326/ECON 326/Coding/Rick's ECON 326 Project/Data Downloaded/internal_trade.csv")

itgdp_2014 <- itgdp_raw %>%
  filter(country %in% country_codes) %>%
  select(Codes=country, `IT_per_GDP` = it_gdp)


##7. merge all selected columns into one table##

dataframe_for_regression <-itgdp_2014 %>%
  left_join(rai_2014, by="Codes")%>%
  left_join(pop_2014, by="Codes")%>%
  left_join(gdppc2014, by="Codes")%>%
  left_join(land_2014, by="Codes")



print(dataframe_for_regression)


















##########################Run the baseline model regression################################

##the regression e are running: InternalTradei=𝛽o +𝛽1RAIi+𝛽2GDPpci+𝛽3Popi+𝛽4Landi+ 𝜀i 



##1. run the baseline regression and demonstrate the results in a table

merged_table <- as.data.frame(dataframe_for_regression)
colnames(merged_table)    
head(merged_table)
model <- lm(IT_per_GDP~ RAI + Population + `GDP per Capita`+ Land, data=merged_table)
summary(model)
stargazer(model,
          type = "text",
          title = "Regression Results",
          dep.var.labels = "IT_per_GDP",
          covariate.labels = c("RAI", "Population", "GDP per Capita", "Land"),
          digits = 3)



##2. generate the plot for the baseline regression 

ggplot(merged_table, aes(x = RAI, y = IT_per_GDP)) +
  geom_point(size = 1.5, alpha = 0.85) +
  geom_smooth(method = "lm", se = FALSE, color = "steelblue", linewidth = 1) +
  
  geom_text_repel(
    aes(label = Codes),
    size = 3,
    family = "Times",
    max.overlaps = Inf,
    box.padding = 0.15,     
    point.padding = 0.05,   
    segment.color = "grey70",
    min.segment.length = 0  
  ) +
  
  labs(
    title = "Internal Trade vs. Regional Authority (2014)",
    x = "Regional Authority Index (RAI)",
    y = "Internal Trade as % of GDP"
  ) +
  
  theme_minimal(base_family = "Times") +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12),
    panel.grid.major = element_line(color = "grey85"),
    panel.grid.minor = element_blank()
  )


##3. scaling variables and running final stepwise regression for the baseline model

merged_table <- merged_table %>%
  rename(GDP_per_Capita = `GDP per Capita`)

merged_table_2 <- merged_table %>%
  mutate(
    Population   = Population / 1000000,
    Land         = Land / 1000000,
    GDP_per_Capita = GDP_per_Capita / 10000
  )

model <- lm(IT_per_GDP~ RAI + Population + GDP_per_Capita + Land, data=merged_table_2)
stargazer(model,
          type = "text",
          title = "Regression Results",
          dep.var.labels = "IT_per_GDP",
          covariate.labels = c("RAI", "Population", "GDP per Capita", "Land"),
          digits = 3)
m1 <- lm(IT_per_GDP ~ RAI, data = merged_table_2)
m2 <- lm(IT_per_GDP ~ RAI + Population, data = merged_table_2)
m3 <- lm(IT_per_GDP ~ RAI + Population + GDP_per_Capita,
         data = merged_table_2)
m4 <- lm(IT_per_GDP ~ RAI + Population + GDP_per_Capita + Land,
         data = merged_table_2)

stargazer(m1, m2, m3, m4,
          type = "text",                
          title = "Regression Results",
          dep.var.labels = "IT_per_GDP",
          covariate.labels = c("RAI", "Population",
                               "GDP per Capita", "Land"),
          digits = 3)



















########################### Specification check ###########################################

#New model for specification check: InternalTradei=𝛽o +𝛽1RAIi+𝛽2GDPpci+𝛽3(GDPpci^)2+𝛽4Popi+𝛽5Landi+𝜀i 


## 1. Create squared GDP per capita and scale variables ----

scaled_df <- dataframe_for_regression %>%
  mutate(
    Population       = Population / 1000000,          
    Land             = Land / 1000000,                
    `GDP per Capita` = `GDP per Capita` / 10000     
  ) %>%
  mutate(
    GDPpc2 = (`GDP per Capita`)^2                 
  )


## 2. Full specification with GDPpc2 ----

model_spec2 <- lm(
  IT_per_GDP ~ RAI + `GDP per Capita` + GDPpc2 + Population + Land,
  data = scaled_df
)
summary(model_spec2)


## 3. Stepwise models ----

m1 <- lm(IT_per_GDP ~ RAI, data = scaled_df)

m2 <- lm(IT_per_GDP ~ RAI + Population, data = scaled_df)

m3 <- lm(
  IT_per_GDP ~ RAI + Population + `GDP per Capita`,
  data = scaled_df
)

m4 <- lm(
  IT_per_GDP ~ RAI + Population + `GDP per Capita` + Land,
  data = scaled_df
)

m5 <- lm(
  IT_per_GDP ~ RAI + `GDP per Capita` + GDPpc2 + Population + Land,
  data = scaled_df
)

## 4. Stargazer table (safe version – no custom labels) ----

stargazer(m1, m2, m3, m4, m5,
          type = "text",
          title = "Regression Results with GDP per Capita Squared",
          dep.var.labels = "IT_per_GDP",
          digits = 3)

















#################### Robustness check ###############################################

##here we remove the outlier of Australia, US, Canada for every category


##1. scaling all variables in tables
merged_table <- as.data.frame(dataframe_for_regression)

merged_filtered <- merged_table %>%
  filter(!Codes %in% c("AUS", "CAN", "USA"))

scaled_merged_filtered <- merged_filtered %>%
  mutate(
    Population       = Population / 1000000,         
    Land             = Land / 1000000,                
    `GDP per Capita` = `GDP per Capita` / 10000    
    
  ) 


##2. stepwise regression restuls in table being performed here

m1 <- lm(IT_per_GDP ~ RAI, data = scaled_merged_filtered)

m2 <- lm(IT_per_GDP ~ RAI + Population, data = scaled_merged_filtered)

m3 <- lm(IT_per_GDP ~ RAI + Population + `GDP per Capita`,
         data = scaled_merged_filtered)

m4 <- lm(IT_per_GDP ~ RAI + Population + `GDP per Capita` + Land,
         data = scaled_merged_filtered)

stargazer(m1, m2, m3, m4, scientific = FALSE,
          options(scipen = 999),
          type = "text",   
          title = "Regression Results (Stepwise, Excluding AUS, CAN, USA)",
          dep.var.labels = "IT_per_GDP",
          column.labels = c("m1", "m2", "m3", "m4"),
          column.separate = c(1, 1, 1, 1),
          covariate.labels = c("RAI", "Population", "GDP per Capita", "Land"),
          
          digits = 3,
          header = FALSE)

