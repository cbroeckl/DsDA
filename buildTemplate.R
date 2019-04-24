library(xcms)
library(mzR)

### check For Consistency in retention times for a given scan index
### we need scan time consistency of  < 20% of a typical chromatographic peak width 
### so that we can preschedule our precursor selection. 
### obviously - this also means that you need reproducible retention times in your
### raw chromatography data.  

### build an MS/MS method which uses static precursor ions - NOT DDA. 
### run this method for ten injections
### conver the raw Waters format to mzML using Proteowizard
### we can analyze these files to explore how stable the 
### relationsthip is between scan index and retention time

## set working directory
setwd("R:/RSTOR-PMF/Projects/Broeckling_Corey/DsDA/FinalExperiment/WRENS_20170524_final_dsda.PRO/mzML")

## determine which files you wish to look at
tarfiles<-c("20170522_dsda_0001.mzML",
            "20170522_dsda_0002.mzML",
            "20170522_dsda_0003.mzML",
            "20170522_dsda_0004.mzML",
            "20170522_dsda_0005.mzML",
            "20170522_dsda_0006.mzML",
            "20170522_dsda_0007.mzML",
            "20170522_dsda_0008.mzML",
            "20170522_dsda_0009.mzML",
            "20170522_dsda_0010.mzML")

## build a template to store data
all.vals <-   ms <- data.frame("n" = vector(length = 0, mode = "integer"), 
                               "f" = vector(length = 0, mode = "integer"),
                               "rt" = vector(length = 0, mode = "numeric"), 
                               "ce" = vector(length = 0, mode = "numeric"), 
                               "prec" = vector(length = 0, mode = "numeric"), 
                               "type" = vector(length = 0, mode = "character"), 
                               stringsAsFactors = FALSE)

## retreive scan header data for all files in 'tarfiles'
for(x in 1:length(tarfiles)) {
  
  mzML <- openMSfile(tarfiles[x], backend = "pwiz")
  tmp <- header(mzML)
  
  n <- tmp$acquisitionNum
  f <- tmp$spectrumId
  f <- gsub("function=", "", f)
  f <- as.numeric(t(data.frame(strsplit(f, " ")))[,1])
  rt <- tmp$retentionTime
  ce <- tmp$collisionEnergy
  prec <- tmp$precursorMZ
  type <- rep("msms", length(f))
  type[which(f == min(f))] <- "ms"
  type[which(f == max(f))] <- "lm"
  
  ms <- data.frame("n" = n, 
                   "f" = f,
                   "rt" = rt, 
                   "ce" = ce, 
                   "prec" = prec, 
                   "type" = type, stringsAsFactors = FALSE)
  
  all.vals <- rbind(all.vals, ms)
} 

## order by scan index
all.vals <- all.vals[order(all.vals[,"n"]),]

## process a bit
ind <- unique(all.vals[,"n"])
rt.mean <- sapply(ind, FUN = function(x) {mean(all.vals[which(all.vals[,"n"] == x), "rt"], na.rm = TRUE)})
rt.sd <- sapply(ind, FUN = function(x) {sd(all.vals[which(all.vals[,"n"] == x), "rt"], na.rm = TRUE)})
fun <- sapply(ind, FUN = function(x) {mean(all.vals[which(all.vals[,"n"] == x), "f"], na.rm = TRUE)})
f.types <- data.frame(t(data.frame(strsplit(names(table(paste(all.vals[,"f"], all.vals[,"type"]))), " "), stringsAsFactors = FALSE)), stringsAsFactors = FALSE)
f.type <- fun
for(i in 1:nrow(f.types)) {
  f.type <- gsub(as.numeric(f.types[i,1]), f.types[i,2], f.type)
}

## relationship between scan retention time and the deviation for that retention time
plot(rt.mean, rt.sd, type = "l", 
     main = paste("maximum RT deviation by scan number =", round(max(rt.sd, na.rm = TRUE), digits = 3)))

## ONLY IF YOUR rt.sd is less than 20% of your typical peak width should you proceed!!!
## if your rt.sd is too high, you should try to manually set the interscan delay in the MassLynx tune page
## you want it to be sufficiently long that the relationship between index and rt are stable
## but no longer, as then you are spending instrument time on interscan delay unecessarily. 

## if you are ready, write a template file out as a csv file.  this will be read by WRENS
out <- data.frame('rt' = rt.mean, 'f' = fun, "type" = f.type, stringsAsFactors = FALSE)
plot(out$rt, out$f, type = "l")
write.csv(out, file = "DsDA_schedule.csv", row.names = FALSE)

