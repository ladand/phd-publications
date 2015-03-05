function bv = BW_EigVec(A)

%%%look at the 2nd eig vector of normalized graph laplacian

A = BLin_W2P(A,1);
A = (A + A') * 0.5;
opts.disp = 0;
[u,s] = eigs(A,2,'LM',opts);

v = u(:,2);
v = max(v,-1);
v = min(v,1);
bv =  1 - abs(v);