function cc = nodeClusteringCoefficient(G)

undirected = 1;
for i=1:size(G,1)
    for j=find(G(i,:))
        if G(i,j) ~= G(j,i)
            undirected = 0;
            break;
        end
    end
    if ~undirected
        break;
    end
end

n = size(G,1);

cc = zeros(n,1);
den = zeros(n,1);

for i=1:n
    if ~mod(i,1000);disp(i);end;
    if undirected
        es = find(G(i,:));
        m = size(es,2);
        for j=1:m-1
            for k=j+1:m
                den(i,1) = den(i,1) + 1.0;
                if(G(es(j),es(k)) ~= 0)
                    cc(i,1) = cc(i,1) + 1.0;
                    %disp([i es(j) es(k)]);
                end
            end
        end
    else
        es = [find(G(i,:)) find(G(:,i)' & ~G(i,:))];
        m = size(es,2);
        for j=1:m-1
            for k=j+1:m
                den(i,1) = den(i,1) + 2;
                if(G(es(j),es(k)) ~= 0)
                    cc(i,1) = cc(i,1) + 1.0;
                end
                if(G(es(k),es(j)) ~= 0)
                    cc(i,1) = cc(i,1) + 1.0;
                end
            end
        end
    end
    if(den(i,1) > 0)
        cc(i,1) = cc(i,1)/den(i,1);
    end
end

