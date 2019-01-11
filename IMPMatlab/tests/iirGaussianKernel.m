%%
%
%

function [b,a] = iirGaussianKernel(radius) 
        
        q = radius;
        q4 = q^2; 
        q4 = 1.0/(q4^2);
        
        coef_A = q4*(q*(q*(q*1.1442707+0.0130625)-0.7500910)+0.2546730);
        coef_W = q4*(q*(q*(q*1.3642870+0.0088755)-0.3255340)+0.3016210);
        coef_B = q4*(q*(q*(q*1.2397166-0.0001644)-0.6363580)-0.0536068);
        
        z0       = exp(coef_A);
        z0_real  = z0 * cos(coef_W);
        z2       = exp(coef_B);

        z02      = z0^2;
        
        a2 =  1.0 / (z2 * z02);
        a0 =  (z02 + 2*z0_real * z2) * a2;
        a1 = -(2*z0_real + z2) * a2;
        
        b0 = 1.0 - (a0 + a1 + a2); 
        b = [b0];
        a = [a0 a1 a2];
end