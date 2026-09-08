function tracks = TrackingSeqFilter(imStack,roiImage,params)

%Performs spot tracking using a sequential filtering framework. Adapted
%from code from Christian Wildner (Darmstadt)

% properties of the optical system
lambda = params.lambda;
if lambda > 1
    lambda = lambda*1e-9;
end
NA = params.NA;

% constants required by the algorithm
dx= params.pxSize;

dy = params.pxSize;

if isfield(params,'pxSizeZ')
    dz = params.pxSizeZ;
else
    dz = 400e-9;
end

%Ensure pixel sizes are specified in m.
if dx > 1
    dx = dx.*1e-9;
elseif dx >0.1
    dx = dx.*1e-6;
end

if dy > 1
    dy = dy.*1e-9;
elseif dy >0.1
    dy = dy.*1e-6;
end

if dz > 1
    dz = dz.*1e-9;
elseif dz >0.1
    dz = dz.*1e-6;
end


sigma_pos = sqrt(2*2.2817e3*11)*1e-9;      % standard deviation for spot diffusion
[s_xy,~,s_z] = compute_gaussian_psf(lambda,NA);
s_I = 75;
s_b = 1.7781; 
p_birth = 0.02;
p_death = 0.2;


% model paramters
%options.initial_mean = [0.5*n_y;0.5*n_x;0.5*n_z;mean(img_4d(:));0];
%options.initial_covariance = diag([n_y^2;n_x^2;n_z^2;var(img_4d(:));var(img_4d(:))]);
options.initial_switch = [p_death/(p_birth+p_death);p_birth/(p_birth+p_death)];
if dz == 0
    options.propagation_covariance = diag([(sigma_pos/dx)^2,(sigma_pos/dx)^2,s_b^2,s_I^2]);
else
    options.propagation_covariance = diag([(sigma_pos/dx)^2,(sigma_pos/dx)^2, (sigma_pos/dz)^2,s_b^2,s_I^2]);
end
options.switch_transition = [1-p_birth,p_birth;p_death,1-p_death];
options.noise_correlation = 7.3399e-7;
options.noise_amplitude = 5084.5971;
options.sigma = 100.9610;

% optical system parameters
if dz == 0
    options.psf_parameters = [s_xy/dx,s_xy/dy];
    options.pixel_size = [dx,dy];
else
    options.psf_parameters = [s_xy/dx,s_xy/dy,s_z/dz];
    options.pixel_size = [dx,dy,dz];
end

% technical parameters required by the algorithm
options.fit_options = optimoptions('fminunc','Algorithm','trust-region','SpecifyObjectiveGradient',true,'HessianFcn','objective','Display','off');
options.cluster_size = 50 ;
options.cluster_size_tolerance = 10;
options.border_margin = 10;
options.min_cluster_size = 15;
options.candidate_threshold = 100;
options.min_intensity = 0;
options.num_states = 2;
if dz == 0
    options.boxsize = [7,7];
else
     options.boxsize = [7,7,3];
end
options.min_marginal = 0.01;
tracks = [];
for i = 1:size(roiImage,1)
    for j = 1:length(imStack)
        curROI = roiImage{i,j};
        [i_x,i_y] = find(curROI > 0);
        if ~isempty(i_x)
            
            x_min = min(i_x(:));
            x_max = max(i_x(:));
            y_min = min(i_y(:));
            y_max = max(i_y(:));
            

            img_4d(:,:,1,j) = double(imgaussfilt(imStack(j).data(x_min:x_max,y_min:y_max),5));
            img_4d(:,:,2,j) = double(imgaussfilt(imStack(j).data(x_min:x_max,y_min:y_max),3));
            img_4d(:,:,3,j) = double(imStack(j).data(x_min:x_max,y_min:y_max));
            img_4d(:,:,4,j) = double(imgaussfilt(imStack(j).data(x_min:x_max,y_min:y_max),3));
            img_4d(:,:,5,j) = double(imgaussfilt(imStack(j).data(x_min:x_max,y_min:y_max),5));
%             img_4d(:,:,3,j) = double(imStack(j).data(x_min:x_max,y_min:y_max));
        end

    end
    [n_x,n_y,n_z,n_t] = size(img_4d);
    % set initial mean
    options.size = size(img_4d);
%     options.initial_mean = [0.5*n_y;0.5*n_x;mean(img_4d(:));0];
    options.initial_mean = [0.5*n_y;0.5*n_x;0.5*n_z;mean(img_4d(:));0];
%     options.initial_covariance = diag([n_y^2;n_x^2;var(img_4d(:));var(img_4d(:))]);
    options.initial_covariance = diag([n_y^2;n_x^2;n_z^2;var(img_4d(:));var(img_4d(:))]);
    % run the filter
    [forward_data,~,~] = forward_reverse_smoother(img_4d,options);
    % get filter means
    [x_filt,x_filt_err] = evaluate_means(forward_data);
    % compute existence probability
    [p_exist,log_likelihood ] = evaluate_existence_probability2D(forward_data);
    track_cur = [x_filt',p_exist(1,:)',i*ones(length(x_filt),1)];
    tracks = [tracks; track_cur];
end
