function[out] = nstate_model(p, o, cfg)
%% n-state model from Zika2022
% https://www.biorxiv.org/content/10.1101/2022.04.01.483303v2 
% Author: Ondrej Zika

%% Setup
% Inferring new state follows Chinese Restaurant Process with alpha=0.25 and theta=1
% These are pre-generated to save time, but in som cases it can be useful
% to fit them. 
crp_difficulty =[1.0000    2.7178    7.2931   15.0321   26.8599   46.3074   67.4356 87.0547  122.3690  153.2690  204.7690];

% if the input of p is a double, make it to struct for easier legibility 
if strcmp(class(p), 'double')
    input = p;
    p = [];
    p.tau_sh    = input(1); 
    p.tau_nosh  = input(2); 
    p.eta       = input(3); 
    p.al0       = input(4); 
    p.be0       = input(5); 
    p.lambda    = input(6);
end

% the surprise weight (pi) and labmda (state memory decay) are fixed
% restricting the two parameters enabled increased idenifiability of the
% eta parameter
p.pi = 0.3;  
p.lambda = exp(p.lambda); % Fitting in log space

% starting values of alpha and beta
al = [p.al0, 1];
be = [p.be0, 1];
s=1;

Q=[];Q=[];E=[];S=[]; ETA =[];

%% Model: loop over trials

for i = 1:numel(o)
    create_new = 0;
    
    %Based on current p and beta, update all states Q and sigm
     os = unique(s);
    for ot = 1:numel(os)
        al(i+1, os(ot)) = al(i, os(ot)); %pre-create
        be(i+1, os(ot)) = be(i, os(ot)); % pre-create
        
        % calculate the mode of the current state
        Q(i, os(ot)) = (al(i,os(ot)) - 1) / ( al(i,os(ot)) + be(i,os(ot))  - 2); % note that this crashes if al/be are 1 or smaller
        
        % calculate the uncertainty of the current state
        sigm(i, os(ot)) = sqrt( al(i,os(ot))*be(i,os(ot)) ./  (((al(i,os(ot))+be(i,os(ot))).^2)*(al(i,os(ot))+be(i,os(ot))+1) ));
        
        %calculate level of surprise experienced in this state   
        if i ==1 || isnan(S(i-1, os(ot)))
            S(i,os(ot)) = 0 + p.pi*abs((o(i) - Q(i, os(ot))));
        else
            S(i,os(ot)) = (1-p.pi)*S(i-1, os(ot)) + p.pi*abs((o(i) - Q(i, os(ot))));
        end
        
        %% get expectation and make sure the new state is in boundaries 
        if o(i) == 1
            E(i, os(ot)) = Q(i, os(ot)) + S(i,os(ot));
            if E(i, os(ot)) > 1; E(i, os(ot))=0.999; end
        elseif o(i) == 0
            E(i, os(ot)) = Q(i, os(ot)) - S(i,os(ot));
            if E(i, os(ot)) < 0; E(i, os(ot))=0.001; end
        end
      
        
    end

    
    
    
    %% Evaluate current state, 

    % Is the surprise outside of the bounds of the standard threshold 
    if abs(S(i,s(i))) >= (sigm(i, s(i))*p.eta) &&  abs(S(i,s(i))) < (sigm(i, s(i))*p.eta*crp_difficulty(max(s)))%

            cand = unique(s);
            pr=[];
            % loop over states and choose the most likely state
            for q = 1:numel(cand)
                pr(q) = betapdf(E(i, cand(q)), al(i, cand(q)), be(i, cand(q)));
            end
            ma_id = find(max(pr)==pr);
            s(i+1) = cand(ma_id(1)); %most likely state


    % Is the surprise exceeding even the extended threshold           
    elseif  abs(S(i,s(i))) >= (sigm(i, s(i))*p.eta*crp_difficulty(max(s))) 
            states = unique(s);
            for t = states
                    %is there a candidate state +/- 
                    m(t) = inrange(E(i,s(i)), Q(i,t)-(sigm(i,t)*p.eta), Q(i,t)+(sigm(i, t)*p.eta) ) ;
            end

            if sum(m) < 1 %none, create new
                create_new = 1;
            else
                cand = unique(s);
                pr=[];
                for q = 1:numel(cand)
                   pr(q) = betapdf(E(i, cand(q)), al(i, cand(q)), be(i, cand(q)));
                end
                ma_id = find(max(pr)==pr);
                s(i+1) = cand(ma_id(1)); %most likely state

             end
    elseif abs(S(i,s(i))) <= (sigm(i, s(i))*p.eta)
             %stays the same
            s(i+1) = s(i);
    end


    % Creating a new state (if determined as necessary above
    % Use expected mean (previous mean + surprise)
    % Uncertainty is determined by rearranging al0 and be0 into sd (as
    % descibed in the paper) 
    if create_new == 1
        s(i+1) = max(s) + 1;
        [Q(1:i,s(i+1)), S(1:i,s(i+1)), al(1:i,s(i+1)),be(1:i,s(i+1)),sigm(1:i, s(i+1)), sigma, mu]  = deal([NaN]);
        [mu, Q(i, s(i+1))] = deal(E(i, s(i)));
        [sigma, sigm(i+1, s(i+1))] = deal(sigm(1, 1));%       
        [al(i+1,s(i+1)), be(i+1, s(i+1)), ~, ~] = beta_ms2ab(mu, sigma);
    else
        %learn towards state 
        if o(i) == 0     
            be(i+1, s(i+1)) = p.lambda*(be(i, s(i+1)) + p.tau_nosh );
            al(i+1, s(i+1)) = p.lambda*(al(i, s(i+1)) ) ;
        elseif o(i) == 1
            al(i+1, s(i+1)) = p.lambda*(al(i, s(i+1)) + p.tau_sh );
            be(i+1, s(i+1)) = p.lambda*(be(i, s(i+1))) ;
        end

    end
        
    if al(i+1, s(i+1)) <= 1
        al(i+1, s(i+1)) = 1.01;
    end
    if be(i+1, s(i+1)) <= 1
        be(i+1, s(i+1)) = 1.01;
    end
    
    % Keep uncertainty at al+be=30
    upper_certainty = 30;    
    sump = []; sump = al(i+1, s(i+1))+be(i+1, s(i+1));
    if sump > upper_certainty % prevents states from becoming too certain
        factor = [];
        factor = upper_certainty/sump;
        al(i+1, s(i+1)) = factor*al(i+1, s(i+1));
        be(i+1, s(i+1)) = factor*be(i+1, s(i+1));
    end
    Scur(i) = sigm(i,s(i));
    Qcur(i) = Q(i,s(i));
   
    %decay and adjust all non-current states
    states =[]; states = setdiff(unique(s),s(i+1));
    if ~isempty(states)
        for st = 1:numel(states)
            al(i+1,states(st)) = p.lambda*al(i, states(st));
            be(i+1,states(st)) = p.lambda*be(i, states(st));
            if al(i+1, states(st)) <= 1
                al(i+1, states(st)) = 1.01;
            end
            if be(i+1, states(st)) <= 1
                be(i+1, states(st)) = 1.01;
            end
        end
    end
end

out.Qs = Q;
out.Qs2 = Q;
out.E = E;
out.Q =[Qcur NaN]; %add a line - most other models produce an additional prediction 
out.sigm =sigm;
out.U =Scur;
out.al = al;
out.be = be;
out.S = S;
out.s = s;
