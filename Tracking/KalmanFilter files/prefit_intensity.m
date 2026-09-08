function [ I ] = prefit_intensity( state,roi,data,noise_basis,noise,param,x_pre,P_pre )
% Evaluates the log of the posterior defined by a Gaussian prior and the
% Gaussian PSF approximation
%   state: current state of the system consisting of [y_k,x_k,z_k]
%   roi: nx3 vector containing the coordinates of the region of interest
%   noise: noise covariance matrix
%   param: standard deviations squared of the gaussian psf model

% calculate the coordinates
roi = roi-state(1:3)';
psf = param.^2;

% scaled roi's
roi_scale = roi./psf;
roi_squ = roi_scale.*roi;

% psf
sim = exp(-0.5*sum(roi_squ,2));

% center data
data = data-state(4);

% calculate result
tmp1 = noise_basis'*data;
tmp2 = noise_basis'*sim;
I = ((tmp1./noise)'*tmp2+x_pre(5)/P_pre(5,5))/((tmp2./noise)'*tmp2+1/P_pre(5,5));


