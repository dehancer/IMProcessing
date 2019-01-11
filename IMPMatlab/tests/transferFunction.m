%%
%
%

function y = transferFunction(b,a,x)
    size = length(x);
    y    = zeros(1,size);
    pad  = length(a);
    for i = 1:pad
        y(i) = x(i);
    end
    for i = pad+1:size
        w = 0;
        for j = 1:pad
            w = w + b(j)*x(i-j+1);
            fprintf('%f\n',w)
        end
        
        y(i) = w ;
        for j = 2:pad
            y(i) = y(i) - a(j)*y(i-j+1);
        end
    end
end