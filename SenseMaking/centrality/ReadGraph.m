function A = ReadGraph(s)

A = dlmread(s); 
A(:,3)=1;
A=spconvert(A);
[m, n] = size(A);
p = max(m,n);
if m ~=n, A(p,p) = 0; end