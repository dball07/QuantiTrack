function  [parFit, ssr, uncert] = gauss_fit2D_cov2(img,coordinates)

x = coordinates{1};
y = coordinates{2};
z = coordinates{3};

[px,py,pz] = meshgrid(x,y,z);
sigmaXY = 0.525/2.3548; % in um for 642
sigmaXY = sigmaXY./0.104; %in pixels;
sigmaZ = 1.1/2.3548; %in um for 642
sigmaZ = sigmaZ/0.5; %in planes
sigma = [sigmaXY, sigmaZ];

% sigma = 1.3;

% Starting values


par0(1) = max(img(:)) -  mean(img(:)); % max intensity
par0(2) = length(x)/8; % sigma
par0(3) = mean(img(:)); % background
par0(4) = x(1) + (x(end) - x(1))/2; % x-center
par0(5) = y(1) + (y(end) - y(1))/2;  % y-center
par0(6) = z(1) + (z(end) - z(1))/2;  % y-center
% boundaries for the fit
LB = [0,0,0,x(1),y(1),z(1)];
UB = [65536,10,65536, x(end), y(end),z(end)];

% fit options
options = optimset('lsqnonlin');
options.Display = 'none';

% fit
% parFit = lsqnonlin(@(P)objfun(P,px,py,img),par0,LB,UB,options);
[parFit,~,residuals,~,~,~,J] = lsqnonlin(@(P)objfun2(P,sigma,px,py,pz,img),par0,LB,UB,options);
% residuals = objfun2(parFit,sigma,px,py,img);
ci = nlparci(parFit,residuals,'jacobian',J);
ci1 = ci(:,1);
uncert = parFit - ci1';
ssr = sum(residuals.^2);
% parFit(2) = sigma(1);
% parFit(3) = sigma(2);

% Object function
% --------------------
function residuals = objfun (par, x, y, img)
sigma_matrix = [1/par(2), 0; 0, 1/par(2)];
exponent = [x(:) - par(4), y(:) - par(5)]*sigma_matrix;
model = par(3) + par(1)*exp(-sum(exponent.*exponent,2)/2);
residuals = model - img(:);

 
% Object function
% --------------------
function residuals = objfun2 (par,sigma, x, y, z, img)
sigma_matrix = [1/sigma(1), 0, 0; 0, 1/sigma(1),0; 0, 0, 1/sigma(2)];
exponent = [x(:) - par(4), y(:) - par(5), z(:) - par(6)]*sigma_matrix;
model = par(3) + par(1)*exp(-sum(exponent.*exponent,2)/2);
residuals = model - img(:);





