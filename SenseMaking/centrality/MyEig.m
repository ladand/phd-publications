function [lambda, v] = MyEig(A)

Iters = 100000;

v = ones(size(A,1));

for i=1:Iters
    u = A*v;
    m = 0;
    k=-1;
    for j=1:size(u)
        if(abs(u(j) > m))
            m = abs(u(j));
            k = j;
        end
    end
    lambda = u(k) / v(k)
    u = u / (u*u');
    v = u;
end;
