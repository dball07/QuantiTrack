function part = SLIMfast_loc_wrapper(imStack,locOptions)

%locates particles in each frame of the input time-lapse movie, imStack3D.
%Uses the code from SLIMfast (Normanno, et al. Nature Comm, 2015).
% locOptions.roi = [1, 1, imStack(1).width,imStack(1).height]; % maybe add ROI if too slow
% locOptions.locParallel = 0;
% locOptions.rLive = 0;
% locOptions.spatialCorrection = 0;
% 
% locOptions.maxOptimIter = 50;
% locOptions.termTol = -2;
% locOptions.isRadiusTol = 0;
% locOptions.radiusTol = 50;
% locOptions.posTol = 1.5;
% 
% locOptions.w2d = windowSz; %detection box
% locOptions.psfStd = 1.03; %PSF width (could be calculated)
% locOptions.errorRate = -6;
% locOptions.dfltnLoops = 1;
% locOptions.minInt = 0;


data = localizeParticles(imStack,1,length(imStack),locOptions);
data(:,1:2) = data(:,1:2) + 1;
part = [data(:,2),data(:,1),data(:,3)/sqrt(pi)./data(:,6), zeros(size(data,1),1), data(:,3)/sqrt(pi)./data(:,6), ...
    data(:,8), data(:,3)/sqrt(pi)./data(:,6), data(:,6), data(:,5), data(:,2),data(:,1), ...
    sqrt(data(:,4)),zeros(size(data,1),6)];




function data_all = localizeParticles(imStack3D,startPnt,endPnt,imageBin)

region = {[imageBin.roi(2) imageBin.roi(2)+imageBin.roi(4)-1],...
    [imageBin.roi(1) imageBin.roi(1)+imageBin.roi(3)-1]};

if imageBin.locParallel
    %startPnt localization procedure
    data = cell(endPnt-startPnt+1,1);
    ctrsN = cell(endPnt-startPnt+1,1);
    data_all = [];
    % switch imageBin.nCores
    %     case 1
    %         %             matlabpool local
    %         parpool('local',1);
    %     case 2
    %         %             matlabpool 2
    %         parpool('local',2);
    %     case 3
    %         %             matlabpool 3
    %         parpool('local',3);
    % end %switch
    roiWidth = imageBin.roi(3);
    roiHeight = imageBin.roi(4);
    w2d = imageBin.w2d;
    psfStd = imageBin.psfStd;
    errorRate = imageBin.errorRate;
    dfltnLoops = imageBin.deflateLoops;
    minInt = imageBin.minIntensity;
    optim = [imageBin.maxOptimIter,imageBin.termTol,...
        imageBin.isRadiusTol,imageBin.radiusTol,...
        imageBin.posTol];
    
    parfor frame = startPnt:endPnt
        [data{frame} unused unused ctrsN{frame}] = ...
            detect_et_estime_part_1vue_deflt(...
            double(imStack3D(frame).data),...
            w2d, psfStd,chi2inv(1-1/10^(errorRate*-1),1),...
            dfltnLoops,roiWidth,roiHeight,minInt,optim);
    end %for
    %     matlabpool close
    
    time = [];
    for frame = startPnt:endPnt
        time = [time;ones(ctrsN{frame},1)*frame];
    end %for
    data = [vertcat(data{:}) time];
    if imageBin.spatialCorrection
        data(:,1:2) = fliplr(tformfwd(imageBin.tMat,data(:,2),data(:,1)));
        bad = data(:,2)<=roi(1) & data(:,2)>=roi(1)+roi(3)-1 &...
            data(:,1)<=roi(2) & data(:,1)>=roi(2)+roi(4)-1;
        data(bad,:) = [];
    end %if
    % streamToDisk(data,...
    %     [imageBin.pathname imageBin.filename])
    data_all = [data_all;data];
    ctrsN = vertcat(ctrsN{:});
else %linear computation
    iter = 0;
    hProgressbar = waitbar(0,'Localization...','Color',...
        get(0,'defaultUicontrolBackgroundColor'));
    data_all = [];
    for frame = startPnt:endPnt
        iter = iter+1;
        I = imStack3D(frame).data;
        
        optim = [imageBin.maxOptimIter,imageBin.termTol,...
            imageBin.isRadiusTol,imageBin.radiusTol,...
            imageBin.posTol];
        
        [data deflatedIm binaryIm ctrsN(iter,1)] = ...
            detect_et_estime_part_1vue_deflt(...
            double(I),imageBin.w2d, imageBin.psfStd,...
            chi2inv(1-1/10^(imageBin.errorRate*-1),1),...
            imageBin.deflateLoops,imageBin.roi(3),...
            imageBin.roi(4),imageBin.minIntensity,optim);
        
