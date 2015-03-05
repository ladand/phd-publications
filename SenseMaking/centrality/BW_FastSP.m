function bv = BW_FastSP(A)

n = size(A, 1);
bv = zeros(n, 1);

for s = 1:n
   if mod(s,100) == 0
       fprintf(1, '%d\n', s);
   end
   S = zeros(n, 1);
   Si = 1;
   P = cell(n, 1);
   sigma = zeros(n, 1);
   sigma(s) = 1;
   d = -1 * ones(n, 1);
   d(s) = 0;
   Q = zeros(n, 1);
   Qs = 1;
   Qe = 2;
   Q(1) = s;
   while Qs < Qe
      v = Q(Qs);
      Qs = Qs + 1;
      S(Si) = v;
      Si = Si + 1;
      ns = find(A(v,:));
      for wi = 1:size(ns, 2);
          w = ns(1, wi);
          if d(w) < 0
              Q(Qe) = w;
              Qe = Qe + 1;
              d(w) = d(v) + 1;
          end
          if d(w) == d(v) + 1
            sigma(w) = sigma(w) + sigma(v);
            %first = P{w}
            P{w}(size(P{w},2) + 1) = v;
            %second = P{w}
          end
      end
   end
   
   
   delta = zeros(n,1);
   while Si > 1
       Si = Si - 1;
       w = S(Si);
       for i=1:size(P{w},2)
           v = P{w}(i);
           delta(v) = delta(v) + (sigma(v)/sigma(w)) * (1 - delta(w));
           if w ~= s
               bv(w) = bv(w) + delta(w);
           end
       end
   end
   
   
end
