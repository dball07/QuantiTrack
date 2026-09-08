function [ res,Df,Hf ] = extended_observation_model_grad( state,roi,data,noise_basis,noise,param,x_pre,P_pre )
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
spot = exp(-0.5*sum(roi_squ,2));

% evaluate the residual based on the current parameters
sim = state(5)*spot+state(4);

% calculate result
res = 0.5*sum((noise_basis'*(data-sim)).^2./noise)+0.5*(state-x_pre)'*(P_pre\(state-x_pre));

% calculate the gradient if required
if nargout > 1
    
    % Jacobian of the observation model
    Dh = state(5)*spot.*(roi_scale);
    Dh = [Dh,ones(size(noise)),spot];
    rest = (noise_basis*(noise_basis'*(sim-data)./noise));
    Df = Dh'*rest;
    Df = Df+(P_pre\(state-x_pre));
    
    % calculate the hessian if required
    if nargout > 2
        % compute contribution of the second derivatives
        Hh = zeros(5,5);
        Hh(1:3,1:3) = -diag(state(5)./psf)*(spot'*rest);
        tmp = state(5)*roi_scale'*((spot.*rest).*roi_scale);
        Hh(1:3,1:3) = Hh(1:3,1:3)+tmp;
        tmp = sum((spot.*(roi_scale)).*rest);
        Hh(5,1:3) = tmp;
        Hh(1:3,5) = tmp';
        % compute contribution of the first derivatives
        tmp = noise_basis'*Dh;
        Hf = Hh+tmp'*(tmp./noise);
        % add contribution from prior
        Hf = Hf+inv(P_pre);
    end
    
end

