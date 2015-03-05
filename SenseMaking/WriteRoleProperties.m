function WriteRoleProperties(M,E,names,outfile)

G_one = ones(size(M,1),1);
E_one = NMF_LS_FixedG(M,G_one);


header = StringJoin(names, ',', '%s');


out = fopen(outfile, 'w');
fprintf(out, ',%s\n', header);
fprintf(out, 'Default,%s\n', StringJoin(E_one./E_one, ',', '%f'));
for role=1:size(E,1)
   %out = 1;
   fprintf(out, 'Role %d,%s\n', role, StringJoin(E(role,:)./E_one, ',', '%f'));
   
   
end

end