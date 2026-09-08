function IntTcourse = measurePixelInt(imStack,x0,y0)

% measures the pixel intensity at a specific location over a time.
for i = 1:length(imStack)
    IntTcourse(i,:) = imStack(i).data(x0,y0);
end

