function c = HuffmanCost(V, symBits, posBits)


c = 0;
V = V(:);
n = size(V);
m = max(V);
counts = zeros(1,m);
for i=1:n
    counts(V(i)) = counts(V(i)) + 1;
end


q = java.util.PriorityQueue(2*m,HuffmanComparator);

costs = zeros(1, m);

for i=1:m
    q.add({counts(i), i});
end

while q.size() > 1
    u = q.poll();
    v = q.poll();
    c1 = u(1);
    a = u(2)';
    c2 = v(1);
    b = v(2)';
    
    elem = [a, b];
    for i=1:size(elem,2)
        costs(elem(i)) = costs(elem(i)) + 1;
    end
    q.add({c1+c2, elem});
end

for i=1:m
    c = c + symBits + costs(i); % cost to store codewords
end

for i=1:n
    c = c + costs(V(i)) + posBits;
end

end