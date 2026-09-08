function sim_IM = generateSimSpotImage(imSize,intensity,background_mean,background_sigma,spot_sigma, centOffset)

%generates a simulated image of size IMSIZE of single particle with maximum value of
%INTENSITY, and background characterized by BACKGROUND_MEAN &
%BACKGROUND_SIGMA. The spot will have a gaussian shape with a standard
%deviation of SPOT_SIGMA.

if rem(imSize,2) == 0
    imSize = imSize + 1;
end
cent_x = (imSize + 1)/2 + centOffset(1);
cent_y = (imSize + 1)/2 + centOffset(2);

sim_im = zeros(imSize);

for i = 1:imSize
    for j = 1:imSize
        expo = -((i - cent_x).^2 + (j - cent_y).^2)./(2.*(spot_sigma.^2));
        norm_fac = 1/(2*pi*(spot_sigma.^2));
        sim_im(i,j) = intensity.*numel(sim_im).*norm_fac.*exp(expo);
    end
end

bg_IM = normrnd(background_mean,background_sigma,imSize);

sim_IM = sim_im + bg_IM;
