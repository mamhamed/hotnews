require(XML)
#setwd("../")

DOWNLOAD_INTERVAL_IN_DAYS = 2

url = "http://dumps.wikimedia.org/other/pagecounts-raw/2015/2015-07/"

doc = htmlTreeParse(paste(url,"index.html",sep=""), useInternalNodes = T)

all_files <- xpathSApply(doc, "//a[contains(@href, 'pagecounts-2015')]", xmlValue)

all_local_files <- list.files(path=path.page.access.data)

day_now <- as.integer(substr(as.character(Sys.Date()),start=9,stop=11))

for (pagecounts in all_files){
  print(pagecounts)
  if (!pagecounts %in% all_local_files){
    
    day <- as.integer(substr(pagecounts,start=18,stop=19))
    
    if (day_now - day < DOWNLOAD_INTERVAL_IN_DAYS){
       print(paste("Downloading ...",pagecounts))
       local_filename = paste(path.page.access.data, pagecounts,sep="")
      
       download.file(url = paste(url,pagecounts,sep=""), 
                  destfile = local_filename) 
                  #method="wget", quiet = FALSE, mode = "w",
                  #cacheOK = TRUE, extra = getOption("download.file.extra"))
    }#download interval
  }
}
