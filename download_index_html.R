require(XML)
#setwd("../")

DOWNLOAD_INTERVAL_IN_DAYS = 2

url = "http://dumps.wikimedia.org/other/pagecounts-raw/2015/2015-07/"

doc = htmlTreeParse(paste(url,"index.html",sep=""), useInternalNodes = T)

all_files <- sort(xpathSApply(doc, "//a[contains(@href, 'pagecounts-2015')]", xmlValue))

calcTimeDiffPageCounts <- function(x){
  (as.numeric(Sys.time()) - as.numeric(strptime(x, "pagecounts-%Y%m%d-%H0000.gz", tz="UTC")))/86400
}

all_local_files <- list.files(path=path.page.access.data)

if (length(all_local_files) > 0){
  removable_file <- all_local_files[1]
}else{
  removable_file = ""
}

for (pagecounts in all_files){
  print(pagecounts)
  if ((!pagecounts %in% all_local_files) && (calcTimeDiffPageCounts(pagecounts) < DOWNLOAD_INTERVAL_IN_DAYS)){
    
    day <- as.integer(substr(pagecounts,start=18,stop=19))
    
    print(paste("Downloading ...",pagecounts))
     
    local_filename = paste(path.page.access.data, pagecounts,sep="")
    
    download.file(url = paste(url,pagecounts,sep=""), 
              destfile = local_filename) 
  }
}

print(paste("to save storage removing ", removable_file))
file.remove(paste(path.page.access.data, removable_file,sep=""))
