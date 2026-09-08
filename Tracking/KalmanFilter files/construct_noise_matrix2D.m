function [ basis,noise ] = construct_noise_matrix2D(roi,options)
% Construct the noise matrix for a region of interest and diagonalizes it.
% Returns the orthonormal basis and a vector of eigenvalues
%   roi: nx3 vector containing the coordinates of the region of interest
%   options: options structure of the full procedure

% check if amplitude of correlated noise is positive
if options.noise_amplitude > 1e-3
    % get parameters
    num_el = size(roi,1);
    noise_kernel = options.noise_correlation./options.pixel_size;
    % calculate differences between all pixels
    noise = repmat(roi,[num_el,1])-repelem(roi,num_el,1);
    % rescale and square
    noise = noise./noise_kernel;
    noise = noise.^2;
    % sum columns and exponentiate
    noise = options.noise_amplitude*exp(-0.5*sum(noise,2));
    % reshape output to square matrix
    noise = reshape(noise,[num_el,num_el]);
    % add the uncorrelated noise
    noise = noise+options.sigma^2*eye(num_el);
    % diagonalize
    [basis,noise] = eig(noise,'vector');
else
    basis = eye(length(roi));
    noise = options.sigma^2*ones([length(roi),1]);
end

end