%         if 0
%             imwrite(uint16(deflatedIm),...
%                 [imagename(1:end-4) '_deflated.tif'],...
%                 'compression','none','writemode','append')
%             imwrite(uint16(binaryIm),...
%                 [imagename(1:end-4) '_binary.tif'],...
%                 'compression','none','writemode','append')
%         end
        
        if imageBin.rLive
            if frame == startPnt
                fig =...
                    figure(...
                    'Units','normalized',...
                    'Position', figPos(imageBin.roi(3)/imageBin.roi(4)),...
                    'Color', get(0,'defaultUicontrolBackgroundColor'),...
                    'Name', 'Live Localization',...
                    'NumberTitle', 'off',...
                    'MenuBar', 'none',...
                    'ToolBar', 'none');
                ax =...
                    axes(...
                    'Parent', fig,...
                    'Units','normalized',...
                    'Position', [0 0 1 1]);
                liveView = imshow(imadjust(I),[]);
                rho = [0;0.69;1.39;2.09;2.79;3.49;4.18;4.88;5.58;6.28];
                hDots = patch(repmat(1+data(:,2)',10,1)+cos(rho)*data(:,6)',...
                    repmat(1+data(:,1)',10,1)+sin(rho)*data(:,6)',...
                    repmat(shiftdim([1 0 0],-1),1,ctrsN(iter)),...
                    'EdgeColor', 'none', 'FaceAlpha', 0.5,...
                    'Parent', ax);
                drawnow
            elseif frame == endPnt
                set(liveView, 'CData', imadjust(I))
                rho = [0;0.69;1.39;2.09;2.79;3.49;4.18;4.88;5.58;6.28];
                set(hDots, 'XData', repmat(1+data(:,2)',10,1)+...
                    cos(rho)*data(:,6)', 'YData', repmat(1+data(:,1)',10,1)+...
                    sin(rho)*data(:,6)', 'CData', repmat(shiftdim([1 0 0],-1),1,...
                    ctrsN(iter)))
                drawnow
                close(fig)
            else
                set(liveView, 'CData', imadjust(I))
                
                rho = [0;0.69;1.39;2.09;2.79;3.49;4.18;4.88;5.58;6.28];
                set(hDots, 'XData', repmat(1+data(:,2)',10,1)+...
                    cos(rho)*data(:,6)', 'YData', repmat(1+data(:,1)',10,1)+...
                    sin(rho)*data(:,6)', 'CData', repmat(shiftdim([1 0 0],-1),1,...
                    ctrsN(iter)))
                drawnow
            end %if
        end %if
        %correct for imageBin.roi(crop)
        %data(:,1:2) = [data(:,1)+imageBin.roi(2)-1,data(:,2)+imageBin.roi(1)-1];
        time = ones(ctrsN(iter),1)*iter;
        
        data = [data, time];
        %apply a nonreflective similarity transformation (correct for
        %scale, rotation and translation)
        if imageBin.spatialCorrection
            data(:,1:2) = fliplr(tformfwd(imageBin.tMat,data(:,2),data(:,1)));
            bad = data(:,2)<=imageBin.roi(1) & data(:,2)>=imageBin.roi(1)+imageBin.roi(3)-1 &...
                data(:,1)<=imageBin.roi(2) & data(:,1)>=imageBin.roi(2)+imageBin.roi(4)-1;
            data(bad,:) = [];
        end %if
        
%         streamToDisk([data ones(ctrsN(iter),1)*frame],...
%             [imageBin.pathname imageBin.filename])
        data_all = [data_all;data];
        waitbar(iter/(endPnt-startPnt+1));
        %,hProgressbar,...
        %    'Localization...','Color',...
        %    get(0,'defaultUicontrolBackgroundColor'));
    end %for
    delete(hProgressbar)
end %if

function [lestime, input_deflt, dfin, ctrsN] =...
    detect_et_estime_part_1vue_deflt(input, wn, r0, pfa, n_deflt,...
    w,h,minInt,optim)

