#setwd("~/workspace/R/wiki/wikiSrc")

## constants and parameters

last_hour <- all_data[all_data$time == max(all_data$time),]

last_hour <- last_hour[which(last_hour$count > MIN_LAST_HOUR_ACCESS_COUNT),]

new_hot_stories <- data.frame(word="toBeRemoved", count=1, 
                              timestamp=0, mean=0, std=0)

for (word in last_hour$word){
  
  word_info <- all_data[all_data$word == word,]
  
  #sorting
  
  word_info <- word_info[order(word_info$time, decreasing = TRUE),]
  
  
  word_count = word_info$count
  
    if (length(word_count) > 18){
    m=mean(word_count[-(1:6)])
    s=sqrt(var(word_count[-(1:6)]))
    #print(paste(word,word_count[1],m,s,sep="  "))
    if (is.na(s)){
      s = Inf
    }
    #print(word)
    if ( word_count[1] > (m+SD_MULTIPLE_FACTOR*s)){
      print(paste(word,word_count[1],m,s,sep="  "))
      
      result <- paste(word,word_count[1],word_info$time[1],m,s,sep="\t")
      write(result,"result.txt", append=TRUE)
      new_hot_stories = rbind(new_hot_stories,
                              data.frame(word=word, count=word_count[1], 
                                         timestamp=word_info$time[1], 
                                         mean=m, std=s) )
      #plot(word_count, xlab=word, type="l")
    }
  }
}
write("\n","result.txt", append=TRUE)

## write new hot stories to database
if (!file.exists(paste(path.wiki.result.db,"wikiResult.db",sep=""))){
    print("result db does not exist, creating...")
}
dbResult <- dbConnect(SQLite(), dbname=paste(path.wiki.result.db,"wikiResult.db",sep=""))

status <- dbWriteTable(conn = dbResult, append = TRUE, name = "HOTSTORIES",
                       row.names = FALSE,
                       value = new_hot_stories[-which(new_hot_stories$word=="toBeRemoved"),])

pendingHotStories = dbListResults(dbResult)

#if (length(pendingHotStories) > 0)
#    dbClearResult(pendingHotStories[[1]])

dbDisconnect(conn=dbResult)
