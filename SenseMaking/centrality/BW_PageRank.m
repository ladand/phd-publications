function bv = BW_PageRank(A,c)
%%betweenness centrality based on pagerank

A = BLin_W2P(A,0);
n = size(A,1);
e0 = 1/n * ones(n,1);
[bv, realIter] = ppr_i2(A, c, e0);
