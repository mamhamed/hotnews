ExtractRelatedNews <- function(all_titles, newsSource)
{

  if (exists("relatedStories"))
    rm("relatedStories")
  
  category = getNewsCategory(all_titles)
  
  for ( i in 2:min(length(all_titles),4) ){
    onetitle <- all_titles[[i]]
    news_source2 <- toString.XMLNode(xpathSApply(onetitle,"//item/link")[i])
    news_source2 <- sub('\\[\\[1\\]\\]\n<link>',"",news_source2)
    news_source2 <- sub('</link> \n',"",news_source2)
    
    #news_image <- getImage2(news_source2)
    news_image <- data.frame(url="", width=0, height=0)
    
    news_title <- toString.XMLNode(xpathSApply(onetitle,"//item/title")[i])
    news_title <- sub('\\[\\[1\\]\\]\n<title>',"",news_title)
    news_title <- sub('</title> \n',"",news_title)
    
    news_desc <- toString.XMLNode(xpathSApply(all_titles[[1]],"//item/description")[i])
    news_desc <- sub('\\[\\[1\\]\\]\n<description>',"",news_desc)
    news_desc <- sub('</description> \n',"",news_desc)
    
    news_time <- toString.XMLNode(xpathSApply(onetitle,"//item/pubdate")[i])
    news_time <- sub('\\[\\[1\\]\\]\n<pubdate>',"",news_time)
    news_time <- sub('</pubdate> \n',"",news_time)
    
    now <- floor(as.double(as.POSIXlt(Sys.time(),tz="GMT")))
    delta_of_news <- (now - as.double(strptime(news_time, format="%a, %d %b %Y %X")))
 
    #if found the related news
    if ( (delta_of_news < 3*24*3600) & !is.null(news_source2) ){  
      if (!exists("relatedStories"))  
        relatedStories <- data.frame(newsSource = newsSource,
                                     relatedSource=news_source2, 
                                     relatedTitle=news_title,
                                     relatedDescription = news_desc,
                                     relatedCategory=category,
                                     relatedImage=news_image$url,
                                     relatedImageWidth=news_image$width,
                                     relatedImageHeight=news_image$height,
                                     relatedTime=news_time)
      else
        relatedStories <- rbind(relatedStories, 
                                data.frame(newsSource = newsSource,
                                           relatedSource=news_source2, 
                                           relatedTitle=news_title,
                                           relatedDescription = news_desc,
                                           relatedCategory=category,
                                           relatedImage=news_image$url,
                                           relatedImageWidth=news_image$width,
                                           relatedImageHeight=news_image$height,
                                           relatedTime=news_time)
                                )
        
    }
    else
      break
  }
  
  if (exists("relatedStories"))
    return (relatedStories)
}
