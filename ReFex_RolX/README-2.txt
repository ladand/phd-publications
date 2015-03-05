(0) You should compile and run the code with Java 1.6.  If you wish to use Java 1.7 (and not Java 1.6),  then just set the system property java.util.Arrays.useLegacyMergeSort to true.  That is, when running java add this to the command line:

-Djava.util.Arrays.useLegacyMergeSort=true

(1) These are the different matlab routines for RolX:

  * NMF_AIC:  NMF with AIC for model selection
  * SNMF_MDL: sparse NMF with MDL as the stopping criteria 
  * truncate: called inside SNMF_MDL to truncate reals
  * nmfsh_comb:  sparse NMF from Georgia Tech
  * fcnnls: called inside nmfsh_comb

(2) There is sample feature-value input in this file: in-featureValues.csv
The feature-heading is in this file: in-featureNames.csv
These features were generated automatically for a network coauthorship graph using another program.

Note: The feature values are assumed to be non-negative.  The in-featureValues.csv file has no column headings and no node-IDs in it.

(3) You also need a file called in-ids.txt, which is the node-ID reordering for matlab.
 
(4) To run the code with NMF_AIC, just run this script: run_aic.sh

(5) To run the code with NMF_MDL_Quantized.m, just run this script: run_mdl_quantized.sh

(6) The output are these:

  * out-nodeRoles.txt: node-by-role matrix
  * out-roleFeatures.txt: role-by-feature matrix

