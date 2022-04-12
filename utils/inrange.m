function[out] = inrange(in, min, max)
if in > min && in < max
    out = 1;
else
    out = 0;
end