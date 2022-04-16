function [al, be, mu, sigma] = beta_ms2ab(mu, sigma)

al = (( (1-mu)/(sigma^2)) - (1/mu))*(mu^2);
be = al*((1/mu)-1);



end

