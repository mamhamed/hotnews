getImage2 <- function(url){
  library("rjson")
  embedelyapi = paste("http://api.embed.ly/1/extract?key=7bdffa10dedf43238c8321d2458e7e0d&url=",url,sep="")

  rm("allimages");

  tryCatch({ 
    res <- fromJSON(file=embedelyapi)  
    allimages <- res$images
  }, error = function(e) {
    print("error in extracting the image, moving on")
  }
  )

  if (exists("allimages")){
     if (length(allimages) > 0)
       return (allimages[[1]])
     else
       return (NULL)
  }

}


