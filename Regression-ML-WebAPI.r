# importing packages
library(httr)
library(xml2) 
library(readr) 
library(rjson) 
library(tidyverse)
library(caret)
library(leaps)
library(caTools) 
library(quickpsy) 

#Check if the GridDb cluster is accessible via secure Web API   
# base_url = "https://cloud1.griddb.com/trialxxxx/griddb/v2/gs_clustertrialxxxx/dbs/pratik" , i.e. https://[host]/griddb/v2/[clustername]/dbs/[databasename] 

my_base_url =  "https://cloud1.griddb.com/trial1602/griddb/v2/gs_clustertrial1602/dbs/r_blog" 
r <- GET(
	url = "https://cloud1.griddb.com/trial1602/griddb/v2/gs_clustertrial1602/dbs/r_blog/checkConnection" , 
   add_headers("Content-Type" = "application/json; charset=UTF-8" ) ,      
    config = authenticate("pratik", "pratik"), 
    encode = "json" 
  )
print(r) 

#Construct a data object to hold the request body (i.e., the container that needs to be created)  

my_data_obj = '{   	"container_name":"HCC_Data"  ,  	"container_type":"COLLECTION" ,    	"rowkey": false,    "columns": [  
{ { "name": "Gender"  ,"type": "FLOAT" },{ "name": "Symptoms"  ,"type": "FLOAT" },  { "name": "Alcohol"  ,"type": "FLOAT" },
  { "name": "Hepatitis B Surface Antigen"  ,"type": "FLOAT" },{ "name": "Hepatitis B e Antigen"  ,"type": "FLOAT" },{ "name": "Hepatitis B Core Antibody"  ,"type": "FLOAT" },{ "name": "Hepatitis C Virus Antibody"  ,"type": "FLOAT" },
  { "name": "Smoking"  ,"type": "FLOAT" },{ "name": "Diabetes"  ,"type": "FLOAT" }, { "name": "Obesity"  ,"type": "FLOAT" },{ "name": "Hemochromatosis"  ,"type": "FLOAT" }, { "name": "Arterial Hypertension"  ,"type": "FLOAT" },{ "name": "Chronic Renal Insufficiency"  ,"type": "FLOAT" },{ "name": "Nonalcoholic Steatohepatitis"  ,"type": "FLOAT" }, { "name": "Esophageal Varices"  ,"type": "FLOAT" },{ "name": "Splenomegaly"  ,"type": "FLOAT" },{ "name": "Liver Metastasis"  ,"type": "FLOAT" },  { "name": "Age at diagnosis"  ,"type": "FLOAT" },{ "name": "Packs of cigarets per year"  ,"type": "FLOAT" },{ "name": "Performance Status"  ,"type": "FLOAT" },
  { "name": "Encefalopathy	degree"  ,"type": "FLOAT" },{ "name": "Ascites degree"  ,"type": "FLOAT" }, { "name": "International Normalised Ratio"  ,"type": "FLOAT" },{ "name": "Alpha-Fetoprotein"  ,"type": "FLOAT" },
  { "name": "Haemoglobin"  ,"type": "FLOAT" },{ "name": "Mean Corpuscular Volume"  ,"type": "FLOAT" }, { "name": "Leukocytes"  ,"type": "FLOAT" },{ "name": "Platelets"  ,"type": "FLOAT" },
  { "name": "Albumin"  ,"type": "FLOAT" },{ "name": "Total Bilirubin"  ,"type": "FLOAT" }, { "name": "Alanine transaminase"  ,"type": "FLOAT" },{ "name": "Alkaline phosphatase"  ,"type": "FLOAT" }, { "name": "Total Proteins"  ,"type": "FLOAT" },{ "name": "Creatinine"  ,"type": "FLOAT" }, { "name": "Number of Nodules"  ,"type": "FLOAT" },{ "name": "Direct Bilirubin"  ,"type": "FLOAT" }, { "name": "Iron"  ,"type": "FLOAT" },{ "name": "Oxygen Saturation"  ,"type": "FLOAT" }, { "name": "Ferritin"  ,"type": "FLOAT" },{ "name": "Class"  ,"type": "FLOAT" }, { "name": "Alive"  ,"type": "FLOAT" } }  ] 
  }
  
