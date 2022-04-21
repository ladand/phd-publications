function [dist,pre,path] = BW_Dijkstra(A,s,m)

%%%compute the shortest path from source s, 
%%%A is the affinity matrix
%%%dist = 1/A(i,j)

% A = sparse(5,5);
% A(1,2)=1;A(2,1)=1;
% A(2,3)=1;A(3,2)=1;A(1,3)= 1/3;A(3,1) = 1/3;A(3,4) = 2;A(4,3)=2;A(4,5)=2;A(5,4)=2;A(2,5)=1/5;A(5,2)=1/5;
%A(6,6) = 0;
% [dist,pre,path] = BW_Dijkstra(A,1);
% for i=1:size(A,1)
% disp(path{i})
% end

if nargin < 3, m = size(A, 1); end;

A = A';

%initialization
n = size(A, 1);
dist = inf * ones(n,1);%dist vector
dist(s) = 0;
pre = -1 * ones(n,1);%previous nodes vector
Q = (1:n)';
vist = zeros(n,1);%wheter or not visited

k = 1;
j = 2;
Q(k) = s;


while k < j && j <= m;
    %fprintf(1, '%d %d\n', k, j);
    %pos = find(dist(Q)==min(dist(Q)));
    %u = Q(pos(1));
    u = Q(k);
    k = k + 1;
    %remove u
    %Q = setdiff(Q,u);
    vist(u) = 1;
    v_all = find(A(:,u));
    for i=1:length(v_all)
        if ~vist(v_all(i))%has not visited
            alt = dist(u) + 1/A(u,v_all(i));
            if alt < dist(v_all(i))
                dist(v_all(i)) = alt;
                pre(v_all(i)) = u;
                Q(j) = v_all(i);
                j = j + 1;
            end
        end
    end
end

if nargout>2
%%read out the path, not including the target node
for i=1:n
    if i==s
        path{i} = [s];
    else
        path0 = [];
        u = i;
        while pre(u)>0
            path0 = [pre(u) path0];
            u = pre(u);
        end
        if u~=s%no shortest path from s
            path0 = -1;                  
        end
        path{i} = path0;
        
    end
end
end