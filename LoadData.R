all_data <- data.frame(word="Hamed",count=100,day=0)

all_files <- list.files(path=path.page.access.data)
for (filename in all_files){
  #filename = all_files[11]
  print(filename)
  
  day <- as.integer(substr(filename,start=18,stop=19))
  hour <- as.integer(substr(filename,start=21,stop=22))
  
  local_filename <- paste(path.page.access.data,filename,sep="")
  
  if (hour >=4 && hour<=20 ){
    data <- tryCatch(
      {
        read.delim(gzfile(local_filename), sep=" ", header=FALSE, 
                       skip=500000, nrows=1200000,
                       colClasses=c('character','character','double','double'))
      }, error = function(e) {
        data <- data.frame("Hamed","ll",100,0) 
      }, finally = {
        data <- data.frame("Hamed","ll",100,0) 
      }
    )
    
    data <- data[,-4]
  
    endata <- data[which(data[,1]=="en"),]
    x <- endata[which(endata[,3]>2000),-1]
    if (dim(x)[1] != 0){
      
      x <- data.frame(word=as.character(x[,1]),count=x[,2],day=day)
  
      all_data_day <- all_data[all_data$day == day,]
      all_data <- all_data[!(all_data$day == day),]
      if (dim(all_data_day)[2]==0)
        all_data_day <- data.frame(word="Hamed",count=100,day=day)
      
      all_data_day <- all_data_day[order(as.character(all_data_day$word)),]
      x <- x[order(as.character(x$word)),]
      
      all_data_x1 <- all_data_day[all_data_day$word %in% x$word,]
      all_data_x2 <- x[x$word %in% all_data_day$word,]
    
      sumup <- all_data_x1$count + all_data_x2$count
    
      all_data_day[all_data_day$word %in% x$word,"count"] <- sumup
      
      remain_x <- x[!(x$word %in% all_data_day$word),]
      
      all_data_day <- rbind(all_data_day,remain_x)
      
      all_data <- rbind(all_data,all_data_day)
    }
    
  }#hour if
}

