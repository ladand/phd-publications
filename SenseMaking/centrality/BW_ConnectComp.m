function cv = BW_ConnectComp(A)

%%%output the connected component vector

[n] = size(A,1);
A = BLin_W2P(A,0);
n = size(A,1);

cv = zeros(n,1);

v = zeros(n,1);
cnt = 1;
flag = 1;
while flag==1
   
    pos = find(v==0);
    if isempty(pos)
        flag = 0;
    else
        i0 = pos(1);
        e0 = sparse(n,1);
        e0(i0) = 1;
        [r, realIter] = ppr_i2(A, .95, e0);
        
        idx = find(r);
        v(idx) = 1;
        cv(idx) = cnt;
        cnt = cnt + 1;
    end
end