function[out] = onestate_model(varargin)
p = varargin{1};
o = varargin{2};


if strcmp(class(p), 'double')
    input = p;
    p = [];
    p.tau_sh    = input(1);
    p.tau_nosh  = input(2);
    p.al0       = input(3);
    p.be0       = input(4);
    p.lambda      = input(5);
end
p.lambda = exp(p.lambda);
al = p.al0;
be = p.be0;

vals = 0.:0.01:1;

Q=[]; U=[];
for i = 1:numel(o)
    
    
    Q(i) = (al(i) - 1) / (al(i) + be(i) -2); 
    U(i) = sqrt(al(i)*be(i) / (( (al(i) + be(i))^2  ) * (al(i) + be(i) + 1) ) );% state uncertainty
    
    if o(i) == 0
        be(i+1) = p.lambda*(be(i)+p.tau_nosh); %offset p and beta by an amount for shock and no-shock
        al(i+1) = p.lambda*al(i);
        
    elseif o(i) == 1
        al(i+1) = p.lambda*(al(i)+p.tau_sh);
        be(i+1) = p.lambda*be(i);
    end
    
    % Keep above 1 for model calculation
    if al(i+1) <= 1
       al(i+1) = 1.01; 
    end
    if be(i+1) <= 1
       be(i+1) = 1.01;
    end
    
     if (al(i+1)+be(i+1)) > 30
        sm = (al(i+1)+be(i+1));
        al(i+1) = 30*al(i+1)/sm;
        be(i+1) = 30*be(i+1)/sm;
    end

end
out.U = U;
out.Q = [Q NaN]; % adding the nan here because fitter expects the model to make a last prediction 
out.al = al;
out.be = be;