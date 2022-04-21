#!/bin/sh

#JAVA=/usr/local/bin/java
#MATLAB=/usr/local/bin/matlab

# JAVA=/usr/bin/java
# JAVAC=/usr/bin/javac
# MATLAB=/Applications/MATLAB_R2013a.app/bin/matlab
#JAVA=/usr/local/bin/java
MATLAB=/usr/local/bin/matlab
JAVA=/usr/bin/java
MEM_IN_MEGS=6500

#input file
INFILE=sample-data/Halophiles_data #csv file with source,dest,weight records

#parameter values
CORR_THRESH=0 #usually 0 -- this is the initial lattice error threshold
BIN_SIZE=0.5 #usually 0.5 -- this is the fraction in each bin

#output files
NODEFILE=out-nodeRoles.txt #which node belongs to which role
ROLEFILE=out-roleFeatures.txt #which features influenced each role

#feature files are prefixed with this
FEATFILE=out
IDFILE=out-ids.txt 

${JAVA} -Djava.util.Arrays.useLegacyMergeSort=true -Xmx${MEM_IN_MEGS}M -jar ReFex.jar ${INFILE} ${CORR_THRESH} ${BIN_SIZE} ${FEATFILE}

echo Finished analysis
date


