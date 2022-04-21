function bv = BW_ShortPath(A)


%%%compute the betweenness centrality based on shortest path
%%%suitable for median size graph
%%%not consider the dupliate of shortest path
% 
% A = sparse(8,8);
% A(1:3,1:3)=1;A(5:8,5:8)=1;A(2,4)=1;A(4,2)=1;A(4,5)=1;A(5,4)=1;
% bv = BW_ShortPath(A)

n = size(A,1);
bv = zeros(n,1);
m = n;
for i=1:n
    if mod(i, 1) == 0, fprintf(1, '%d\n', i); end;
    %shortest path from i to the remaining
    [dist,pre,path] = BW_Dijkstra(A,i,m);
    for j=1:n
        bv(path{j}(2:end)) = bv(path{j}(2:end)) + 1;
    end
end
bv = bv;