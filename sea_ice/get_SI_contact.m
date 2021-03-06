function get_SI_contact(bt_len,age_yr,fp_version)
%get_SI_contact(age_yr) total sea ice contact for FLEXPART back
%trajectories based on EASE-grid sea ice age data
%
% Code calculates overall sensitivity to the part of the Arctic
% Ocean covered by ice of a specified age, and simply multiplies by the
% total SI area
%
% INPUT: bt_len: length of back trajectories in days (loads appropriate file)
%        age_yr (optional): what we want the overall sensitivity to.
%           1 -- first year sea ice (default)
%           2 -- multi-year sea ice
%           0 -- open water (excluding ocean mask in SI age data)
%          20 -- land (using land mask in SI age data)
%        fp_version: folder name of current FLEXPART run version (e.g. 'BrO_back_runs_v2')
%
% OUTPUT: file with vector of contact times in seconds, corresponding to the
%         number of FLEXPART runs. Naming is FYSI, MYSI, water, and land,
%         corresponding to the indices above
%
% WARNING: Code takes a while, since it interpolates/matches indices 
%          using a 6000 x 14400 array for every FLEXPART run
%
%                          %%%%%%%%%%%%%%%
%
% Code uses pre-calculated grid mapping that assigns the linear
% index of each SI age grid cell to a finer version of the FLEXPART grid.
%       SI age is in azimuthal equal area coordinates
%       FLEXPART is in lat-lon coordinates
% FLEXPART grid was subdivided into 0.01° (lat) x 0.025° (lon) grid, grid
% centres were converted to x-y coordinates in equal area projection, and
% each small FLEXPART cell was agssigned the index of the SI age grid cell
% it falls into. What's used here is the mask that relates the fine
% FLEXPART grid to the SI age grid
%
% @Kristof Bognar, 2019


if nargin<3
    if nargin==1, age_yr=1; end
    fp_version='BrO_back_runs_v2';
end

if ~any(age_yr==[0,1,2,20])
    error('Valid SI age indices are 0,1,2, and 20')
end


%% load data

% EASE-grid is 12.5x12.5 km (12.534 km), on an equal area grid,
% coordinates in the .nc files are grid centres
load('/home/kristof/work/BEEs/sea_ice_data/EASE_grid_SI_age.mat')

lat_age=lat_age';
lon_age=lon_age';

% FLEXPART was run using a NH 0.5°x0.5° grid
% coords are cell centres, bottom left of grid is lat=0, lon=-179

% need to load *__weekly_data, with total sensitivities calculated not only for
% each run, but for each week as well if run stretches across two weeks
load(['/home/kristof/berg/FLEXPART_10.02/' fp_version '/' fp_version '_'...
      num2str(bt_len) 'day__weekly_sum.mat'])
% load fine flexpart grid
load('/home/kristof/berg/FLEXPART_10.02/grid_data/fine_FLEXPART_grid.mat')

% mask for fine FLEXPART grid, matches each cell to linear index of
% transpose of age array
load('/home/kristof/berg/FLEXPART_10.02/grid_data/FP_fine_mask.mat')

% flexpart times
if strcmp(fp_version, 'BrO_back_runs_v1')
    load('/home/kristof/berg/FLEXPART_10.02/BrO_back_runs_v1/flexpart_times_2015-2019.mat')
elseif strcmp(fp_version, 'BrO_back_runs_v2')
    load('/home/kristof/berg/FLEXPART_10.02/BrO_back_runs_v2/flexpart_times_2016-2019.mat')
end

% convert to 0-360, east of Greenwich
longitude(longitude<0)=longitude(longitude<0)+360;
lon_age(lon_age<0)=lon_age(lon_age<0)+360;

% switch FP grid center to 180 instead of 0
lon_tmp=[longitude(359:end);longitude(1:358)];

%% get SI/water/land contact

% initialize output array
% FP_SI_contact=NaN(max(sens_info.run_index),1);
FP_SI_contact=[];

% initialize map object
SI_age_inds=containers.Map(1,age(:,:,1));