#Set up the GridDB WebAPI URL
container_url = "https://cloud1.griddb.com/trial1602/griddb/v2/gs_clustertrial1602/dbs/r_blog/containers/"
#Lets now invoke the POST request via GridDB WebAPI with the headers and the request body 
 r <- POST(container_url, 
       add_headers("Content-Type" = "application/json; charset=UTF-8" ) ,      
       config = authenticate("pratik", "pratik"), 
       encode = "json", 
       body= my_data_obj) 
	  
# Populate the container with rows from JSON or CSV 
hcc_data_JSON <- fromJSON(hcc_data.json) 
 

insert_url = "https://cloud1.griddb.com/trial1602/griddb/v2/gs_clustertrial1602/dbs/r_blog/containers/HCC_Data/rows/"  
r <- PUT(insert_url, add_headers("Content-Type" = "application/json; charset=UTF-8" ) , config = authenticate("pratik", "pratik"), encode = "json" , body=hcc_data_JSON ) 

#To check if all rows have been inserted
print(str(json.loads(r.text)['count']) + ' rows have been registered in the container HCC_Data.') 

#Fetch(Query) Only 2 columns are of interest, Alive( i.e. years alive after HCC) and Packs_of_cigarets_per_year (Packs of cigarretes per year) . 
my_sql_query1 = '(f"""SELECT Packs_of_cigarets_per_year, Alive FROM HCC_Data """) '

#To retieve data from a GridDB container, the GridDB Web API Query URL must be suffied with "/sql" 
my_query_url = "https://cloud1.griddb.com/trial1602/griddb/v2/gs_clustertrial1602/dbs/r_blog/sql"

#Construct the request body 
query_request_body = '[ {"type" : "sql-select", "stmt" : "SELECT Packs_of_cigarets_per_year, Alive FROM HCC_Data" }]' 

# print(query_request_body ) 
#Invoke the GridDB WebAPI request 
dataset <- POST ( my_query_url, 
       add_headers("Content-Type" = "application/json" ) ,      
       config = authenticate("pratik", "pratik"), 
       body = query_request_body 
       ) 
                             
#The data returned is now in dataset variable. 

# Simple Linear Regression 
# Splitting the dataset into the, Training_set and Test_set 
split = sample.split(dataset$Packs_of_cigarets_per_year, SplitRatio = 0.7) 
trainingset = subset(dataset, split == TRUE) 
testset = subset(dataset, split == FALSE) 

# Fitting Simple Linear Regression, to the Training set 
lm.r = lm(formula = Packs_of_cigarets_per_year~Alive, data = trainingset) 
# Just print the coefficient calculated, just to be sure that holds a logical value 
coef(lm.r) 
  
# Predicting the Test set results his lifestyle. 
# "ypred" function calculates the predicted probabilities at the values of the explanatory(independent) variable.
ypred = predict(lm.r, newdata = testset) 
#Now, the data frame testset has the predicted values of life expectancy OR Alive(how long can one expect to stay alive based on post HCC treatment lifestyle. 

#Lets visualize the results. 
trainingsetdf = data.frame( trainingset) 

# Visualising the Training set results  
x <- trainingsetdf$Packs_of_cigarets_per_year 
y <- trainingsetdf$Alive 
plot(x, y, main="Alive vs Packs_of_cigarets_per_year (Training set)", xlab="Packs Cigs", ylab="Alive")

# Next, based on the training , let the algorithm now predict the life expectancy in years. 
x <- testset$Packs_of_cigarets_per_year 
y <- testset$Alive 
plot(x, y, main="Predicted - Alive vs Packs_of_cigarets_per_year ", xlab="Packs Cigs", ylab="Alive") 

	