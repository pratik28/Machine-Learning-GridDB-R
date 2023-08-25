# importing packages
library(httr)
library(xml2) 
library(readr) 
#library(rjson) 
library(jsonlite) 
library(tidyverse)
#library(caret)
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

my_data_obj = '{   	"container_name":"HCC_Data4"  ,  	"container_type":"COLLECTION" ,    	"rowkey": false,    "columns": [  { "name": "Gender"  ,"type": "FLOAT" },{ "name": "Symptoms"  ,"type": "FLOAT" },  { "name": "Alcohol"  ,"type": "FLOAT" }, { "name": "Hepatitis_B_Surface_Antigen"  ,"type": "FLOAT" },{ "name": "Hepatitis_B_e_Antigen"  ,"type": "FLOAT" },{ "name": "Hepatitis_B_Core_Antibody"  ,"type": "FLOAT" },{ "name": "Hepatitis_C_Virus_Antibody"  ,"type": "FLOAT" }, { "name": "Smoking"  ,"type": "FLOAT" },{ "name": "Diabetes"  ,"type": "FLOAT" }, { "name": "Obesity"  ,"type": "FLOAT" },{ "name": "Hemochromatosis"  ,"type": "FLOAT" }, { "name": "Arterial_Hypertension"  ,"type": "FLOAT" },{ "name": "Chronic_Renal_Insufficiency"  ,"type": "FLOAT" },{ "name": "Nonalcoholic_Steatohepatitis"  ,"type": "FLOAT" }, { "name": "Esophageal_Varices"  ,"type": "FLOAT" },{ "name": "Splenomegaly"  ,"type": "FLOAT" },{ "name": "Liver_Metastasis"  ,"type": "FLOAT" },  { "name": "Age_at_diagnosis"  ,"type": "FLOAT" },{ "name": "Packs_of_cigarets_per_year"  ,"type": "FLOAT" },{ "name": "Performance_Status" ,"type": "FLOAT" },   { "name": "Encefalopathy_degree"  ,"type": "FLOAT" },{ "name": "Ascites_degree"  ,"type": "FLOAT" }, { "name": "International_Normalised_Ratio"  ,"type": "FLOAT" },{ "name": "Alpha_Fetoprotein"  ,"type": "FLOAT" },   {"name": "Haemoglobin"  ,"type": "FLOAT" },{ "name": "Mean_Corpuscular_Volume"  ,"type": "FLOAT" }, { "name": "Leukocytes"  ,"type": "FLOAT" },{ "name": "Platelets"  ,"type": "FLOAT" },   { "name": "Albumin"  ,"type": "FLOAT" },{ "name": "Total_Bilirubin"  ,"type": "FLOAT" }, { "name": "Alanine_transaminase"  ,"type": "FLOAT" },{ "name": "Alkaline_phosphatase"  ,"type": "FLOAT" }, { "name": "Total_Proteins"  ,"type": "FLOAT" },{ "name": "Creatinine"  ,"type": "FLOAT" }, { "name": "Number_of_Nodules"  ,"type": "FLOAT" },{ "name": "Direct_Bilirubin"  ,"type": "FLOAT" }, { "name": "Iron"  ,"type": "FLOAT" },{ "name": "Oxygen_Saturation"  ,"type": "FLOAT" }, { "name": "Ferritin"  ,"type": "FLOAT" },{ "name": "Class"  ,"type": "FLOAT" }, { "name": "Alive"  ,"type": "FLOAT" }   ]    } ' 
  
#Set up the GridDB WebAPI URL
container_url = "https://cloud1.griddb.com/trial1602/griddb/v2/gs_clustertrial1602/dbs/r_blog/containers"
#Lets now invoke the POST request via GridDB WebAPI with the headers and the request body 
 r <- POST(container_url, 
       add_headers("Content-Type" = "application/json; charset=UTF-8" ) ,      
       config = authenticate("pratik", "pratik"), 
       encode = "json", 
       body= my_data_obj) 

print("After container create")	  
# Populate the container with rows from JSON or CSV 
HCC_Data4_JSON <- fromJSON("../data/hcc_data.json") 
#print(HCC_Data3_JSON) 

insert_url = "https://cloud1.griddb.com/trial1602/griddb/v2/gs_clustertrial1602/dbs/r_blog/containers/HCC_Data4/rows/"  
r <- PUT(insert_url, 
         add_headers("Content-Type" = "application/json; charset=UTF-8" ) , 
		 config = authenticate("pratik", "pratik"), 
		 encode = "json" ,
		 body=HCC_Data4_JSON ) 

#To check if all rows have been inserted  
#print(r) 
print("Rows inserted")	  
#Fetch(Query) Only 2 columns are of interest, Alive( i.e. years alive after HCC) and Packs_of_cigarets_per_year (Packs of cigarretes per year) . 
my_sql_query1 = "SELECT Packs_of_cigarets_per_year, Alive FROM HCC_Data4 " 

#To retieve data from a GridDB container, the GridDB Web API Query URL must be suffied with "/sql" 
my_query_url = "https://cloud1.griddb.com/trial1602/griddb/v2/gs_clustertrial1602/dbs/r_blog/sql"

#Construct the request body  

query_request_body = ' [{"type":"sql-select" , "stmt":"SELECT Packs_of_cigarets_per_year, Alive FROM HCC_Data4" }] '

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

	
