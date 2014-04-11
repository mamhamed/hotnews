getNewsCategory <- function(all_titles){
  category <- toString.XMLNode(xpathSApply(all_titles[[1]],"//item/category")[1])
  category <- sub('\\[\\[1\\]\\]\n<category>',"",category)
  category <- sub('</category> \n',"",category)
  
  if (category == "[[1]]\nNULL\n"){
    return("News")
  }
  else
    return(category)
}
  
  