How to use GCtoMAT_v4
================

## The purpose of this code

“GCtoMAT” (meaning “GC to matrix”) gathers multiple chromatograph
outputs from a gas chromatograph (GC) and automatically organizes their
useful data into one matrix or “master table” in which areas from peaks
at similar retention times (RT’s) can be compared to each other.
Gathering peak data from hundreds of files is tedious and software that
does it for you is hard to come by. This code aims to makes such
analysis possible to anyone doing research involving GC data. Following
this intent, this code is written to use .csv files from “.D” folders as
its only input, since .D folders appear to be the universal output that
Agilent GC/MS machines store data in each time they run a sample. No
extra software for viewing/modifying/or arranging GC files is required
to use this code.

This document shows you *how to use* this code, not *how to understand*
what each command line is doing. Therefore, I will only discuss how to
set up your folders and files, run the script, and interpret its
outputs. Once everything is prepared as expected, running the script all
at once should give you the master tables you desire.

## Outline:

1.  Set up working directories
2.  Running the script + fixing potential errors
3.  Reading + modifying the master tables

------------------------------------------------------------------------

### PART I: Set up working directories

To access all the data in the .D folders and begin merging them
together, the RESULTS.CSV files within each .D folder must be identified
and extracted into a single working directory. To do this, all the
folders are placed in one directory (e.g. “…/C20_Tests/Files/”), and all
their .CSV files are copied and moved into the directory preceeding it
(e.g. “…/C20_Tests/”). These are referred to as the secondary and
primary directories, respectively.

``` r
## Set PRIMARY and SECONDARY directories
PRIMARY_DIR <- "C:/Users/Brian/Desktop/R_folder/GCtoMAT/C20_Tests"
SECONDARY_DIR <- "C:/Users/Brian/Desktop/R_folder/GCtoMAT/C20_Tests/Files"
```

**You will need to change these to your own working directories**.
Gathering your .D folders into your secondary directory, and defining
your primary and secondary directories in the script is the only thing
you have to do before running the code.

If this is not making sense, maybe the images at the end of this
document will help. Before running the first block of code (i.e. *BLOCK
1: Set up + clean up*), your primary directory should look similar to
FIG 1. Within that primary directory is the secondary directory
(e.g. the “Files” folder), where all the unmodified .D folders fresh
from the GC are contained (FIG 2). After running the first block of
code, your primary directory should have all the .csv files renamed and
copied into it (FIG 3). If your directories look similar, you should be
ready to run the rest of the script.

------------------------------------------------------------------------

### PART II: Running the script + fixing potential errors

In R studio, you can run the entire script with the “Source” option,
next to the “Run” option (which only runs what you have selected). If
you are worried about getting errors, you can run each command line
one-by-one, such that when errors occur you know exactly where they are
occuring. Errors can occur for many unpredictable reasons, but here are
some things you should check first if the code is not working for you:

-   *Empty .CSV files*
    -   Even if no data is collected from a GC run due to an error, a .D
        folder with a RESULTS.CSV file is still generated. Double check
        to make sure you aren’t including any empty .CSV files in your
        collection of .D folders. These empty files will prevent a
        master table from being formed.
-   *Different RESULTS.CSV layout*
    -   In the for-loop for gathering RT and Area data from RESULTS.CSV
        files (below), we assume that:
        -   the first 7 rows of the file are useless info to be removed
        -   RT and Area data is found in column 3 and 9 specifically.
        -   A “\[PBM Peak average\]” section is generated, and needs to
            be removed.
    -   Make sure these assumptions are true for your RESULTS.CSV files.
        If your GC generates these .CSVs slightly differently, you can
        modify the first 3 command lines in this for-loop to fit your
        unique .CSV layouts.

``` r
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
```

------------------------------------------------------------------------

### PART III: Reading + modifying the master tables

If you succeed in running this code with your data, BASE (FIG 4) and
ROUNDED (FIG 5) matrices are generated. The base matrix creates a column
for every unique RT value down to the millisecond. In other words, a
peak recorded at 6.323 minutes is considered different from a peak
recorded at 6.322 minutes, and gets its own column where its
corresponding area data is stored. Of course, these peaks can be
interpreted as the same compounds separated by just a millisecond, but
this is a subjective call that everyone has to make when analyzing GC
data.

We offer the ROUNDED matrices as a way to systematically work around
this, assuming every RT can be rounded to the nearest second, or even
rounded to the nearest minute. For example, if RTs are rounded to the
nearest second, they would be rounded to the 2nd digit after the
decimal:

``` r
##R2_MATRIX: masterRT rounded to second digit, with area's aggregated
r2_m <- m
r2_m[,1] = round(r2_m[,1],2) # round the masterRT to the second digit
r2_m <- as.data.frame(r2_m) # make data frame before using aggregate
r2_m <- aggregate(. ~ masterRT, data=r2_m, FUN=sum) # sum's up area values in a column based on shared masterRT
r2_m <- t(r2_m)
write.csv(r2_m,file="0-R2_matrix.csv",row.names=TRUE)
```

This would mean a peak at 6.323 minutes would be put in the same column
as a peak at 6.322 minutes. If these two peaks are found *in the same
.csv file*, their area’s are summed together. If they are come from
different .csv files, they are placed in the same column, but in
separate rows, each row corresponding to the .csv file they came from.

**The rounding step is entirely subjective, and should be modified for
each user**. In our case, millisecond differences between RTs can be
ignored, but RTs separated by a minute or more could be different
compounds, likely needing further investigation. While these master
tables require further modifications and manipulations depending on each
user’s research questions and planned analyses, having hundreds of files
worth of GC data all organized into one table can make comparisons much
easier, preparing your code for statistical analyses in one quick step.

------------------------------------------------------------------------

### **PICTURES**

------------------------------------------------------------------------

#### *FIG 1: Primary directory BEFORE running block 1*

![](C:/Users/Brian/Desktop/R_folder/GCtoMAT/PIC_PrimDirB.png)

------------------------------------------------------------------------

#### *FIG 2: Secondary directory, holding the .D folders*

![](C:/Users/Brian/Desktop/R_folder/GCtoMAT/PIC_SecDir.png)

------------------------------------------------------------------------

#### *FIG 3: Primary directory AFTER running block 1*

![](C:/Users/Brian/Desktop/R_folder/GCtoMAT/PIC_PrimDirA.png)

------------------------------------------------------------------------

#### *FIG 4: Base matrix. Column = RTs. Row = Area data for each .csv*

![](C:/Users/Brian/Desktop/R_folder/GCtoMAT/PIC_Bmatrix.jpg)

------------------------------------------------------------------------

#### *FIG 5: R1 matrix (rounded to first decimal). Column = RTs. Row = Area data for each .csv*

![](C:/Users/Brian/Desktop/R_folder/GCtoMAT/PIC_R1matrix.jpg)

------------------------------------------------------------------------
