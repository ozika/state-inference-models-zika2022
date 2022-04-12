function[err] = model_error(alpha, outcomes, probabilities, cfg, cue)


[out] = feval(cfg.spec.model_names{1},alpha, outcomes, cfg);

if strcmp(cfg.spec.err.var, 'value')
    data = cfg.spec.data.probs;
    data(data==0) = 0.001;
elseif strcmp(cfg.spec.err.var, 'gsr')
    data = cfg.spec.data.gsr_ampl;
    mi = min(data);
    ma = max(data);
    data =  (data - mi) ./ (ma - mi); %rescale to 0-1
end

if strcmp(cfg.spec.err.obsFnc, 'value')
    prediction = out.Q;
elseif strcmp(cfg.spec.err.obsFnc, 'assoc') %associability
    prediction = out.L;
end
%EXCLUDE THE LAST PREDICTION TO MAKE the amount of probabilities same
%across models
prediction(length(prediction)) = []; 
%probabilities(length(probabilities)) = [];
%prediction(1) =[]; %
%data(1) = [];
A =[];
A(:,1) = prediction;
A(:,2) = data;
valid = find(all(~isnan(A),2))';


if strcmp(cfg.spec.algorithm, 'vbmc')
    cfg.spec.error_type = 'pri_and_liklhd';
end

if ~isempty(valid)
    cfg.spec.out = out;
    cfg.spec.valid =   valid;
    [err,LL] = calculate_err(A(valid,1), A(valid,2), cfg.spec.error_type, cfg.spec);
   % err = sum((A(r,1) - A(r,2)).^2);
else
    err = NaN;
end
 if isnan(err) || isinf(err)
        disp(['Model diverged, assigning high maual error\n']);
        err = 9999;
    end