n=0;
for i=1:size(sens_info,1)
    
    % display progress info
    disp_str=['Processing FLEXPART run ' num2str(i) '/' num2str(size(sens_info,1))...
              ' (' datestr(trajectories.end_on(...
              find(trajectories.index==sens_info.run_index(i),1))) ')'];
    % stuff to delete last line and reprint updated message
    fprintf(repmat('\b',1,n));
    fprintf(disp_str);
    n=numel(disp_str);    
    
    %% interpolate sensitivities
    % switch center to 180 instead of 0
    sens_tmp=[sensitivities(:,359:end,i),sensitivities(:,1:358,i)];
    % interpolate sensitivity to fine grid
    sens_fine=interp2(lon_tmp',latitude,sens_tmp,lon_FP_fine',lat_FP_fine);
    sens_fine(isnan(sens_fine))=0;

    %% get FYSI mask (or any age)
    % index of current week
    week_ind=sens_info.week_index(i);
    
    try % try to load mask (weeks repeat)
        
        SI_age_inds_current=SI_age_inds(week_ind);
        
    catch me % if current week hasn't been read in yet, do it
        
        if strcmp(me.identifier,'MATLAB:Containers:Map:NoKey')
            age_tmp=age(:,:,week_ind)'; % need transpose of current age array
            
            if age_yr==2 % MYSI, only one with multiple corresponding indices
                SI_age_inds(week_ind)=find(age_tmp>=2 & age_tmp<=16);
            else % FYSI, water, land mask
                SI_age_inds(week_ind)=find(age_tmp==age_yr);
            end
            
            SI_age_inds_current=SI_age_inds(week_ind);
            
        else % only catching noKey error above
            error('Something went wrong')
        end
        
    end
    
    % remove old indices (no more than two weeks are needed at a time)
    SI_age_keys=keys(SI_age_inds);
    if length(SI_age_keys)==3
        remove(SI_age_inds,SI_age_keys{1});
    end
    
    %% calculate contact time

    % linearize sens_fine and mask
    sens_lin=sens_fine(:);
    mask_lin=FP_fine_mask(:); % 3 cells from each corner of SI grid missing, doesn't matter here
    
    % select only mask indices that appear in SI_age_inds_current
    SI_contact_mask=ismember(mask_lin,SI_age_inds_current);
    
    % % select only nonzero sensitivities
    % error('removing zero elements not essential, fix bugs if it''s to be included')
    % nonzero=sens_lin>0; % can only remove zeros if entilre SI grid cell is 0!!
    % reduce arrays to selected elements
    % mask_lin=mask_lin(SI_contact_mask & nonzero);
    % sens_lin=sens_lin(SI_contact_mask & nonzero);
    
    mask_lin=mask_lin(SI_contact_mask);
    sens_lin=sens_lin(SI_contact_mask);
    
    if ~isempty(sens_lin)

        % redo indices in truncated mask such that unique elements start from
        % 1, and increase with no gaps -- necessary for splitapply
        [tmp,~,order]=unique(mask_lin);
        tmp=1:length(tmp);
        split_group=tmp(order)';

        % calculate mean sensitivity in each grid cell of interest, then add the values
        SI_contact_tmp=sum(splitapply(@mean,sens_lin,split_group));
    else
        % all cells with selected SI type have zero sensitivity
        SI_contact_tmp=0;
    end
    
% % %     error('Not a good way of calculating SI contact')
% % %     (overall mean * number of cells) is only equal to sum(mean of eac
% % %     cell) if each cell has the same number of points (not true here)
% % %     
% % %     SI_contact_mask=ismember(FP_fine_mask,SI_age_inds_current);
% % % 
% % %     % mean sensitivity over all FYSI covered regions x number of FYSI cells
% % %     % units: s
% % %     SI_contact_tmp=mean(sens_fine(SI_contact_mask)) * ...
% % %                      (length(SI_age_inds_current) );
    
    %% save FYSI contact
    
    % if same run but different SI age data, add the two numbers
    if i>1 && sens_info.run_index(i)==sens_info.run_index(i-1)
        FP_SI_contact(end)=FP_SI_contact(end)+SI_contact_tmp;
    else % if entire flexpart run is within one SI age timestep, save
        FP_SI_contact=[FP_SI_contact;SI_contact_tmp];
    end
    
end

% save corresponding times (each back trajectory corresponds to BrO
% profiles between run_start and run_end)
tmp=table();

tmp.run_times=run_times'; 
tmp.run_start=run_start';
tmp.run_end=run_end';
tmp.contact=FP_SI_contact;

FP_SI_contact=tmp;

if age_yr==1
    save(['/home/kristof/work/BEEs/flexpart_SI_contact/FP_FYSI_contact_'...
          num2str(bt_len) 'day.mat'],'FP_SI_contact')
elseif age_yr==2
    save(['/home/kristof/work/BEEs/flexpart_SI_contact/FP_MYSI_contact_'...
          num2str(bt_len) 'day.mat'],'FP_SI_contact')
elseif age_yr==0    
    save(['/home/kristof/work/BEEs/flexpart_SI_contact/FP_water_contact_'...
          num2str(bt_len) 'day.mat'],'FP_SI_contact')
elseif age_yr==20    
    save(['/home/kristof/work/BEEs/flexpart_SI_contact/FP_land_contact_'...
          num2str(bt_len) 'day.mat'],'FP_SI_contact')
end

fprintf('\n')

end

