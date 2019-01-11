radius = 9;
len     = ceil(radius) * 20;

[b,a] = iirGaussianKernelAsFIR(radius);

xsignal        = zeros(len-1, 1);
xsignal(len/2) = 1;
xsignal(1) = 1;
xsignal(len-1) = 1;

%vYSignal = filter(b, a, xsignal);
%vYSignal = filter(b, a, vYSignal(end:-1:1));
vYSignal = transferFunction (b, a, xsignal);
vYSignal = transferFunction (b, a, vYSignal(end:-1:1));

%vYSignal = iirFilter(b,a,xsignal);

figure(1);
clf(1);

x = -len/2+1:len/2-1;

plot(x,vYSignal,'b','LineWidth',3);
hold on;
plot(x,xsignal,'k','LineWidth',1);

[b,a] = iirGaussianKernel(radius);
vYSignal2 = iirFilter(b,a,xsignal);
hold on; plot(x,vYSignal2,'g-.','LineWidth',2);

x = -len/2+1:len/2-1;
g = normpdf(x,0,radius);
hold on; plot(x,g,'r-','LineWidth',2);
axis([-len/2-10,len/2+10, 0, 0.1])

