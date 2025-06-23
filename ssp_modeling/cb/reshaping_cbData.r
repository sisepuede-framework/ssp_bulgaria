#lets just bring in the 
#read all folders 
 dir.data <- "ssp_modeling/cb/cb_results/"
 target_cb_file <- "cost_benefit_results_tornado.csv"
 cb_data <-read.csv(paste0(dir.data,target_cb_file))

 cb_chars <- data.frame(do.call(rbind, strsplit(as.character(cb_data$variable), ":")))
 colnames(cb_chars) <- c("name","sector","cb_type","item_1","item_2")
 cb_data <- cbind(cb_data,cb_chars)
 cb_data$value <- cb_data$value/1e9

#remove shifted 
 dim(cb_data)
 cb_data <- subset(cb_data,grepl("shifted",cb_data$item_2)==FALSE)
 dim(cb_data)
 ids <- unique(cb_data$variable)
 ids <- subset(ids,grepl("shifted2",ids)==FALSE)
#clean  
 cb_data <- subset(cb_data,grepl("shifted2",cb_data$variable)==FALSE)
 dim(cb_data)

#add Year 
cb_data$Year <- cb_data$time_period+2015

head(cb_data)

#change strategy names 
cb_data$strategy <- gsub("PFLO:LEP", "Lower Emissions Pathway", cb_data$strategy )


#create strategy id 
cb_data$strategy <- cb_data$strategy_code
cb_data$strategy_id <- ifelse(cb_data$strategy=="PFLO:LEP",600)
cb_data$ids <- paste(cb_data$variable,cb_data$strategy_id,sep=":")

dir.out <- "ssp_modeling/Tableau/data/"

write.csv(cb_data,paste0(dir.out,"cb_data.csv"),row.names=FALSE)