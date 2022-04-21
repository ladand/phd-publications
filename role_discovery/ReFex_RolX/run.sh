#!/bin/sh

JAVA=/usr/local/bin/java
MATLAB=/usr/local/bin/matlab

MEM_IN_MEGS=500

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

${JAVA} -Xmx${MEM_IN_MEGS}M -jar ReFex.jar ${INFILE} ${CORR_THRESH} ${BIN_SIZE} ${FEATFILE}

echo Start matlab
date

${MATLAB} -r "W=load('${FEATFILE}-featureValues.csv'); IDs=W(:,1); save('${IDFILE}', 'IDs', '-ASCII'); [n,m] = size(W); V=W(1:n,2:m); [F,G]=NMF_AIC(V); save('${NODEFILE}', 'G', '-ASCII'); save('${ROLEFILE}', 'F', '-ASCII'); quit;"

echo Done with matlab
date

echo Finished analysis
date


