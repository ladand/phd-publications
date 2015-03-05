function bv = BW_RandWalk(A)

%%%compute the betweenness centrality vector
%%%using Newman's metric based on random walk
%%%for median size graph
% % % 
% % % A = sparse(8,8);
% % % A(1:3,1:3)=1;A(5:8,5:8)=1;A(2,4)=1;A(4,2)=1;A(4,5)=1;A(5,4)=1;
% % % bv = BW_RandWalk(A)

D = diag(sum(A,2));
n = size(A,1);
S = D(1:n-1,1:n-1) - A(1:n-1,1:n-1);
%voltage matrix
T = inv(S);
T(n,n) = 0;
T = full(T);
A0 = A';
%A = full(A);
bv = zeros(n,1);
if 1
for j = 1:1000
        s = randI(n-1);
        t = s + randI(n-s);
        
        if mod(j, 100) == 0, fprintf(1, '%d: %d %d\n', j, s, t); end;
%         tic
        v = T(:,s) - T(:,t);
%         v = T(:,s) - T(:,t);
%         X = repmat(v,1,n);
%         Y = repmat(v',n,1);
%         Z = abs(Y-X);
%         
%         Z(:,[s,t]) = 0;
%         bv = bv + diag(A * Z)/2;
        for i=1:n
            if i~=s & i~=t
                v0 = v;
                v0 = abs(v(i) - v);
%             v0([s,t],1) = 0;
%             bv(i) = bv(i) + A0(:,i)' * Z(:,i) /2;
                bv(i) = bv(i) + A0(:,i)' * v0 /2;
            end
        end
       
%                
end

else %%%for debug
for s=1:n-1%for source s
    for t=s+1:n%targe t
        for i=1:n
            Isti = 0;
            if i~=s & i~=t
                %%compute the current that pass node i
                for j=1:n
                    Isti = Isti + A(i,j) * abs(T(i,s) - T(i,t) - T(j,s) + T(j,t));
                end
                bv(i) = bv(i) + Isti/2;
            end
        end
    end
end
end
bv = bv/2/n/(n-1);
