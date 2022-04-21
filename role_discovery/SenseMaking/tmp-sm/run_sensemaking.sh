#!/bin/sh

#paths on linux
#JAVA=/usr/local/bin/java
#JAVAC=/usr/local/bin/javac
#MATLAB=/usr/local/bin/matlab

#paths on Tina's MAC
JAVA=java
JAVAC=javac
MATLAB=/Applications/MATLAB_R2010b.app/bin/matlab

#input file
INPUTG= ./input/netsci-G.csv
INPUTV= ./input/netsci-V.csv

#output file
OUTPUTA= ./output/test-A.csv
OUTPUTM= ./output/test-M.csv
OUTPUTE= ./output/test-E-analysis.csv
OUTPUTQ= ./output/test-Q-analysis.csv
OUTPUTEQ= ./output/test-EQ-analysis.csv

${JAVAC} HuffmanComparator.java

#Generate a 1-indexed version of the graph file (test-A.csv) so
#Matlab can read it. The order of nodes is the same as in the V file
#(netsci-V.csv). It also generates an example "property" file
#(test-M.csv), which in this case has just two properties: eccentricity
#and the number of biconnected components. Again, the order is the same
#as in the V file. This can be omitted if you just want the properties
#calculated in matlab (degrees, pagerank, clustering).

./make_adjacency.py $INPUTG $INPUTV > $OUTPUTA
./eccentricity.py $INPUTG $INPUTV > $OUTPUTM

${JAVAC} HuffmanComparator.java

exit
echo Start matlab
date

${MATLAB} -r "javaaddpath('.'); V = dlmread('${INPUTV}',',',1,1); A = spconvert(dlmread('${OUTPUTA}')); [M, E, N, Q, E_names, Q_names, err] = MakeSense(A,V,'${OUTPUTM}'); WriteRoleProperties(M, E, E_names, '${OUTPUTE}'); WriteRoleProperties(N, Q, Q_names, '${OUTPUTQ}'); WriteRoleProperties([M N], [E Q], [E_names Q_names], '${OUTPUTEQ}'); quit;"

#comments on the matlab commands
# The first two commands just read feature matrix V (input to our
# program) and adjacency matrix A from the file we generated in
# python. 
#
# The third line calls the main sensemaking code, which (1)
# computes topological properties M and, if necessary, reads in the
# external properties we generated in python, adding these to M. It also
# computes N, the neighborhood matrix (node x role, tells the percentage
# of node i's neighborhood that is role j). It computes F and G using
# our MDL version of RolX, and then computes E s.t. GE=M using fixed G
# NMF, and Q s.t. GQ=N, using fixed G NMF. It also returns cell arrays
# with names for each column of E and Q, and an n-by-3 array err which
# has the "anomaly score" of each node based on (1) GF=V reconstruction
# error, (2) GE=M reconstruction error, (3) GQ=N reconstruction error.
#
# The last three lines show how to write the results to a csv file so
# you can load it in excel or whatever. If you call it with M, E, and
# E_names, it will have one row per role (plus one default row), and one
# column per column of M. The value at Role i and Property j is the
# ratio of E(i,j) to E_1(i,j), where E_1 is the matrix we get if we try
# to fit G_1*E_1=M, where G_1 is a n-by-1 matrix (only one role). So all
# the defaults are 1.0. You can do the same with N, Q, and Q_names, or
# just concatenate everything to get one file with all of it.

echo Done with matlab
date

echo Finished sensemaking
date


#Notes:
#If you just had the V file (output of ReFeX, first row is 
#feature names and first column is nodeIDs) and the graph file 
#(u,v,w where u and v are nodeIDs that appear in the V file). 
#They are in a file called commands.txt, and the example input 
#is in the input folder.

