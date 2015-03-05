%
% Inputs:
%  V - (node x feature) matrix
%  precBits - how many bits of precision for F and G representation - smaller numbers give more roles - use 4 as default
%  expBits - how many bits for the exponent in F and G representation - smaller numbers give more roles - use 4 as default 
%  maxRoles - [optional] maximum number of roles to try
%
% Outputs:
%  F - (role x feature) matrix
%  G - (node x role) matrix
%  dLen - description length of model (bits)
%
function [F, G, dLen] = NMF_MDL(V,precBits,expBits,maxRoles)
more off;
format short;

v = V(:);
bits = precBits + expBits;

mx = max(max(V));
[n,d] = size(V);
if nargin < 4
    maxRoles = n;
end
maxRoles = min(maxRoles, n);
maxRoles = min(maxRoles, d);

G0 = rand(n,maxRoles)*mx;
F0 = rand(d,maxRoles)*mx;

maxCost = (n*d + maxRoles^2)*bits;
minLogLikelihood = -0.5/(var(v))*sum(v.^2);
maxDLen = max(-minLogLikelihood, maxCost);

minDLen = maxDLen;

fprintf('maxCost = %d, -minLogLikelihood = %1.0f\n', maxCost, -minLogLikelihood);

numWorse = 0;
for numRoles = 1:maxRoles
    cost = bits*numRoles * (n + d);
    if cost >= minDLen
        break
    end
    [F,G] = NMF_LS_new(V,1000,numRoles, 0, F0(:,1:numRoles), ...
        G0(:,1:numRoles));
    E = abs(V-truncate(G,precBits,expBits)*truncate(F,precBits,expBits));

    err = E(:);
    logLikelihood = -0.5/(var(v))*sum(err.^2);
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
