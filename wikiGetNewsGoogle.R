source('ExtractRelatedNews.R')
source('getNewsCategory.R')

library('rjson')
library("RSQLite")
require("XML")
library('RCurl')

db_wikiResult <- dbConnect(SQLite(), dbname=paste(path.wiki.result.db,"wikiResult.db",sep=""))

tryCatch({
  res <- dbSendQuery(conn = db_wikiResult, 
                     "select * from hotstories where timestamp=(select timestamp from hotstories order by timestamp DESC limit 1)" )
  
  allwords <- fetch(res,n=-1)
  
  tmp <- data.frame(allwords$word)
  
  dbDisconnect(conn=db_wikiResult)
  
  if (!file.exists(paste(path.wiki.result.db,"wikiNews.db",sep=""))){
    print("result db does not exist, creating...")
  }
  db_news <- dbConnect(SQLite(), dbname=paste(path.wiki.news.db,"wikiNews.db",sep=""))
  
  print("wikiNews.db is open...")
  for (words in unique(allwords$word)){
    mywords <- gsub(pattern="\u2012|\u2013|\u2014|\u2015",replacement=" ",words)
    mywords <- gsub(pattern="[_]",replacement=" ", mywords)
    mywords <- gsub(pattern="[(_)]",replacement="", mywords)
    mywords <- URLencode(mywords)
    print(paste("search hot news for" ,mywords))
    
    enddate = floor(as.double(as.POSIXlt(Sys.time(),tz="GMT")))
    startdate = enddate - OBSERVATION_INTERVAL_IN_SECONDS/2  #only for 24 hour
    #url = paste('http://access.alchemyapi.com/calls/data/GetNews?apikey=10a7ffc09c69299716a77d3100c0305886443d15&return=enriched.url.title,enriched.url.url,enriched.url.publicationDate&start=',
    #            startdate,
    #            '&end=',
    #            enddate,
    #            '&q.enriched.url.cleanedTitle=',
    #            mywords,
    #            '&count=',
    #            10,
    #            '&outputMode=json',sep="")
    
    url = paste('http://ajax.googleapis.com/ajax/services/search/news?v=1.0&q=',
                mywords,sep="")
    
    if (exists("doc")){
      rm("doc")
    }
    
    print("query to Google API.")
    tryCatch( {
      doc <- fromJSON(file=url)
    }, error = function(e) {
      print("Error in Google API.")
    }
    )
    print("done with Google API.")
    
    
    if (exists("doc") && length(doc$responseData$results) > 0){
      #all_files <- xpathSApply(doc, "//a[contains(@title)]", xmlValue)
      
      news_title <- doc$responseData$results[1][[1]]$titleNoFormatting
      
      news_time <- doc$responseData$results[1][[1]]$publishedDate
      
      news_source <- doc$responseData$results[1][[1]]$unescapedUrl
      
      news_desc <- ""#doc$responseData$results[1][[1]]$content
      
      
      news_category <- ""
      
      now <- floor(as.double(as.POSIXlt(Sys.time(),tz="GMT")))
      delta_of_news <- (now - as.double(strptime(news_time, format="%a, %d %b %Y %X")))
      
      #if news is a recent news
      if (delta_of_news < 72*3600){  
        
        #get the main story photo
        news_image = data.frame(url="", width=0, height=0)#<- getImage2(news_source)
        #if (is.null(news_image))
        #  news_image <- getImage2(paste("http://en.wikipedia.com/wiki/",words,sep=""))
        
        i = 0
        if (is.null(news_image)){
          for (onetitle in all_titles){
            i = i+1
            news_source2 <- toString.XMLNode(xpathSApply(onetitle,"//item/link")[i])
            news_source2 <- sub('\\[\\[1\\]\\]\n<link>',"",news_source2)
            news_source2 <- sub('</link> \n',"",news_source2)
            
            news_image <- getImage2(news_source2)
            if (!is.null(news_image))
              break
          }
        } 
        print(paste("getting news for ", news_title, sep=" "))
        print(paste("source ", news_source, sep=" "))
        print(paste("news image is ", news_image$url, sep=" "))
        
        print("finding related stories...")
        relatedNewsData <- NULL #ExtractRelatedNews(all_titles, news_source)
        
        
        #find time and hotness index
        now <- floor(as.double(as.POSIXlt(Sys.time(),tz="GMT")))
        hottyindex <- max((allwords[which(allwords$word == words),2])/500)
        
        print("writing result in DB ...")
        
        #check if the NewsTable Exists
        tables <- dbListTables(db_news)
        
        news_dataframe = data.frame(news_title = news_title, 
                                    news_source = news_source, 
                                    news_description = news_desc,
                                    news_time = news_time,
                                    news_category = news_category,
                                    timestamp=now,
                                    image_source=news_image$url,
                                    image_width=news_image$width,
                                    image_height=news_image$height,
                                    hotindex = hottyindex,
                                    hotwords = words)
        
        if (length(which(tables == "NewsTable"))>0){
          del_query <- dbSendQuery(conn = db_news, 
                                   paste("delete from NewsTable where news_source = '", news_source, "'",  sep=""))
          del_info <- dbGetInfo(del_query)
        }
        
        if (del_info$rowsAffected == 0){ ##no such a source before
          print("sending to zapier...")
          httpPOST("https://zapier.com/hooks/catch/bqp5gd/", content=toJSON(news_dataframe))   
        
          print("put news in DB")
        
          status <- dbWriteTable(conn = db_news, append = TRUE, name = "NewsTable",
                               row.names = TRUE,
                               value = news_dataframe
                               ) 
          if (!is.null(relatedNewsData)){
            if (length(which(tables == "RelatedNewsTable"))>0)
              dbSendQuery(conn = db_news, 
                          paste("delete from RelatedNewsTable where newsSource = '", relatedNewsData$newsSource, "'",sep=""))
            
            status <- dbWriteTable(conn = db_news, append = TRUE, name = "RelatedNewsTable",
                                   row.names = FALSE,
                                   value = relatedNewsData)   
          }
          
          print("Done writing to DB.")
        }else{
          print("news already exists in DB, no update")
        }
      } ##if the news is real
      else{
        print("no up-to-date news was found...")
      }
      
    } #if doc exists
  }#for
  
}, error = function(e) {
  print("wikiGetNews.R has issues, ask an adult")
  print(e)
  
}
)

dbDisconnect(conn=db_news)
