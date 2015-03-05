%
% Inputs:
%  V - (node x feature) matrix
%  maxRoles - [optional] maximum number of roles to try
%
% Outputs:
%  F - (role x feature) matrix
%  G - (node x role) matrix
%  AIC - Akaike Information Criterion 
%   (normalized by max possible value for V)
%
function [F, G, AIC] = NMF_AIC(V, maxRoles)
more off;
format short;

v = V(:);


mx = max(max(V));
[n,d] = size(V);
if nargin < 2
    maxRoles = n;
end
maxRoles = min(maxRoles, n);
maxRoles = min(maxRoles, d);

G0 = rand(n,maxRoles)*mx;
F0 = rand(d,maxRoles)*mx;

maxCost = n*d + maxRoles^2;
minLogLikelihood = -0.5/(var(v))*sum(v.^2);
maxAIC = max(-minLogLikelihood, maxCost);

minAIC = maxAIC;

fprintf('maxCost = %d, -minLogLikelihood = %1.0f\n', maxCost, -minLogLikelihood);

numWorse = 0;
for numRoles = 1:maxRoles
    cost = numRoles * (n + d);
    if cost >= minAIC
        break
    end
    [F,G] = NMF_LS_new(V,1000,numRoles, 0, F0(:,1:numRoles), ...
        G0(:,1:numRoles));
    E = abs(V-G*F);

    err = E(:);
    logLikelihood = -0.5/(var(v))*sum(err.^2);
    AIC = cost - logLikelihood;
    fprintf(1, ...
        'numRoles = %d, cost = %1.0f, -logLikelihood = %1.0f, AIC/maxAIC = %1.8f\n',...
        numRoles, cost, -logLikelihood, AIC/maxAIC);
    if AIC < minAIC
       minAIC = AIC;
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
AIC = minAIC/maxAIC;
