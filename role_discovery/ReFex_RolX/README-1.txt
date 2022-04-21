(1) ReFex.jar calls the GenerateFeatures class to generate features when the
set of features is unknown.  If the set of features is known, then you need to
use CalculateFeatures class.

(2) These are the matlab routines: 

NMF_Model_Select.m: Latest model selection code; usage is in the file's header
NMF_LS_new:  NMF with our original heuristic for stopping criteria
NMF_AIC:  NMF with AIC for model selection
NMF_MDL:  NMF with MDL as the stopping criteria
SNMF_MDL: sparse NMF with MDL as the stopping criteria 
truncate: called inside NMF_MDL and SNMF_MDL to truncate reals
nmfsh_comb:  sparse NMF from Georgia Tech
fcnnls: called inside nmfsh_comb

(3) There are sample input data in sample-data/ directory

(4) To run the code with NMF_AIC, just run this script run.sh

(5) The output are:

out-featureNames.csv: feature names extracted by ReFex
out-featureValues.csv: feature values extracted by ReFex
out-ids.txt: node ID reordering for matlab
out-nodeRoles.txt: node-by-role matrix
out-roleFeatures.txt: role-by-feature matrix

