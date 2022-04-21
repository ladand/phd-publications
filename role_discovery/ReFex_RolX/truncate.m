function y = truncate(x, precBits, expBits)

xx = x(:);
y = zeros(size(xx));

maxExp = 2^(expBits-1);

maxVal = 1;
for i=1:precBits
    maxVal = maxVal + 2^(-i);
end
maxVal = maxVal * maxExp;

for i=1:size(xx)
    if (x(i) == 0 || log2(x(i)) < -(maxExp+1))
        y(i) = 0;
    elseif (log2(x(i)) < -maxExp)
        y(i) = 2^-maxExp;
    elseif x(i) >= maxVal
        y(i) = maxVal;
    else
        e = floor(log2(x(i)));
        b = x(i)/(2^e);
        t = floor(b*(2^precBits))/(2^precBits);
        y(i) = t*(2^e);
    end
end

y = reshape(y, size(x));