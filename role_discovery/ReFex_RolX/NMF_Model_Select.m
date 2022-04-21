%
% Inputs:
%  V - (node x feature) matrix
%  criterion - "AIC" or "MDL" for model selection criterion
%  lossFun - "KL" or "Fro" for error/loss function
%  bins - [optional] number of quantization bins (default=log2(n))
%  maxRoles - [optional] maximum number of roles to try
%
% Outputs:
%  F - (role x feature) matrix
%  G - (node x role) matrix
%  dLen - description length of model (bits)
%
function [F, G, dLen] = NMF_Model_Select(V, criterion, lossFun, bins,maxRoles)
more off;
format short;

v = V(:);

mx = max(v);
[n,d] = size(V);
if nargin < 4
    bins = log2(n);
end
if nargin < 5
    maxRoles = n;
end
maxRoles = min(maxRoles, n);
maxRoles = min(maxRoles, d);

G0 = rand(n,maxRoles)*mx;
F0 = rand(d,maxRoles)*mx;


minDLen = 1e20;


bits = log2(bins);
thresh = 1e-5;

numWorse = 0;

lens = [];

for numRoles = 1:maxRoles
    [F,G] = NMF_LS_new(V,1000,numRoles, 0, F0(:,1:numRoles), ...
        G0(:,1:numRoles));
        
    
    if strcmp(criterion, 'AIC')
        descCost = 2*numRoles*(n + d);
        GF = G*F; % AIC no need to quantize
        E = V-GF;
        scale = 2*log(2); % For KL only -- adjusting for log base
    else % MDL
        [Ft,Fi] = MaxLloyd(F, bins, thresh);
        [Gt,Gi] = MaxLloyd(G, bins, thresh);
        descCost = HuffmanCost(Fi, bits, 0) + HuffmanCost(Gi, bits, 0);
        GF = Gt*Ft; % MDL need to quantize
        E = V-GF;
        scale = 1; % For KL only -- adjusting for log base
    end

    
    if strcmp(lossFun, 'KL') % KL Divergence
        loss = 0;
        for i=1:n
            for j=1:d
                if (V(i,j) < 1e-10 || GF(i,j) < 1e-10) continue; end;
                loss = loss + V(i,j)*log2(V(i,j)/GF(i,j))-V(i,j)+GF(i,j);
            end
        end
        errCost = loss*scale; % Adjust for AIC natural base
    else % Frobenius Norm
        err = E(:);
        sig2 = var(err);
        fro2 = sum(err.^2);
        
        % Adjust for MDL Base 2
        if strcmp(criterion, 'AIC')
            errCost = fro2/sig2 + n*d*log(sig2*2*pi);
            if errCost < 0
	        return;
            end
        else   
            errCost = 0.5*(log2(exp(1))/(sig2)*fro2 + n*d*(log(sig2*2*pi)));
        end
    end
    dLen = descCost + errCost;

    
    lens(numRoles) = dLen;
    plot(lens);
    
    fprintf(1, ...
        'numRoles = %d, desc cost = %1.0f, error cost = %1.0f, dLen = %1.0f\n',...
        numRoles, descCost, errCost, dLen);
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
