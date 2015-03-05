%
% Inputs:
%  V - (node x feature) matrix
%  precBits - how many bits of precision for F and G representation
%  expBits - how many bits for the exponent in F and G representation
%  maxRoles - [optional] maximum number of roles to try
%
% Outputs:
%  F - (role x feature) matrix
%  G - (node x role) matrix
%  dLen - description length of model (bits)
%
function [F, G, dLen] = SNMF_MDL(V,precBits,expBits,maxRoles)
more off;
format short;

v = V(:);
%bits = precBits + expBits;

[n,d] = size(V);
if nargin < 4
    maxRoles = n;
end
maxRoles = min(maxRoles, n);
maxRoles = min(maxRoles, d);


%mx = max(v);
%G0 = rand(n,maxRoles)*mx;
%F0 = rand(d,maxRoles)*mx;

%maxCost = (n*d + maxRoles^2)*bits;
minLogLikelihood = -0.5*log2(exp(1))/(var(v))*sum(v.^2);
%maxDLen = max(-minLogLikelihood, maxCost);

minDLen = 1e20;

%fprintf('maxCost = %d, -minLogLikelihood = %1.0f\n', maxCost, -minLogLikelihood);

bins = precBits;
bits = log2(bins);
thresh = 1e-5;

numWorse = 0;
for numRoles = 1:maxRoles
    
    % [F,G] = NMF_LS_new(V,1000,numRoles, 0, F0(:,1:numRoles), ...
    %     G0(:,1:numRoles));
    [F,G] = nmfsh_comb(V',numRoles,[1 0.9],0);
    G = G';
    F = F';
    
    [Ft,Fi] = MaxLloyd(F, bins, thresh);
    [Gt,Gi] = MaxLloyd(G, bins, thresh);
    
%     f = Ft(:);
%     idx = find(f > 1e-10);
%     f = Fi(:);
%     f = f(idx);
%     
%     g = Gt(:);
%     idx = find(g > 1e-10);
%     g = Gi(:);
%     g = g(idx);
    
%     cost = HuffmanCost(f, bits, log2(n) + log2(numRoles)) + ...
%         HuffmanCost(g, bits, log2(d) + log2(numRoles));
    
    cost = HuffmanCost(Fi, bits, 0) + HuffmanCost(Gi, bits, 0);
    
%     mxt = truncate(1e20,precBits,expBits);
%     N = diag(mxt ./ max(max(F,[],2),1e-20));
%     F = N*F;
%     G = G*inv(N);
    
    % cost = bits*numRoles * (n + d);
    % if cost >= minDLen
    %     break
    % end
    
%     Gt = truncate(G,precBits,expBits);
%     Ft = truncate(F,precBits,expBits);
%     cost = nnz(Gt)*(bits + log2(n) + log2(numRoles)) + ...
%         nnz(Ft)*(bits + log2(d) + log2(numRoles));
    
    E = abs(V-Gt*Ft);

    err = E(:);
    logLikelihood = -0.5*log2(exp(1))/(var(v))*sum(err.^2);
    dLen = cost - logLikelihood;
    fprintf(1, ...
        'numRoles = %d, cost = %1.0f, -logLikelihood = %1.0f, dLen = %1.0f\n',...
        numRoles, cost, -logLikelihood, dLen);
    if dLen < minDLen
       minDLen = dLen;
       minF = F;
       minG = G;
       numWorse = 0;
    else
        numWorse = numWorse + 1;
        if numWorse == 5 
            break 
        end
    end
end

F = minF;
G = minG;
dLen = minDLen;
