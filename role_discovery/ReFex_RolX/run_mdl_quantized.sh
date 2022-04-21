#!/bin/sh

#JAVA=/usr/local/bin/java
#JAVAC=/usr/local/bin/javac
#MATLAB=/usr/local/bin/matlab

JAVA=/usr/bin/java
JAVAC=/usr/bin/javac
MATLAB=/Applications/MATLAB_R2013a.app/bin/matlab


MEM_IN_MEGS=500

#output files
NODEFILE=out-nodeRoles.txt #which node belongs to which role
ROLEFILE=out-roleFeatures.txt #which features influenced each role

#feature files are prefixed with this
FEATFILE=out

IDFILE=out-ids.txt 

${JAVAC} HuffmanComparator.java

echo Start matlab
date

${MATLAB} -r "javaaddpath('.'); W=load('${FEATFILE}-featureValues.csv'); IDs=W(:,1); save('${IDFILE}', 'IDs', '-ASCII'); [n,m] = size(W); V=W(1:n,2:m); [F,G,dlen]=NMF_MDL_Quantized(V); save('${NODEFILE}', 'G', '-ASCII'); save('${ROLEFILE}', 'F', '-ASCII'); quit;"

echo Done with matlab
date

echo Finished analysis
date