[lest,ldec,dfin] = detect_et_estime_part_1vue (input, wn, r0, pfa, optim) ;
input_deflt = deflat_part_est(input, lest, wn);
lestime = lest ;
if n_deflt == 0
            border = ceil(wn/2);
        good = lestime(:,7) & ...
            (lestime(:,4)/sqrt(pi)./lestime(:,6)>minInt) & ...
            (lestime(:,1)>border) & (lestime(:,1)<h-border) & ...
            (lestime(:,2)>border) & (lestime(:,2)<w-border) ;
        lestime = lestime(good,:);
        ctrsN = sum(good);
        return
end %if

for n=1:n_deflt
    [l,ld,d,N] = detect_et_estime_part_1vue (input_deflt, wn, r0, pfa, optim) ;
    lestime = [lestime ; l] ;
    %%dfin += d
    dfin = dfin | d ;
    input_deflt = deflat_part_est(input_deflt, l, wn);
    
    if (N==0) || n == n_deflt
        border = ceil(wn/2);
        good = lestime(:,7) & ...
            (lestime(:,4)/sqrt(pi)./lestime(:,6)>minInt) & ...
            (lestime(:,1)>border) & (lestime(:,1)<h-border) & ...
            (lestime(:,2)>border) & (lestime(:,2)<w-border) ;
        lestime = lestime(good,:);
        ctrsN = sum(good);
        return
    end

end%for


function [lestime, ldetect, d, Nestime] = detect_et_estime_part_1vue(input, wn, r0, pfa, optim)%%, pas_ijr)

[Ni, Nj] = size(input) ;

% positions des parametres
Nparam = 7 ;
detect_i = 2 ;
detect_j = 3 ;
alpha = 4 ;
% sig2 = 5 ;

% detection pour un rayon moyen r0
[c,ldetect,d] = carte_H0H1_1vue(input, r0, wn, wn, pfa);

% estimation pour des pas de recherche
% interval [-1,1] pour ij
% interval [0.6,1.4] pour le rayon

Ndetect = size(ldetect, 1) ;
if (Ndetect==0) %no pixels meets glrt threshold
    lestime = zeros(1,Nparam) ;
    Nestime = 0 ;
    return ;
end%if

Nestime = 0 ;
bord = ceil(wn/2) ;
for n=1:Ndetect
    test_bord = (ldetect(n,detect_i) < bord) || (ldetect(n,detect_i) > Ni-bord) || ...
        (ldetect(n,detect_j) < bord) || (ldetect(n,detect_j) > Nj-bord) ;
    if ((ldetect(n,alpha) > 0.0) && (~test_bord) )
        Nestime = Nestime + 1 ;
        lestime(Nestime, :) = estim_param_part_GN(input, wn, ldetect(n,:), r0, optim) ;
    end%if
end%for

% a la bonne taille
if (Nestime==0)
    lestime = zeros(1,Nparam) ;
else
    lestime = lestime(1:Nestime,:) ;
end%if

function [carte_MV, liste_detect, detect_pfa] = carte_H0H1_1vue(im, rayon, wn_x, wn_y, s_pfa)

[N,M] = size(im) ;
T = wn_x*wn_y ; % nombre de pixel dans la fenetre


%% Hypothese H0
%% pas de particule dans la fenetre
m = ones(wn_x,wn_y) ;
hm = expand_w(m, N, M) ;
tfhm = fft2(hm) ;
tfim = fft2(im) ;
m0 = real(fftshift(ifft2(tfhm .* tfim))) /T ;

im2 = im .* im ;
tfim2 = fft2(im2) ;
Sim2 = real(fftshift(ifft2(tfhm .* tfim2)));

%% H0 = T/2*log(2*pi*sig0^2)-T/2 ;
T_sig0_2 = Sim2 - T*m0.^2 ;

%% Hypoth?se H1
%% une particule est au centre de la fenetre
%% amplitude inconnue, rayon fixe

%% generation masque gaussien de largeur (sigma)
%% egal a rayon

%%g = gausswin2(rayon, wn_x, wn_y) ;
g = gausswin2(rayon, wn_x, wn_y, 0, 0) ;
gc = g - sum(g(:))/T ;
Sgc2 = sum(gc(:).^2) ;
hgc = expand_w(gc, N, M) ;
tfhgc = fft2(hgc) ;

alpha = real(fftshift(ifft2(tfhgc .* tfim))) / Sgc2 ;

%% H1 = T/2*log(2*pi*sig1^2)-T/2 ;
%%sig1_2 = sig0_2 - alpha.^2 * Sgc2 / T ;

