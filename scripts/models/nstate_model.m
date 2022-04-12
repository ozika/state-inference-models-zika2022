function[out] = nstate_model(p, o, cfg)
%% Beta state switcher model 
%This model is develped to infer hidden belief states based on patterns in
%binary outcomes.

% The fibonnaci sequence is used as increasing threshold for new state creation - we wanted it fixed across participants, it can be replaced by an exponential distribution 
%fib = [1     1     2     3     5     8    13    21    34    55 89         144         233         377         610 987 1597 2584 4181 6765];

% Chinese restaurant process with alpha=0 and theta=1
%crp_difficulty = [2.02633629895039,3.94871794871795,7.82795698924731,16.1036036036036,27.9374825565169,64.5598194130925,143.615494978479,350,800.800000000000,1711.11111111111,3707.40740740741,10010,16683.3333333333,40040,100100];
% Chinese restaurant process with alpha=0.25 and theta=1
% started at 1
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
p.lambda = exp(p.lambda);

anchor=1;

al = [p.al0, 1];
be = [p.be0, 1];
s=1;

Q=[];Q2=[];
E=[];
S=[];    
ETA =[];
x=0:0.001:1;
for i = 1:numel(o)
    create_new = 0;
    %Based on current p and beta, update all states Q and sigm
     os = unique(s);
    for ot = 1:numel(os)
        al(i+1, os(ot)) = al(i, os(ot)); %pre-create
        be(i+1, os(ot)) = be(i, os(ot)); % pre-create
        
        
        %%% old Q calculation
        y=[];
        y=betapdf(x,  al(i,os(ot)), be(i,os(ot)));
        Q(i, os(ot)) = mean(x(find(y==max(y))));
        
        %%% new Q calculation 
        Q2(i, os(ot)) = (al(i,os(ot)) - 1) / ( al(i,os(ot)) + be(i,os(ot))  - 2);

        sigm(i, os(ot)) = sqrt( al(i,os(ot))*be(i,os(ot)) ./  (((al(i,os(ot))+be(i,os(ot))).^2)*(al(i,os(ot))+be(i,os(ot))+1) ));
        %calculate level of surprise experienced in this state using Q(i)
    
        if i ==1 || isnan(S(i-1, os(ot)))
            S(i,os(ot)) = 0 + p.pi*abs((o(i) - Q(i, os(ot))));
        else
            S(i,os(ot)) = (1-p.pi)*S(i-1, os(ot)) + p.pi*abs((o(i) - Q(i, os(ot))));
        end
        %E(i, os(ot)) = Q(i, os(ot)) + p.kappa*S(i,os(ot))*(o(i) - Q(i, os(ot)));
        
        
        
        %% get expectation and make sure the new state is in boundaries 
        if o(i) == 1
            E(i, os(ot)) = Q(i, os(ot)) + S(i,os(ot));
            if E(i, os(ot)) > 1; E(i, os(ot))=0.999; end
        elseif o(i) == 0
            E(i, os(ot)) = Q(i, os(ot)) - S(i,os(ot));
            if E(i, os(ot)) < 0; E(i, os(ot))=0.001; end
        end
      
        
    end

    
    
    
     %if surprise is ouside of the bounds of current state but not extreme
     %enough to create a new state
     
     ETA(i) = p.eta;
  
          if abs(S(i,s(i))) >= (sigm(i, s(i))*ETA(i)) &&  abs(S(i,s(i))) < (sigm(i, s(i))*ETA(i)*crp_difficulty(max(s)))%

                cand = unique(s);
                pr=[];
                for q = 1:numel(cand)
                    pr(q) = betapdf(E(i, cand(q)), al(i, cand(q)), be(i, cand(q)));
                end
                try
                    ma_id = find(max(pr)==pr);
                    s(i+1) = cand(ma_id(1)); %most likely state
                catch
                    disp('Error in competing part');
                   % s(i+1) = 1;
                end
        elseif  abs(S(i,s(i))) >= (sigm(i, s(i))*ETA(i)*crp_difficulty(max(s))) 
                states = unique(s);
                for t = states
                        %is there a candidate state +/- 
                        m(t) = inrange(E(i,s(i)), Q(i,t)-(sigm(i,t)*ETA(i)), Q(i,t)+(sigm(i, t)*ETA(i)) ) ;
                end

                if sum(m) < 1 %none, create new
                    create_new = 1;
                else
                    cand = unique(s);
                    pr=[];
                    for q = 1:numel(cand)
                       pr(q) = betapdf(E(i, cand(q)), al(i, cand(q)), be(i, cand(q)));
                    end
                    try
                        ma_id = find(max(pr)==pr);
                        s(i+1) = cand(ma_id(1)); %most likely state
                    catch
                        disp('Error in competing part');
                       % s(i+1) = 1;
                    end
                 end
        elseif abs(S(i,s(i))) <= (sigm(i, s(i))*ETA(i))
                 %stays the same
                s(i+1) = s(i);
        end


           %2) if not, create a NEW state
        %This has to involve filling Q and other vars with NaNs for
        %previous trials
        if create_new == 1
            s(i+1) = max(s) + 1;
            Q(1:i,s(i+1)) = NaN;
            S(1:i,s(i+1)) = NaN;
            al(1:i,s(i+1)) = NaN;
            be(1:i,s(i+1)) = NaN;
            sigm(1:i, s(i+1)) = NaN;

   
            Q(i, s(i+1)) = E(i, os(ot));
       
            sigm(i+1, s(i+1)) = sigm(1, 1);%
            mu = Q(i, s(i+1));
            sigma = sigm(i+1, s(i+1)); %
               
                
            %solution 1) Find such set of parameters for new distr that
            %have twice as big sigma as the previous state and are
            %closest to the mean
            param_sum =[];
            param_sum = 2 + (al(i,s(i)) + be(i, s(i)))/2;

            al_test = 1.01:0.1:param_sum;
            be_test =param_sum+1-al_test;
            minM = [];
            errM =[];
            for tt = 1:numel(al_test)
                errM(tt) = abs(mu - (al_test(tt) / (al_test(tt)+be_test(tt))));

            end
            ii=find(errM == min(errM)); 
            ii=ii(1);
            al(i+1,s(i+1)) =al_test(ii);
            be(i+1, s(i+1)) =  be_test(ii); 

       %     end       
        else
        %learn towards new state 
            if o(i) == 0      
                be(i+1, s(i+1)) = p.lambda*(be(i, s(i+1)) + p.tau_nosh - anchor) + anchor;
                al(i+1, s(i+1)) = p.lambda*(al(i, s(i+1)) ) ;
            elseif o(i) == 1
                al(i+1, s(i+1)) = p.lambda*(al(i, s(i+1)) + p.tau_sh - anchor) + anchor;
                be(i+1, s(i+1)) = p.lambda*(be(i, s(i+1))) ;
            end
            
        end
        
    if al(i+1, s(i+1)) <= 1
        al(i+1, s(i+1)) = 1.01;
    end
    if be(i+1, s(i+1)) <= 1
        be(i+1, s(i+1)) = 1.01;
    end
    
    upper_certainty = 30;    
    sump = [];
    sump = al(i+1, s(i+1))+be(i+1, s(i+1));
    if sump > upper_certainty % prevents states from becoming too certain
        factor = [];
        factor = upper_certainty/sump;
        al(i+1, s(i+1)) = factor*al(i+1, s(i+1));
        be(i+1, s(i+1)) = factor*be(i+1, s(i+1));
    end
    Scur(i) = sigm(i,s(i));
    Qcur(i) = Q(i,s(i));
    Qcur2(i) = Q2(i,s(i));
    
    %decay and adjust all non-next states
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
out.Qs2 = Q2;
out.E = E;
out.Q =[Qcur NaN]; %add a line - most other models produce an additional prediction 
out.Q2 =[Qcur2 NaN];
out.sigm =sigm;
out.U =Scur;
out.al = al;
out.be = be;
out.S = S;
out.s = s;
