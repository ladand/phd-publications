function [M, E, N, Q, E_names, Q_names, err] = MakeSense(A,V,propFileName)

n = max(size(A));
if min(size(A)) < n
    A(n,n) = 0;
end


[F,G] = NMF_MDL_Quantized(V);

for i=1:n
    s = max(1e-5, sum(G(i,:)));
    G(i,:) = G(i,:)./s;
end

[M, E_names] = TopologicalAttrs(A);
if nargin > 2
    props = dlmread(propFileName,',',1,0);
    fid = fopen(propFileName);
    line = fgetl(fid);
    names = {};
    while ~strcmp(line, '');
        [name, line] = strtok(line, ',');
        names = [names name]; 
    end
    M = [props M];
    E_names = [names E_names];
end

E = NMF_LS_FixedG(M, G);

N = NeighborRoles(A,G);

Q = NMF_LS_FixedG(N, G);

Q_names = cell(1,size(Q,1));
for i=1:size(Q,1)
    Q_names{1,i} = sprintf('Role %d Affinity',i);
end


err = zeros(n,3);
err(:,1) = sqrt(sum((V-G*F).^2,2));
err(:,2) = sqrt(sum((M-G*E).^2,2));
err(:,3) = sqrt(sum((N-G*Q).^2,2));
