add_data2DB <- function(data2add)

library("DBI")
library("RSQLite")

if (!file.exists("wikiData.db")){
  print("db does not exist, creating...")
}

# Creates the database if none exists;
# Or connects to the database if one already exists.

db <- dbConnect(SQLite(), dbname="wikiData.db")

# Create a table containing school data
#dbSendQuery(conn = db, 
#            "CREATE TABLE PAGEACCESS 
#       (id INTEGER,
#        page_name TEXT, 
#        page_counts INTEGER,
#        timestamp INTEGER)")

status <- dbWriteTable(conn = db, append = TRUE, name = "PAGEACCESS",
             row.names = FALSE,
             value = data.frame(word = data2add$word, 
                                count = data2add$count, time = data2add$time) )
pendingResults = dbListResults(db)
if (length(pendingResults) > 0)
    dbClearResult(pendingResults[[1]])

dbDisconnect(conn=db)
