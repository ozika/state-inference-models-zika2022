function[err,L] = calculate_err(pred, prob, type, spec)
L = [];
if strcmp(type, 'least_squares')
    L = (pred(:) - prob(:)).^2;
    err = sum(L);
   
elseif strcmp(type, 'likelihood')
    L =[];
    for i = 1:length(pred)
        L(i) = -log(normpdf(prob(i), pred(i), 0.2));
    end
    err = sum(L);
elseif strcmp(type, 'beta-likelihood')
    L = [];
    if ~isfield(spec.out, 's')
        spec.out.s = repmat(1,1,max(spec.valid));
    end
    if size(spec.out.al,1)==1
        spec.out.al = spec.out.al';
        spec.out.be = spec.out.be';
    end
    l=1;
    % this is super-confusing. spec.valid holds all the valid trials that
    % don't contain NaN, but at the same time externally L needs to have
    % one field for trial, that's why I introduced the double indexing here
    % i is the tru index of the trial
    % l is just a dummy index
    L = repmat(NaN,1,max(spec.valid));
    for i = spec.valid
        L(i) = -log(0.0001 + betapdf(prob(l), spec.out.al(i,spec.out.s(i)), spec.out.be(i,spec.out.s(i))));
        l = l+1;
    end
    err = sum(L(spec.valid));

elseif strcmp(type, 'pri_and_liklhd')
        logp =[];
        pd =[];%probability density
        for i = 1:numel(spec.pr.type) %loop over all parameters
            if strcmp(spec.pr.type{i}, 'beta')
                n = betacdf([spec.limits(i,1) spec.limits(i,2)], spec.pr.alpha(i), spec.pr.beta(i));
                norm = n(2) - n(1);
                mu = spec.pr.alpha(i) / (spec.pr.alpha(i) + spec.pr.beta(i));
                pd(i) = betapdf(mu, spec.pr.alpha(i), spec.pr.beta(i));
                logp(i) = log(pd(i) / norm);
            elseif strcmp(spec.pr.type{i}, 'norm')
                n = normcdf([spec.limits(i,1) spec.limits(i,2)], spec.pr.mu(i), spec.pr.sigm(i));
                norm = n(2) - n(1);
                pd(i) = normpdf(spec.pr.mu(i), spec.pr.mu(i), spec.pr.sigm(i));
                logp(i) = log(pd(i) / norm);
            elseif strcmp(spec.pr.type{i}, 'flat')
                logp(i) = log(spec.limits(i,2) - spec.limits(i,1));
            end
        end

        %calculate log likelihood
       loglik =[];
        for i = 1:length(pred)
            loglik(i) = log(normpdf(prob(i), pred(i), 0.2)); %0.2 is an arbitrary value
        end

        %combine prior and likelihood
        err = sum(loglik) + sum(logp);
    
end
