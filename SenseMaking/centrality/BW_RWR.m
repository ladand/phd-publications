function bv = BW_RWR(A,c)

%%%betweenness centrality based on random walk with restart
%%%c: (1-c) is the restart prob

[Q1,U,V,Lam] = BLin_Pre(A);

n = size(A, 1);
bv = zeros(n, 1);

for i=1:n
    if mod(i, 100) == 0, fprintf(1,'%d\n', i);end;
    bv(:,1) = bv(:,1) + BLin_OQ(Q1,U,V,Lam,c,i);
end