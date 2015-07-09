#!/usr/bin/Rscript

source('setup.R')

while(TRUE){
  source("download_index_html.R")
  source("loadData_hour.R")
  source("trend.R") 
  print("finding news ...")
  source("wikiGetNews.R")
  print("current time is ")
  print(as.POSIXlt(Sys.time(),tz="GMT"))
  now <- floor(as.double(as.POSIXlt(Sys.time(),tz="GMT"))) 
  time_to_sleep <- floor((now + 3600)/3600)*3600+900 - now
  print("sleeping for next hour...")
  print(time_to_sleep)
  Sys.sleep(time_to_sleep)
}
