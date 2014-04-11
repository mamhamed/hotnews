#setwd("~/workspace/R/wiki/wikiSrc")
library("DBI")
library("RSQLite")
#source("./wikiSrc/add_data2DB.R")

## constants and parameters
OBSERVATION_INTERVAL_IN_SECONDS = 48*3600
MIN_WIKI_ARTICLE_ACCESS_COUNT = 50

if (!exists("all_data"))
  all_data <- data.frame("Hamed","ll",100,0) 

## get all the files and process them

all_files <- list.files(path="/mnt/Data/wikiHourlyData/")
now <- floor(as.double(as.POSIXlt(Sys.time(),tz="GMT")))
# there is a bug that it generates many of a word. the following line is a work around

all_data <- all_data[-which(all_data$time < (now-OBSERVATION_INTERVAL_IN_SECONDS)),]


for (filename in all_files){
  #filename = "pagecounts-20140108-220000.gz"  #all_files[11]
  print(filename)
  
  ## get time information from file
  
  day <- as.integer(substr(filename,start=18,stop=19))
  mon <- as.integer(substr(filename,start=16,stop=17))
  year <- as.integer(substr(filename,start=12,stop=15))
  hour <- as.integer(substr(filename,start=21,stop=22))
  
  ## convert time to unix timestamp
  
  mydate <- paste(year, mon, day, sep="-")
  mytime <- paste(hour,":00:00 GMT",sep="")
  tt <- as.double(as.POSIXlt(paste(mydate,mytime)))  
  
  local_filename <- paste("/mnt/Data/wikiHourlyData/",filename,sep="")
  
  ## look back window size e.g. 48*3600 means 48 hours before
  
  if ( (now - tt) < OBSERVATION_INTERVAL_IN_SECONDS ){ #history
    ## make sure the data is not already loaded
    if ( length(which(all_data$time == tt)) == 0 ){
    
      ## load the data
      
      data <- tryCatch(
      {
        read.delim(gzfile(local_filename), sep=" ", header=FALSE, 
               skip=500000, nrows=1200000,
               colClasses=c('character','character','double','double'))
          }, error = function(e) {
            print(e)
            print("error in reading the access files")
            data <- data.frame("Hamed","ll",100,0) 
          }, finally = {
            print("error in reading the access files")
            data <- data.frame("Hamed","ll",100,0) 
          }
      )

      print("Done with loading the file into memory")
      
      ## remove page size
      
      data <- data[,-4]
      
      ## extract en webpages that have atleast 500 hit/hour
      
      endata <- data[which(data[,1]=="en"),]
      x <- endata[which(endata[,3] > MIN_WIKI_ARTICLE_ACCESS_COUNT),-1]
      
      ## if there are some page
      
      if (dim(x)[1]*dim(x)[2] != 0){
        x <- data.frame(word=as.character(x[,1]),count=x[,2],time=tt)
        
        ## Add data to the DB
        
        #add_data2DB(x)
        
        ## append data to the memory
        if (!exists("all_data")){
          all_data <- x  
        }else{
          all_data <- rbind(all_data,x)
        }
      }
      
    }#hour if
  
  }#history if
}

## creating the database
if (!file.exists("wikiData.db")){
    print("data db does not exist, creating...")
}
db <- dbConnect(SQLite(), dbname="wikiData.db")

status <- dbWriteTable(conn = db, append = TRUE, name = "PAGEACCESS",
                       row.names = FALSE,
                       value = data.frame(word = all_data$word, 
                                          count = all_data$count, 
                                          time = all_data$time) )

#pendingResults = dbListResults(db)
#if (length(pendingResults) > 0)
#    dbClearResult(pendingResults[[1]])


## remove old data no longer in observation interval

dbSendQuery(conn = db, 
            paste("DELETE FROM PAGEACCESS WHERE time <",  
            (now - OBSERVATION_INTERVAL_IN_SECONDS), sep="" ))

pendingResults = dbListResults(db)
if (length(pendingResults) > 0)
    dbClearResult(pendingResults[[1]])

dbDisconnect(conn=db)
