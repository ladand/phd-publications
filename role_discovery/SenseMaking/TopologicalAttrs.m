function [M, names] = TopologicalAttrs(A)

addpath('./centrality');

n = max(size(A));
if min(size(A)) < n
    A(n,n) = 0;
end

M = zeros(n, 6);
names = {'Out Degree', 'In Degree', 'Number of Neighbors', 'Weight',...
    'Clustering Coefficient',...
    'PageRank' };

cc = NodeClusteringCoefficient(A);
pr = BW_PageRank(A,0.95);

for i=1:n
    M(i,1) = nnz(A(i,:));
    M(i,2) = nnz(A(:,i));
    vs = [find(A(i,:)) (find(A(:,i)' & ~A(i,:)))];
    M(i,3) = size(vs,2);
    M(i,4) = sum(A(i,:)) + sum(A(:,i)) - A(i,i);
    M(i,5) = cc(i);
    M(i,6) = pr(i);
end


end