A = dlmread('data/dblp_graph.e');A(:,3)=1;A=spconvert(A);
[bv, idx] = BW_All(A);

out = fopen('data/centrality_dblp.txt', 'w');
for i=1:length(bv)
 fprintf(out, '%d %f %f %f %f %f\n', i, bv(i,1), bv(i, 2), bv(i, 3), bv(i, 4), bv(i, 5)); 
end

quit
