function [ s_x,s_y,s_z ] = compute_gaussian_psf( lambda,na )
%% Computes a Gaussian psf approximation for the given optical system
% inputs
%   na: numerical aperture of the microscope objective
%   n: refractive index of the immersion objective
%   lambda: wave length of the fluorescent dye 

% refractive index of water
n_s = 1.33;

% calculate the PSF parameters in meters
s_x = sqrt(2)*lambda/(2*pi*na); 
s_y = s_x;
s_z = sqrt(6)*n_s*lambda/(pi*na^2); 


end
