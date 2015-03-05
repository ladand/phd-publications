function bv = BW_Eigs(A,flag)

%%%betweenness centrality by delta lambda_1
if nargin<2
    flag=1;
end
opts.disp = 0;
sig1 = eigs(A,1,'LM',opts);
n = size(A,1);

if flag==1%naive search
    for i=1:n
        if mod(i, 100) == 0, fprintf(1,'%d\n', i);end;
        A0 = A;
        A0(i,:) = 0;
        A0(:,i) = 0;
        sig0 = eigs(A0,1,'LM',opts);
        bv(i,1) = sig1 - sig0;
    end
elseif flag==2%using sqrt(2) bound
    deg = sum(A,2);
    [deg0,I] = sort(deg,1,'descend');%%%    
    i0 = I(1);%start with high
    A0 = A;    
    A0(i0,:) = 0;
    A0(:,i0) = 0;
    sig0 = eigs(A0,1,'LM',opts);
    bv(i0,1) = sig1 - sig0;
end