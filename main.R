#Sys.sleep(600)

while(TRUE){
  source("./wikiSrc/download_index_html.R")
  source("./wikiSrc/loadData_hour.R")
  source("./wikiSrc/trend.R") 
  print("finding news ...")
  source("./wikiSrc/wikiGetNews.R")
  print("current time is ")
  print(as.POSIXlt(Sys.time(),tz="GMT"))
  now <- floor(as.double(as.POSIXlt(Sys.time(),tz="GMT"))) 
  time_to_sleep <- floor((now + 3600)/3600)*3600+900 - now
  print("sleeping for next hour...")
  print(time_to_sleep)
  Sys.sleep(time_to_sleep)
}
