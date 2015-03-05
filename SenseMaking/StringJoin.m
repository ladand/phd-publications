function s = StringJoin(args, delim, format)

args = args(:);

n = size(args,1);
if n == 0
    s = '';
    return;
end

if iscell(args)
    s = sprintf(format,args{1});
    if n == 1
        return;
    end


    for i=2:n
        s = strcat(s, delim, sprintf(format, args{i}));
    end
else
    s = sprintf(format,args(1));
    if n == 1
        return;
    end


    for i=2:n
        s = strcat(s, delim, sprintf(format, args(i)));
    end
end
