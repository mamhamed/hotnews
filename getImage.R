getImage <- function(url)
{
  require('XML')  
  #url = "http://boston.cbslocal.com/2014/01/23/top-5-moments-in-super-bowl-history/"
  #url = "http://insidetv.ew.com/2014/01/30/revolution-ratings-2/"
  #url = "http://www.hollywoodreporter.com/news/super-bowl-2014-commercial-bob-676570"
  tryCatch( {
    doc <- htmlTreeParse(url, useInternalNodes = T)
  }, error = function(e) {
    print("Error in loading the html")
  }
  )
  if (exists("doc")){
    all_images <- getNodeSet(doc, "/html//img[@src]") 
    image_size_data <- data.frame(image_url="", image_size = -1)
    for (image in all_images){
      news_image = toString.XMLNode(image)[[1]]
      #print(paste("image = ", news_image, sep = " "))
      
      src_index <- regexpr("src=",news_image)[[1]][1]
      image_url = substr(news_image, src_index+5, nchar(news_image))
      image_url = sub('/>',"",image_url)
      src_index2 <- gregexpr(" ",image_url)[[1]][1]
      if (src_index2 > 0 )
        image_url = substr(image_url, start = 1, stop=src_index2-2)
      
      
      index <- regexpr("width=", news_image)[1]
      width = substr(news_image,index+7,index+9)
      width = gsub("[^1-9]","",width)
      
      index <- regexpr("height=", news_image)[1]
      height = substr(news_image,index+8,index+10)
      height = gsub("[^1-9]","",height)
      
      width <- as.double(width)
      height <- as.double(height)
     if (!is.na(width) || !is.na(height)){
        if (is.na(width))
          image_size <- height*height
        else if (is.na(height))
          image_size <- width*width
        else
          image_size <- width*height
     }else
       image_size <- 0 
      
      #print(image_url)
      #print(image_size)
      
      
      if (!is.na(image_size)){
        tmp <- data.frame(image_url=image_url, image_size = image_size)
        image_size_data <- rbind(tmp,image_size_data)
      }
    
    } 
  }
  
  image_size_data <- image_size_data[order(image_size_data$image_size, decreasing=TRUE),]
  
  selected_img <- toString(((image_size_data$image_url)[1]))
  selected_img_size <- as.double((image_size_data$image_size)[1])

  if (selected_img_size <= 40000)
    selected_img <- ""
  
  return (selected_img)
  
  
}