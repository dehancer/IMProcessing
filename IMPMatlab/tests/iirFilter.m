%%
%
%

function outb = iirFilter(b,a,signal)

    len = length(signal);
    out = zeros(1,len);
    start = length(b)+length(a);
    
    for i = start:len
        
        o = signal(i) * b(1);
        
        for j = 2:length(b)
            o = o + signal(i-(j+1))*b(j);
        end
        
        for j = 1:length(a)
            o = o + out(i-j)*a(j);        
        end
        
        out(i) = o;
        
    end
    
    outb = zeros(1,len);
    out = fliplr(out);
    
    for i = start:len
        
        o = out(i) * b(1);
        
        for j = 2:length(b)
            o = o + out(i-(j+1))*b(j);
        end
        
        for j = 1:length(a)
            o = o + outb(i-j)*a(j);        
        end
        
        outb(i) = o;
        
    end
    
end