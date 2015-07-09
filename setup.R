
#setup required packages
list.of.required.packages <- c("XML", "RSQLite", "rjson", "DBI")
list.of.missing.packages <- list.of.required.packages[!(list.of.required.packages %in% installed.packages()[,"Package"])]
if(length(list.of.missing.packages) > 0) install.packages(list.of.missing.packages)

#directory ame needs to be end with /
if (grepl('windows',Sys.info()['sysname'], ignore.case=TRUE))
  path.page.access.data = "C:\\"
else
  path.page.access.data = "./wikiHourlyData/"
dir.create(path.page.access.data, showWarnings = FALSE)
  
## constants and parameters
OBSERVATION_INTERVAL_IN_SECONDS = 48*3600
MIN_WIKI_ARTICLE_ACCESS_COUNT = 50

## section of file to read
FILE.START = 500000
FILE.STEP = 1200000

