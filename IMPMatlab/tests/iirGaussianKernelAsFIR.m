    %%
    %
    %

 function [b,a] = iirGaussianKernelAsFIR(radius)

    q = radius;

    if 0.5 <= radius && radius <= 2.5 
        q = 3.97156 - 4.14554 * sqrt(1.0 - 0.26891*radius);
    elseif radius > 2.5 
        q = 0.98711 * radius - 0.96330;
    end
    
    q2   = q^2;
    q3   = q^3;
    b0   = 1.57825 + (2.44413 * q) + (1.4281  * q2) + (0.422205 * q3);
    b1   =           (2.44413 * q) + (2.85619 * q2) + (1.26661  * q3);
    b2   =                           (-1.4281 * q2) + (-1.26661 * q3);
    b3   =                                            (0.422205 * q3);
    b    = [1 - ((b1 + b2 + b3) / b0),0,0,0];
    a    = [b0, -b1, -b2, -b3] / b0;
    
 end