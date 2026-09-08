function [ means,covariances,weights,max_log_weight ] = forward_update2D( means_old,covariances_old,...
    weights_old,candidates,roi,z,options )
% Performs the update steps for all possible transitions and returns the
% new means and covariances along with log weights

% preparations
n_states = options.num_states;
off = 1;
on = 2;
eps = options.min_marginal;
Q = options.propagation_covariance;

% transition matrix
p_trans = options.switch_transition;

% set up output
means = means_old;
covariances = covariances_old;
weights = -Inf(n_states,n_states);

% norm for components
prior_norm = sum(weights_old);

% calculate noise covariance (eigen-decomposition)
[R_basis,R] = construct_noise_matrix2D(roi,options);

% check if off component of last step has positive weight
if prior_norm(1) > 0
    % prepare predicted density
    x_pre_1 = means_old{1,1};
    x_pre_2 = means_old{2,1};
    P_pre_1 = covariances_old{1,1};
    P_pre_2 = covariances_old{2,1};
    prior_weights = weights_old(:,1)/prior_norm(1);
% transition off -> off
    % perform prediction
    [x_pre,P_pre] = mixture_reduction2D(prior_weights,{x_pre_1,x_pre_2},{P_pre_1,P_pre_2});
    x_pre(4) = 0;
    P_pre = P_pre+Q;
    P_pre(:,4) = 0;
    P_pre(4,:) = 0;
    P_pre(4,4) = Q(4,4);
    % define the target function
    fun = @(x) 0.5*sum((R_basis'*(z-x(3))).^2./R)+0.5*(x-x_pre)'*(P_pre\(x-x_pre));
%     % perform fit
%     x_start = [mean(roi)';x_pre(4);0.1*std(z)];
%     [x,res,~,~,~,H] = fminunc(fun,x_start,options.fit_options);
    [x,H] = optimize_background2D(x_pre,P_pre,z,R_basis,R);
    res = fun(x);
    % save the updated states
    means{off,off} = x;
    covariances{off,off} = inv(H);
    % evaluate the (log) weights
    weights(off,off) = -res-0.5*log(det(H))+log(prior_norm(1))-0.5*log(det(P_pre));
% transition off -> on
    % perform prediction
    [x_pre,P_pre] = mixture_reduction2D(prior_weights,{x_pre_1,x_pre_2},{P_pre_1,P_pre_2});
    x_pre(4) = 0;
    P_pre(:,4) = 0;
    P_pre(4,:) = 0;
    P_pre = P_pre+Q;
    % prepare fit function
    %fun = @(x) extended_observation_model(x,roi,z,R_basis,R,options.psf_parameters)+0.5*(x-x_pre)'*(P_pre\(x-x_pre));
    fun = @(x) extended_observation_model_grad2D(x,roi,z,R_basis,R,options.psf_parameters,x_pre,P_pre);
    % perform fit for all candidates
    res = Inf;
    x = zeros(4,1);
    H = eye(4);
    for j = 1:length(candidates)
        % starting value for optimization
        x_start = zeros(size(x_pre));
        x_start(1:2) = candidates{j}(1:2);
        x_start(3) = means{off,off}(3);
        x_start(4) = prefit_intensity2D(x_start,roi,z,R_basis,R,options.psf_parameters,x_pre,P_pre);
        % perform fit with all candidates as initial points
        [x_test,res_test,~,~,~,H_test] = fminunc(fun,x_start,options.fit_options);
        if is_valid_cov(H_test) && res_test < res && is_valid_state2D(x_test,options)
            x = x_test;
            res = res_test;
            H = H_test;
        end
    end
    % save the updated states
    means{off,on} = x;
    covariances{off,on} = inv(H);
    % evaluate the (log) weights
    weights(off,on) = -res-0.5*log(abs(det(H)))+log(prior_norm(1))-0.5*log(det(P_pre));
end
% check if on component of last step has positive weight
if prior_norm(2) > 0
    % prepare predicted density
    x_pre_1 = means_old{1,2};
    x_pre_2 = means_old{2,2};
    P_pre_1 = covariances_old{1,2};
    P_pre_2 = covariances_old{2,2};
    prior_weights = weights_old(:,2)/prior_norm(2);
% transition on -> off
    % perform prediction
    [x_pre,P_pre] = mixture_reduction2D(prior_weights,{x_pre_1,x_pre_2},{P_pre_1,P_pre_2});
    % modify to take account of the on-off transition
    x_pre(4) = 0;
    P_pre(:,4) = 0;
    P_pre(4,:) = 0;
    P_pre = P_pre+Q;
    % define the target function
    fun = @(x) 0.5*sum((R_basis'*(z-x(3))).^2./R)+0.5*(x-x_pre)'*(P_pre\(x-x_pre));
%     % perform fit
%     x_start = [mean(roi)';x_pre(4);0.1*std(z)];
%     [x,res,~,~,~,H] = fminunc(fun,x_start,options.fit_options);
    [x,H] = optimize_background2D(x_pre,P_pre,z,R_basis,R);
    res = fun(x);
    % save the updated states
    means{on,off} = x;
    covariances{on,off} = inv(H);
    % evaluate the (log) weights
    weights(on,off) = -res-0.5*log(det(H))+log(prior_norm(2))-0.5*log(det(P_pre));
% transition on -> on
    % perform prediction
    [x_pre,P_pre] = mixture_reduction2D(prior_weights,{x_pre_1,x_pre_2},{P_pre_1,P_pre_2});
    P_pre = P_pre+Q;
    % prepare fit function
    %fun = @(x) extended_observation_model(x,roi,z,R_basis,R,options.psf_parameters)+0.5*(x-x_pre)'*(P_pre\(x-x_pre));
    fun = @(x) extended_observation_model_grad2D(x,roi,z,R_basis,R,options.psf_parameters,x_pre,P_pre);
    % perform fit
    res = Inf;
    x = zeros(4,1);
    H = eye(4);
    for j = 1:length(candidates)
        % starting value for optimization
        x_start = zeros(size(x_pre));
        x_start(1:2) = candidates{j}(1:2);
        x_start(3) = means{on,off}(3);
        x_start(4) = prefit_intensity2D(x_start,roi,z,R_basis,R,options.psf_parameters,x_pre,P_pre);
        % perform fit with all candidates
        [x_test,res_test,~,~,~,H_test] = fminunc(fun,x_start,options.fit_options);
        if is_valid_cov(H_test) && res_test < res && is_valid_state2D(x_test,options)
            x = x_test;
            res = res_test;
            H = H_test;
        end
    end
    % save the updated states
    means{on,on} = x;
    covariances{on,on} = inv(H);
    % evaluate the (log) weights
    weights(on,on) = -res-0.5*log(abs(det(H)))+log(prior_norm(2))-0.5*log(det(P_pre));
end
% update the weights and save the max
weights = weights+log(p_trans);
max_log_weight = max(weights(:));
weights = exp(weights-max_log_weight);
% neglect small components
marginal = sum(weights)/sum(weights(:));
marginal = [marginal;marginal];
weights(marginal<eps) = 0;
% add all components to max_log_weight that are identical for all transitions
max_log_weight = max_log_weight-0.5*log(2*pi)*length(z);%-0.5*sum(log(R));

end

