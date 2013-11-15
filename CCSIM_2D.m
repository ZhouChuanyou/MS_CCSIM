% -----------------------------------------------------------------------------
% This function can be used for both 2D unconditional and conditional
% MS-CCSIM. For using in unconditional mode, the hd should be just NaN
% value.

% Reference: Tahmasebi, P., Sahimi, M., Caers, J., 2013. 
% MS-CCSIM: accelerating pattern-based geostatistical simulation of 
% categorical variables using a multi-scale search in Fourier space
% functions, Computers & Geosciences, 


% Author: Pejman Tahmasebi
% E-mail: pejman@stanford.edu
% Stanford Center for reservoir Forecasting, Stanford University.
% -----------------------------------------------------------------------*/
% 
function [ C ] = CCSIM_2D(ti, hd, T, OL, CT, fc, prop, rad, cand, mrp, ms_level, real_numb)


%% Input Parameters
% - ti: Training image
% - hd: Hard data matrix
% - T: Template size
% - OL: Overlap size
% - CT: Size of Co-Template (e.g. [2 2])
% - fc: Number of facies (if fc = 0, histogram matching will not apply; default is 0)
% - prop: The proportion of TI which will be scanned to find the matched hard data (0 < prop <=1))
% - rad: Neighbourhood radius for MS simulation (default is [1 1])
% - cand: Number of candidates for pattern pool
% - mrp: Multiple random path flag (1:on, 0:off).
% - ms_level: Number of MS level (1, 2, 3).
% - real_numb: Number of the realizations

%% Output Parameters
% - C: Simulation grid for output

%%

sizeout_orig = size(hd);

HD1_1 = hd; ti1_1 = ti;
HD2_1 = flipdim(HD1_1,1); ti2_1 = flipdim(ti1_1,1);
HD3_1 = flipdim(HD1_1,2); ti3_1 = flipdim(ti1_1,2);
HD4_1 = flipdim(flipdim(HD1_1,1),2); ti4_1 = flipdim(flipdim(ti1_1,1),2);
if mrp == 1
    HD5_1 = HD1_1'; ti5_1 = ti1_1';
    HD6_1 = HD3_1'; ti6_1 = ti3_1';
end

sizeout(1) = sizeout_orig(1) + 2*(T);
sizeout(2) = sizeout_orig(2) + 2*(T);

HD = NaN(sizeout(1),sizeout(1));

HD_temp = HD; HD_temp(1:size(hd,1),1:size(hd,2)) = HD1_1; HD1_1 = HD_temp;
HD_temp = HD; HD_temp(1:size(hd,1),1:size(hd,2)) = HD2_1; HD2_1 = HD_temp;
HD_temp = HD; HD_temp(1:size(hd,1),1:size(hd,2)) = HD3_1; HD3_1 = HD_temp;
HD_temp = HD; HD_temp(1:size(hd,1),1:size(hd,2)) = HD4_1; HD4_1 = HD_temp;

lag = 4;

if mrp == 1
    sizeout(1) = sizeout_orig(1) + 4*(T);
    sizeout(2) = sizeout_orig(2) + 4*(T);
    
    HD = NaN(sizeout(1),sizeout(2));
    
    HD_temp = HD; HD_temp(2*T+1:2*T+size(hd,1),2*T+1:2*T+size(hd,2)) = HD5_1; HD5_1 = HD_temp;
    HD_temp = HD; HD_temp(2*T+1:2*T+size(hd,1),2*T+1:2*T+size(hd,2)) = HD6_1; HD6_1 = HD_temp;
        
    lag = 6;
end;

C = zeros(numel(hd),1);

    
HD1_2 = hd_resize_2D(HD1_1, size(HD1_1)/2); ti1_2 = ti_resize_2D(ti1_1, size(ti1_1)/2);
HD2_2 = hd_resize_2D(HD2_1, size(HD2_1)/2); ti2_2 = ti_resize_2D(ti2_1, size(ti2_1)/2); 
HD3_2 = hd_resize_2D(HD3_1, size(HD3_1)/2); ti3_2 = ti_resize_2D(ti3_1, size(ti3_1)/2); 
HD4_2 = hd_resize_2D(HD4_1, size(HD4_1)/2); ti4_2 = ti_resize_2D(ti4_1, size(ti4_1)/2);
if mrp == 1
    HD5_2 = hd_resize_2D(HD5_1, size(HD5_1)/2); ti5_2 = ti_resize_2D(ti5_1, size(ti5_1)/2); 
    HD6_2 = hd_resize_2D(HD6_1, size(HD6_1)/2); ti6_2 = ti_resize_2D(ti6_1, size(ti6_1)/2);    
