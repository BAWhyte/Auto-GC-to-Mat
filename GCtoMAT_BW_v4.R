### - GCtoMAT_BW_v4 - ###
# AUTHOR: Brian Whyte, PhD Candidate, UC Berkeley
# EMAIL: ba.whyte@berkeley.edu

### INSTRUCTIONS ###
# 1) Have all .D folders in a the same directory (make sure they have data!)
# 2) Modify PRIMARY and SECONDARY paths (labeled below) to your own directories
# 3) Source this script (i.e. run it all at once) and look for "matrix" csv's in your primary directory.
#    This matrix is the combined data of all RESULTS.CSV files, making for easier comparitive analysis.
# 
# - Always let me know if you run into problems:
#           ba.whyte@berkeley.edu
# - glhf

### PATCH NOTES ###
# vJJ_2   - Output is now an Area vs. RT matrix
#         - Merging to masterRT no longer rounds or subsequently removes duplicates
# vJJ_2b  - Output is now three matrixes. One with a non-rounded masterRT, and then two where the masterRT
#           has been rounded (to the 1st or 2nd digit) and area data sharing the same masterRT (within data sets)
#           have been summed together using aggregate()
# v3      - Read GCMS csv files differently (removes [PBM Peak Average] section)
# v4      - Renames RESULTS.CSV files from directory of many .D folders
#         - Extracts .CSV files from many subfolders into main directory
# ------------------------------------------------------------------------- 

# BLOCK 1: Set up + clean up -----------------------------------------------

## Housekeeping
cat("\014") # Clear console
rm(list=ls()) # Remove all variables
require(stringi) # package for stri_list2matrix()
## Set PRIMARY and SECONDARY directories
PRIMARY_DIR <- "C:/Users/Brian/Desktop/R_folder/GCtoMAT/CHC_Oct29"
SECONDARY_DIR <- "C:/Users/Brian/Desktop/R_folder/GCtoMAT/CHC_Oct29/Files"
# Start with secondary directory
setwd(SECONDARY_DIR)
## Create list of .csv names
L <- list.dirs(path= ".", full.names=FALSE) # list folders in SECONDARY directory
L <- L[-1] # remove empty first value
L <- L[-which(grepl("/", L) == TRUE)] # remove unwanted subfolders
## Rename all RESULTS.CSV with folder names and move them into PRIMARY directory
for (i in 1:length(L)) {
  setwd(SECONDARY_DIR)
  tempDir <- paste(getwd(),paste("/", L[i], sep= ""), sep= "")
  setwd(tempDir)
  file.rename("RESULTS.CSV", paste(L[i], ".CSV", sep= ""))
  file.copy(file.path(tempDir,list.files(tempDir, "*.CSV")), PRIMARY_DIR)
}

# BLOCK 2: Merge all .csv into list, isolating RT and Area data ----------

## Return to PRIMARY directory and list all .csv files we've prepared
setwd(PRIMARY_DIR)
names <- list.files(pattern="*.CSV") 
l <- list() # empty list to be filled below
## Gather .csv data into list, where each object is RT or Area data from .csv's
for (i in 1:length(names)) {
  df <- assign(names[i], read.csv(names[i],skip=7,dec=".",sep=",")) # read first .csv, skipping useless first rows
  df <- df[-(which(df == "[PBM Peak average]", arr.ind = TRUE)[1]:nrow(df)),] # remove PBM section 
  df <- df[c(3,9)] # remove all but RT and Area columns
  colnames(df) <- c("RT","Area")
  n <- names[i]
  l[[paste(c(n,"_RT"),sep="",collapse="")]] <- df$RT
  l[[paste(c(n,"_Area"),sep="",collapse="")]] <- df$Area
}

# BLOCK 3: Transform list into master table matrix -------------------------

## Create masterRT df for merging other RT + Area data onto it
masterRT <- unique(sort(as.vector(unlist(l[which(grepl("RT",names(l)))]))),decreasing=FALSE) # all possible RTs
dfRT <- data.frame(masterRT,stringsAsFactors = FALSE) # convert from matrix to data frame
## Gather list data and organize it for merging
tempdf <- stri_list2matrix(l) 
colnames(tempdf) <- names(l) 
tempdf[is.na(tempdf)] <- 0
tempdf <- as.data.frame(tempdf)
## Merge all RT + Area data, such that they are organized based on the masterRT
for (j in 1:length(names)) {
  ndf <- tempdf[which(grepl(names[j],names(tempdf)))] # grab one file's data and copy to new df
  ndf["masterRT"] <- ndf[1]
  dfRT <- merge(dfRT,ndf,by = "masterRT", all.x=TRUE) # align ndf data to dfRT by shared "masterRT" column
}
dfArea <- dfRT[,-which(grepl("_RT",names(dfRT)))] # remove RT data, leaving only area data
m <- as.matrix(dfArea) # convert data frame to matrix so eliminating NA's is easy
m[is.na(m)] <- 0
class(m) <- "numeric" # makes sure numbers=numbers, and not characters

# BLOCK 4: Output base and rounded matrices --------------------------------

##BASE_MATRIX: masterRT not rounded
base_m <- as.data.frame(m, stringsAsFactors = FALSE)
base_m <- t(base_m) # transpose, switching x and y axis
write.csv(base_m, file="0-base_matrix.csv",row.names=TRUE)
##R2_MATRIX: masterRT rounded to second digit, with area's aggregated
r2_m <- m
r2_m[,1] = round(r2_m[,1],2) # round the masterRT to the second digit
r2_m <- as.data.frame(r2_m) # make data frame before using aggregate
r2_m <- aggregate(. ~ masterRT, data=r2_m, FUN=sum) # sum's up area values in a column based on shared masterRT
r2_m <- t(r2_m)
write.csv(r2_m,file="0-R2_matrix.csv",row.names=TRUE)
##R1_MATRIX: masterRT rounded to first digit, with area's aggregated
r1_m <- m
r1_m[,1] = round(r1_m[,1],1) # round the masterRT to the second digit
r1_m <- as.data.frame(r1_m) # make data frame before using aggregate
r1_m <- aggregate(. ~ masterRT, data=r1_m, FUN=sum) # sum's up area values in a column based on shared masterRT
r1_m <- t(r1_m)
write.csv(r1_m,file="0-R1_matrix.csv",row.names=TRUE)
### FINISH ###
