
spec.load_or_calcualte = 'calc'; %'calc'
spec.models= {'onestate_model'};%'norm_outcome_phase04'};%'norm_outcome_quarter08'};% { 'norm_outcome_quarter08''norm_outcome_by_ind_phase_16' 'norm01','norm02', 'norm_outcome_phase04', 'norm_outcome_half04'};%, 'norm02', 'norm_outcome_phase04', 'norm_outcome_half04', 'norm_outcome_phase06'}; %'norm01', 'norm02', 'norm_outcome_phase04', 'norm_outcome_half04', 'norm_outcome_phase06', 
spec.model_names = {'onestate_model'};
spec.algorithm = 'bads'; %fminsearch or bads
spec.fit_type = 'fit';
spec.err.var = 'value'; %'gsr' or 'value' i.e. what am I fitting data to. 
spec.err.obsFnc = 'value';
spec.error_type  = 'beta-likelihood';
spec.dep_var = '';
spec.flag = '';
spec.noruns = 45;
spec.labels = {'tau_sh', 'tau_nosh', 'al0', 'be0', 'lambda'};
limits =[0 2; 0 2; 1 10; 1 10; log(0.001) log(0.999)];
spec.limits = limits;