%% pour test
%sig1_2 = T_sig0_2/T - alpha.^2 * Sgc2 / T ;
%%imagesc(T_sig0_2/T);
%imagesc(sig1_2);
%%imagesc(sig1_2 ./ (T_sig0_2/T));

%%  carte_MV = -0.5*(H0 - H1) ;
% carte_MV = - T * log(1 - (Sgc2 * alpha.^2) ./ T_sig0_2) ;
test = 1 - (Sgc2 * alpha.^2) ./ T_sig0_2 ;
test = (test > 0) .* test + (test <= 0) ;
carte_MV = - T * log(test) ;
carte_MV(isnan(carte_MV)) = 0; %CPR

%% detection et recherche des maximas
%% s_pfa = 28 ;
detect_masque = carte_MV > s_pfa ;
if (sum(detect_masque(:))==0)
    %     warning('No target detected !') ; %#ok
    liste_detect = zeros(1,6) ;
    detect_pfa = zeros(size(detect_masque)) ; % ajout AS 4/12/7
else
    detect_pfa = all_max_2d(carte_MV) & detect_masque ;
    
    [di, dj] = find(detect_pfa) ;
    n_detect = size(di, 1) ;
    vind = N*(dj-1)+di ;
    valpha = alpha(:) ;
    alpha_detect = valpha(vind) ;
    
    sig1_2 = ( T_sig0_2 - alpha.^2 * Sgc2 ) / T ;
    vsig1_2 = sig1_2(:) ;
    sig2_detect = vsig1_2(vind) ;
    
    %% g de puissance unitaire
    %%RSBdB_detect = 10*log10(alpha_detect.^2  ./ sig2_detect) ;
    
    %%liste_detect = [(1:n_detect)', di, dj, alpha_detect, sqrt(sig2_detect), RSBdB_detect] ;
    liste_detect = [(1:n_detect)', di, dj, alpha_detect, sig2_detect, rayon*ones(n_detect,1),ones(n_detect,1)] ;
    
end%if


function out = expand_w(in, N, M)

[N_in, M_in] = size(in) ;

out = zeros(N,M) ;
%nc = 1+floor(N/2 - N_in/2) ;
%mc = 1+floor(M/2 - M_in/2) ;
%out(nc:(nc+N_in-1) , mc:(mc+M_in-1)) = in ;

nc = floor(N/2 - N_in/2) ;
mc = floor(M/2 - M_in/2) ;
out((nc+1):(nc+N_in) , (mc+1):(mc+M_in)) = in ;

function g = gausswin2(sig, wn_i, wn_j, offset_i, offset_j)

if (nargin < 5)
    offset_i = 0.0 ;
    offset_j = 0.0 ;
end%if

if (nargin < 3)
    wn_j = wn_i ;
end%if

refi = 0.5 + (0:(wn_i-1)) - wn_i/2 ;
i = refi - offset_i ;
refj = 0.5 + (0:(wn_j-1)) - wn_j/2 ;
j = refj - offset_j ;
ii = i' * ones(1,wn_j) ; %'
jj = ones(wn_i,1) * j ;

%%% puissance unitaire
g = (1/(sqrt(pi)*sig)) * exp(-(1/(2*sig^2))*(ii.*ii + jj.*jj)) ;


function carte_max = all_max_2d(input)

[N,M] = size(input) ;
ref = input(2:N-1, 2:M-1) ;

pos_max_h = input(1:N-2, 2:M-1) < ref & ...
    input(3:N  , 2:M-1) < ref;
pos_max_v = input(2:N-1, 1:M-2) < ref & ...
    input(2:N-1, 3:M  ) < ref;
pos_max_135 = input(1:N-2, 1:M-2) < ref & ...
    input(3:N  , 3:M  ) < ref;
pos_max_45  = input(3:N  , 1:M-2) < ref & ...
    input(1:N-2, 3:M  ) < ref;

carte_max = zeros(N,M) ;
carte_max(2:N-1, 2:M-1) = pos_max_h & pos_max_v & pos_max_135 & pos_max_45 ;
carte_max = carte_max .* input ;


function liste_param = estim_param_part_GN(im, wn, liste_info_param, r0, optim)

Pi = liste_info_param(2) ;
Pj = liste_info_param(3) ;
di = (1:wn)+Pi-floor(wn/2) ;
dj = (1:wn)+Pj-floor(wn/2) ;
im_part = im(di, dj) ;

if 0
        options = optimset(...
        'Algorithm', 'Active-Set',...
        'Display','off',...
        'UseParallel', 'always');
    if 0
    guess = [0,0,r0];
    bounds = [-1.5,-1.5,r0-r0*0.1;1.5,1.5,r0+r0*0.6];
    liste_param = gaussMLE(im_part,guess,bounds,options);
    else
    guess = [0,0,r0,0,r0];
    bounds = [-1.5,-1.5,r0-r0*0.1,0,r0-r0*0.1;...
        1.5,1.5,r0+r0*0.6,0.8,r0+r0*0.6];
    liste_param = gaussEllipticMLE(im_part,guess,bounds,options);
    end   
    liste_param(1:2) = liste_param(1:2)+[Pi Pj];    
else
    %limits for optimization
    bornes_ijr(1) = -optim(5) ;
    bornes_ijr(2) = optim(5) ;
    bornes_ijr(3) = -optim(5) ;
    bornes_ijr(4) = optim(5) ;
    bornes_ijr(5) = r0-optim(4)*r0/100 ;
    bornes_ijr(6) = r0+optim(4)*r0/100 ;
    
    r = r0 ;
    i = 0.0 ;
    j = 0.0 ;
    dr = 1 ;
    di = 1 ;
    dj = 1 ;
    fin = 10^optim(2) ;
    sig2 = inf ;
    cpt = 0 ;
    test = 1 ;
    ITER_MAX = optim(1) ;
    while (test)
        %%[r, i, j, dr, di, dj, alpha, sig2] = deplt_GN_estimation (r, i, j, im_part) ;
        [r, i, j, dr, di, dj, alpha, sig2, offset] = deplt_GN_estimation (r, i, j, im_part, sig2, dr, di, dj, optim) ;
        cpt = cpt + 1 ;
        if optim(3)
            test = max([abs(di), abs(dj), abs(dr)]) > fin ;
        else
            test = max([abs(di), abs(dj)]) > fin ;
        end %if
        if (cpt > ITER_MAX)
            test = 0 ;
        end%if
        
        %% on stop si l_on sort des bornes
        result_ok = ~((i < bornes_ijr(1)) || (i > bornes_ijr(2)) || ...
            (j < bornes_ijr(3)) || (j > bornes_ijr(4)) || ...
            (r < bornes_ijr(5)) || (r > bornes_ijr(6)) ) ;
        test = test & result_ok ;
        
    end%while
    
    
    % liste_info_param = [num, i, j, alpha, sig^2]
    % liste_param = [num, i, j, alpha, sig^2, rayon, ok]
    
    liste_param = [Pi+i , ... %y-coordinate
        Pj+j , ... %x-coordinate
        alpha , ... %mean amplitude
        sig2 , ... %noise power
        offset, ... %background level
        r , ... %r0
        result_ok ];
end %if

function [n_r, n_i, n_j, dr, di, dj, alpha, sig2 m] = ...
    deplt_GN_estimation(p_r, p_i, p_j, x, sig2init, p_dr, p_di, p_dj, optim)

%%  p_di, p_dj les precedents deplacements
%% qui ont conduit a p_r, p_i, p_j

r0 = p_r ;
i0 = p_i ;
j0 = p_j ;
prec_rel = 10^optim(2) ;

verif_crit = 1 ;
pp_r = r0 - p_dr ;
pp_i = i0 - p_di ;
pp_j = j0 - p_dj ;

[wn_i, wn_j] = size(x) ;
N = wn_i * wn_j ;
refi = 0.5 + (0:(wn_i-1)) - wn_i/2 ;
refj = 0.5 + (0:(wn_j-1)) - wn_j/2 ;

%% on boucle, en diminuant les deplacements
%% tand que le nouveau critere en plus grand
again = 1 ;
loops = 0;
while (again)
    
    loops = loops + 1;
    i = refi - i0 ;
    j = refj - j0 ;
    ii = i' * ones(1,wn_j) ; %'
    jj = ones(wn_i,1) * j ;
    
    %% puissance unitaire
    iiii = ii.*ii ;
    jjjj = jj.*jj ;
    iiii_jjjj = iiii + jjjj ;
    g = (1/(sqrt(pi)*r0)) * exp(-(1/(2*r0^2))*(iiii_jjjj)) ;
    gc = g - sum(g(:))/N ;
    Sgc2 = sum(gc(:).^2) ;
    g_div_sq_r0 = inv(r0^2) * g ;
    
    %% alpha estime MV
    if (Sgc2 ~= 0)
        alpha = sum(sum(x .* gc)) / Sgc2 ;
    else
        alpha = 0 ;
    end%if
    %% m estime MV
    
    x_alphag = x - alpha.*g ;
    m = sum(sum(x_alphag))/N ;
    
    err = x_alphag - m ;
    
    %% critere avant deplacement
    sig2 = sum(sum(err.^2)) / N ;
    if ((verif_crit) && (sig2 > sig2init))
        p_di = p_di / 10.0 ;
        p_dj = p_dj / 10.0 ;
        i0 = pp_i + p_di ;
        j0 = pp_j + p_dj ;
        if optim(3)
            p_dr = p_dr / 10.0 ;
            r0 = pp_r + p_dr ;
        else
            p_dr = 0;
            r0 = pp_r;
        end %if
        if (max([abs(p_dr), abs(p_di), abs(p_dj)]) > prec_rel)
            %      if (max([abs(p_di), abs(p_dj)]) > prec_rel)
            n_r = p_r ;
            n_i = p_i ;
            n_j = p_j ;
            dr = 0 ;
            di = 0 ;
            dj = 0 ;
            return ;
        end%if
    else
        again = 0 ;
    end%if
    
    % to avoid getting stuck in this loop
    if (loops > 50)
        again = 0;
    end
    
end%while

%% der_g
der_g_i0 =  ii .* g_div_sq_r0 ;
der_g_j0 =  jj .* g_div_sq_r0 ;

%% derder_g
derder_g_i0 = (-1 + inv(r0^2)*iiii) .* g_div_sq_r0 ;
derder_g_j0 = (-1 + inv(r0^2)*jjjj) .* g_div_sq_r0 ;

%% der_J /2
der_J_i0 = alpha * sum(sum(der_g_i0 .* err)) ;
der_J_j0 = alpha * sum(sum(der_g_j0 .* err)) ;

%% derder_J /2
derder_J_i0 = alpha * sum(sum(derder_g_i0 .* err)) - alpha^2 * sum(sum(der_g_i0.^2)) ;
derder_J_j0 = alpha * sum(sum(derder_g_j0 .* err)) - alpha^2 * sum(sum(der_g_j0.^2)) ;

%% deplacement par Gauss-Newton
if optim(3)
    der_g_r0 = (-inv(r0) + inv(r0^3)*(iiii_jjjj)) .* g ;
    derder_g_r0 = (1 - 3*inv(r0^2)*iiii_jjjj) .* g_div_sq_r0 ...
        + (-inv(r0) + inv(r0^3)*(iiii_jjjj)) .* der_g_r0 ;
    der_J_r0 = alpha * sum(sum(der_g_r0 .* err)) ;
    derder_J_r0 = alpha * sum(sum(derder_g_r0 .* err)) - alpha^2 * sum(sum(der_g_r0.^2)) ;
    dr = - der_J_r0 / derder_J_r0 ;
    n_r = abs(r0 + dr) ; %% r0 > 0
else
    dr = 0;
    n_r = r0;
end %if

di = - der_J_i0 / derder_J_i0 ;
dj = - der_J_j0 / derder_J_j0 ;

n_i = i0 + di ;
n_j = j0 + dj ;

function output = deflat_part_est(input, liste_est, wn)

[idim, jdim] = size(input) ;
nb_part = size(liste_est, 1) ;

output = input ;

%% parametre dans liste_est :
%% liste_param = [num, i, j, alpha, sig^2, rayon, ok]

for part=1:nb_part
    if (liste_est(part, 7) == 1)
        i0 = liste_est(part, 1) ;
        j0 = liste_est(part, 2) ;
        alpha = liste_est(part, 3) ;
        r0 = liste_est(part, 6) ;
        wn = ceil(6*r0); % by CPR: 99% of Gaussian
        
        pos_i = round(i0) ;
        dep_i = i0 - pos_i ;
        pos_j = round(j0) ;
        dep_j = j0 - pos_j ;
        
        alpha_g = alpha * gausswin2(r0, wn, wn, dep_i, dep_j) ;
        
        dd = (1:wn) - floor(wn/2) ;
        di = dd + pos_i ;
        iin = di > 0 & di < idim+1;
                
        dj = dd + pos_j ;
        jin = dj > 0 & dj < jdim+1;
                
        output(di(iin), dj(jin)) = ...
            output(di(iin), dj(jin)) - alpha_g(iin,jin) ;
    end%if
end%for
