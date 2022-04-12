
spec.load_or_calcualte = 'calc'; %'calc'
spec.models= {'nstate_model'};%'norm_outcome_phase04'};%'norm_outcome_quarter08'};% { 'norm_outcome_quarter08''norm_outcome_by_ind_phase_16' 'norm01','norm02', 'norm_outcome_phase04', 'norm_outcome_half04'};%, 'norm02', 'norm_outcome_phase04', 'norm_outcome_half04', 'norm_outcome_phase06'}; %'norm01', 'norm02', 'norm_outcome_phase04', 'norm_outcome_half04', 'norm_outcome_phase06', 
spec.model_names = {'nstate_model'};
spec.algorithm = 'bads'; %fminsearch or bads
spec.fit_type = 'fit';
spec.err.var = 'value'; %'gsr' or 'value' i.e. what am I fitting data to. 
spec.err.obsFnc = 'value';
spec.error_type  = 'beta-likelihood';
spec.dep_var = '';
spec.flag = '';
spec.noruns = 5;
spec.labels = {'tau_sh', 'tau_nosh', 'eta', 'al0', 'be0', 'lambda'};
spec.limits =[0 0.2; 0 0.2; 1 10; 1 10; 1 10; log(0.0001) log(0.9999)];

cfg.spec = spec;



