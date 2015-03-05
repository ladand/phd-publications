#!/bin/sh

#JAVA=/usr/local/bin/java
#MATLAB=/usr/local/bin/matlab

JAVA=/usr/bin/java
MATLAB=/Applications/MATLAB_R2010b.app/bin/matlab

MEM_IN_MEGS=500

#input file
INFILE=sample-data/Halophiles_data #csv file with source,dest,weight records
#output files
NODEFILE=out-nodeRoles.txt #which node belongs to which role
ROLEFILE=out-roleFeatures.txt #which features influenced each role

#feature files are prefixed with this
FEATFILE=in

IDFILE=in-ids.txt 

echo Start matlab
date

${MATLAB} -r "W=load('${FEATFILE}-featureValues.csv'); IDs=W(:,1); save('${IDFILE}', 'IDs', '-ASCII'); [n,m] = size(W); V=W(1:n,2:m); [F,G]=NMF_AIC(V); save('${NODEFILE}', 'G', '-ASCII'); save('${ROLEFILE}', 'F', '-ASCII'); quit;"

echo Done with matlab
date

echo Finished analysis
date


