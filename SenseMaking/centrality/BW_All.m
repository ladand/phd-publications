function [bv,idx] = BW_All(A)

%%%%compute betweenness centrality, using different metrics
c = 0.95;
%%%find the largest connected component
% cv = BW_ConnectComp(A);
% n0 = max(cv);
% for i=1:n0
%     len(i) = length(find(cv==i));
% end
% i0 = find(len==max(len));
% i0 = i0(1);
% 
% idx = find(cv==i0);
% A0 = A(idx,idx);

A0 = A;
idx = 1:size(A,1);

%%work on this largest connected component

fprintf(1, 'degree\n');
%%degree
bv(:,1) = sum(A0+A0',2);

fprintf(1, 'path\n');

%%shortest path
%bv(:,2) = BW_FastSP(A0);
bv(:,2) = 1;

fprintf(1, 'rw\n');
%%Newman's R.W.
%bv(:,3) = BW_RandWalk(A0);
bv(:,3) = 0;
bv(1,3) = 1;

fprintf(1, 'rwr\n');
%%RWR
bv(:,4) = BW_RWR(A0,c);

fprintf(1, 'pr\n');
%%PageRank
bv(:,5) = BW_PageRank(A0,c);


fprintf(1, 'lam1\n');
%%delta lambda_1
%bv(:,6) = BW_Eigs(A0);

fprintf(1, 'lam2\n');
%%2nd eigen-vector
%bv(:,7) = BW_EigVec(A0);

