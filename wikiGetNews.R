source('ExtractRelatedNews.R')
source('getNewsCategory.R')

library("RSQLite")
require("XML")

db_wikiResult <- dbConnect(SQLite(), dbname="wikiResult.db")

tryCatch({
  res <- dbSendQuery(conn = db_wikiResult, 
            "select * from hotstories where timestamp=(select timestamp from hotstories order by timestamp DESC limit 1)" )

  allwords <- fetch(res,n=-1)
  
  tmp <- data.frame(allwords$word)
  
  dbDisconnect(conn=db_wikiResult)
  
  db_news <- dbConnect(SQLite(), dbname="wikiNews.db")
  for (words in unique(allwords$word)){
    
    mywords <- gsub(pattern="\u2012|\u2013|\u2014",replacement=" ",words)
    mywords <- gsub(pattern="[_]",replacement=" ", mywords)
    mywords <- URLencode(mywords)
    print(paste("search hot news for" ,mywords))
    url = paste("http://api.newslookup.com/search/live?fmt=&q=",
          mywords,"&client_id=999&secret=demosecret0113",sep="")
    
    if (exists("doc")){
      rm("doc")
    }
    
    print("query to newslookup website.")
    tryCatch( {
        doc <- xmlTreeParse(url, useInternalNodes = T)
    }, error = function(e) {
        print("Error in newslookup api")
    }
    )
    print("done with newslookup.")
          
    
    if (exists("doc")){
      #all_files <- xpathSApply(doc, "//a[contains(@title)]", xmlValue)
      all_titles <- xpathSApply(doc, "//response/item")
      
      news_title <- toString.XMLNode(xpathSApply(all_titles[[1]],"//item/title")[1])
      news_title <- sub('\\[\\[1\\]\\]\n<title>',"",news_title)
      news_title <- sub('</title> \n',"",news_title)
      
      news_time <- toString.XMLNode(xpathSApply(all_titles[[1]],"//item/pubdate")[1])
      news_time <- sub('\\[\\[1\\]\\]\n<pubdate>',"",news_time)
      news_time <- sub('</pubdate> \n',"",news_time)
      
      news_source <- toString.XMLNode(xpathSApply(all_titles[[1]],"//item/link")[1])
      news_source <- sub('\\[\\[1\\]\\]\n<link>',"",news_source)
      news_source <- sub('</link> \n',"",news_source)
      
      news_desc <- toString.XMLNode(xpathSApply(all_titles[[1]],"//item/description")[1])
      news_desc <- sub('\\[\\[1\\]\\]\n<description>',"",news_desc)
      news_desc <- sub('</description> \n',"",news_desc)
      
      
      news_category <- getNewsCategory(all_titles)
      
      now <- floor(as.double(as.POSIXlt(Sys.time(),tz="GMT")))
      delta_of_news <- (now - as.double(strptime(news_time, format="%a, %d %b %Y %X")))
      
      #if news is a recent news
      if (delta_of_news < 72*3600){  
        
        #get the main story photo
        news_image <- getImage2(news_source)
        if (is.null(news_image))
          news_image <- getImage2(paste("http://en.wikipedia.com/wiki/",words,sep=""))
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
        relatedNewsData <- ExtractRelatedNews(all_titles, news_source)

        
        #find time and hotness index
        now <- floor(as.double(as.POSIXlt(Sys.time(),tz="GMT")))
        hottyindex <- max((allwords[which(allwords$word == words),2])/500)
          
        print("writing result in DB....")
        
        #check if the NewsTable Exists
        tables <- dbListTables(db_news)
        
        if (length(which(tables == "NewsTable"))>0)
           dbSendQuery(conn = db_news, 
                      paste("delete from NewsTable where news_source = '", news_source, "'",  sep=""))
          
        status <- dbWriteTable(conn = db_news, append = TRUE, name = "NewsTable",
                             row.names = FALSE,
                             value = data.frame(news_title = news_title, 
                                                news_source = news_source, 
                                                news_description = news_desc,
                                                news_time = news_time,
                                                news_category = news_category,
                                                timestamp=now,
                                                image_source=news_image$url,
                                                image_width=news_image$width,
                                                image_height=news_image$height,
                                                hotindex = hottyindex,
                                                hotwords = words
                                                ) )  
        if (!is.null(relatedNewsData)){
          if (length(which(tables == "RelatedNewsTable"))>0)
            dbSendQuery(conn = db_news, 
                      paste("delete from RelatedNewsTable where newsSource = '", relatedNewsData$newsSource, "'",sep=""))
          
          status <- dbWriteTable(conn = db_news, append = TRUE, name = "RelatedNewsTable",
                               row.names = FALSE,
                               value = relatedNewsData)   
        }
        
        print("Done writing to DB.")
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
