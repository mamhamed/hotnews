library("DBI")
library("RSQLite")

if (!exists("all_data"))
  all_data <- data.frame("Hamed","ll",100,0) 

## get all the files and process them

all_files <- list.files(path=path.page.access.data)
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
  
  local_filename <- paste(path.page.access.data,filename,sep="")
  
  ## look back window size e.g. 48*3600 means 48 hours before
  
  if ( (now - tt) < OBSERVATION_INTERVAL_IN_SECONDS ){ #history
    ## make sure the data is not already loaded
    if ( length(which(all_data$time == tt)) == 0 ){
    
      ## load the data
      cat(paste("loading ", local_filename, " ...\n"))
      
      ##### read file
      #f <- gzfile(local_filename)
      data <- read.delim(gzfile(local_filename), sep=" ", 
                       colClasses=c('character','character','double','double'))
      #close(f)
      #data <- as.data.frame(data_tmp)
      #rm("data_tmp")
      
      print("Done with loading the file into memory")
      
      ## remove page size
      data <- data[,-4]
      data <- data[data[,1]=="en",]
      
      ## extract en webpages that have atleast 500 hit/hour
      data <- data[which(data[,3] > MIN_WIKI_ARTICLE_ACCESS_COUNT),-1]
      
      ## if there are some page
      
      if (dim(data)[1]*dim(data)[2] != 0){
        data <- data.frame(word=as.character(data[,1]),count=data[,2],time=tt)
        
        ## Add data to the DB
        
        #add_data2DB(x)
        
        ## append data to the memory
        if (!exists("all_data")){
          all_data <- data  
        }else{
          all_data <- rbind(all_data,data)
        }
      }
      
    }#hour if
  
  }#history if
}

rm("data")

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
print("[wikiData.db] remove old data no longer in observation interval")
dbSendQuery(conn = db, 
            paste("DELETE FROM PAGEACCESS WHERE time <",  
            (now - OBSERVATION_INTERVAL_IN_SECONDS), sep="" ))

pendingResults = dbListResults(db)
if (length(pendingResults) > 0)
    dbClearResult(pendingResults[[1]])

dbDisconnect(conn=db)