end
    
    
HD1_3 = hd_resize_2D(HD1_1, size(HD1_1)/4); ti1_3 = ti_resize_2D(ti1_1, size(ti1_1)/4);
HD2_3 = hd_resize_2D(HD2_1, size(HD2_1)/4); ti2_3 = ti_resize_2D(ti2_1, size(ti2_1)/4); 
HD3_3 = hd_resize_2D(HD3_1, size(HD3_1)/4); ti3_3 = ti_resize_2D(ti3_1, size(ti3_1)/4); 
HD4_3 = hd_resize_2D(HD4_1, size(HD4_1)/4); ti4_3 = ti_resize_2D(ti4_1, size(ti4_1)/4);
if mrp == 1
    HD5_3 = hd_resize_2D(HD5_1, size(HD5_1)/4); ti5_3 = ti_resize_2D(ti5_1, size(ti5_1)/4); 
    HD6_3 = hd_resize_2D(HD6_1, size(HD6_1)/4); ti6_3 = ti_resize_2D(ti6_1, size(ti6_1)/4);
end
       

h = waitbar(0, sprintf('CCSIM is running ... %i realization(s)', real_numb), ...
    'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0)

R1 = 1:lag:real_numb;
R2 = 2:lag:real_numb;
R3 = 3:lag:real_numb;
R4 = 4:lag:real_numb;
R5 = 0;
R6 = 0;
if mrp == 1
    R5 = 5:lag:real_numb;
    R6 = 6:lag:real_numb;
end



for i = 1:real_numb
    
    if getappdata(h,'canceling')
        break
    end    
    
%     if any(R1==i)
%         T_new = T+4; OL_new = OL;
%     elseif any(R2==i)
%         T_new = T-4; OL_new = OL;
%     elseif any(R3==i)
%         T_new = T; OL_new = OL;
%     end;

    if any(R1==i)
        hd0 = HD1_1; ti0 = ti1_1;
        hd1 = HD1_2; ti1 = ti1_2;
        hd2 = HD1_3; ti2 = ti1_3;
        
    elseif any(R2==i)
        hd0 = HD2_1; ti0 = ti2_1;
        hd1 = HD2_2; ti1 = ti2_2;
        hd2 = HD2_3; ti2 = ti2_3;        
        
    elseif any(R3==i)
        hd0 = HD3_1; ti0 = ti3_1;
        hd1 = HD3_2; ti1 = ti3_2;
        hd2 = HD3_3; ti2 = ti3_3;
        
    elseif any(R4==i)
        hd0 = HD4_1; ti0 = ti4_1;
        hd1 = HD4_2; ti1 = ti4_2;
        hd2 = HD4_3; ti2 = ti4_3;
        
    elseif any(R5==i)
        hd0 = HD5_1; ti0 = ti5_1;
        hd1 = HD5_2; ti1 = ti5_2;
        hd2 = HD5_3; ti2 = ti5_3;
        
    elseif any(R6==i)
        hd0 = HD6_1; ti0 = ti6_1;
        hd1 = HD6_2; ti1 = ti6_2;
        hd2 = HD6_3; ti2 = ti6_3;        
    end;

    
    tStart = tic;
    if ms_level ==1
        [MS0, ~] = CCSIM_2D_MS2(ti0, hd0, T, OL, CT, fc, prop, cand);
    elseif ms_level==2
        [~, LOC1] = CCSIM_2D_MS2(ti1, hd1, T/2, OL/2, CT, fc, prop, cand);
        [MS0, ~] = CCSIM_2D_MS1(ti0, hd0, LOC1, T, OL, rad);
    else
        [~, LOC2] = CCSIM_2D_MS2(ti2, hd2, T/4, OL/4, CT, fc, prop, cand);
        [~, LOC1] = CCSIM_2D_MS1(ti1, hd1, LOC2, T/2, OL/2, rad);
        [MS0, ~] = CCSIM_2D_MS1(ti0, hd0, LOC1, T, OL, rad);
    end;
    
    tEnd = toc(tStart);
    
    
            
    if any(R2==i)
        MS0 = MS0(1:size(hd,1),1:size(hd,2));
        MS0 = flipdim(MS0,1);   
        
    elseif any(R3==i)
        MS0 = MS0(1:size(hd,1),1:size(hd,2));
        MS0 = flipdim(MS0,2);
        
    elseif any(R4==i)
        MS0 = MS0(1:size(hd,1),1:size(hd,2));
        MS0 = flipdim(flipdim(MS0,1),2);
        
    elseif any(R5==i)
        MS0 = MS0(2*T+1:2*T+size(hd,1),2*T+1:2*T+size(hd,2));
        MS0 = MS0';
        
    elseif any(R6==i)
        MS0 = MS0(2*T+1:2*T+size(hd,1),2*T+1:2*T+size(hd,2));
        MS0 = MS0';
        MS0 = flipdim(MS0,2);
    else
        MS0 = MS0(1:size(hd,1),1:size(hd,2));
    end;    

    C(:,i) = MS0(:);


    waitbar(i / real_numb, h, sprintf('CCSIM is running...Please wait...%ith realization completed', i))
    
    disp(['********  CPU time for a grid size of ',num2str(size(HD,1)),'x',...
        num2str(size(HD,2)), 'x',num2str(size(HD,3)), ' is ', num2str(tEnd),...
        '  (s) ********'])
    
    subplot(1,2,1); imagesc(ti); axis equal tight xy; colormap gray
    subplot(1,2,2); imagesc(MS0); axis equal tight xy; colormap gray
end;


delete(h)

end
