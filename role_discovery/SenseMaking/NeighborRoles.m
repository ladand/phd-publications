function N = NeighborRoles(A,G)

[n,m] = size(G);

N = zeros(n,m);

for i=1:n
    vs = find(A(i,:));
    for j=1:size(vs,2)
        v = vs(j);
        for k=1:m
            N(i,k) = N(i,k) + G(v,k);
        end
    end
    N(i,:) = N(i,:)./max(1e-100,sum(N(i,:)));
end