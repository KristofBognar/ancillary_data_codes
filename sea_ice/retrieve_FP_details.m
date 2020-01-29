function data_out = retrieve_FP_details( data_type, prof_times, bt_len, interp_type, surf_type )
%data_out = retrieve_FP_details( prof_times, bt_len, si_age ) 
%
% Returns sea ice/water/land contact for the given BrO profile
% Use get_SI_contact.m to extract contact times from FLEXPART back
% trajectories and sea ice age data
%
% INPUT:
%   data_type: data to interpolate
%       'traj_len': back trajectory length
%       'traj_hmix': back trajectory mean mix layer height
%       'traj_fmix: back trajectory mean fraction of particles in mixed layer
%       'SI_approx': SI contact, mean over all SI areas * number of cells
%       'SI_exact': SI contact, sum of the means in individual SI cells
%
%       Data type can be any per trajectory detail for the FLEXPART
%       dataset, but input must have the 'run_times', 'run_start', and
%       'run_end' fields corresponding to the initialixation times of the
%       FLEXPART runs (in e.g. flexpart_times_2015-2019.mat)
%
%   prof_times: times to match to start interval of FLEAXPART run 
%   bt_len: length of back trajectory used to save the data (1-5)
%   interp_type:
%       'nearest': same value is returned for all prof_times within the
%                  start interval
%       'linear': contact times are linearly intepolated for each day, and
%                 profiles before the first (after the last) FLEXPART run
%                 are held constant (to avoid negative values for sharp
%                 slopes)
%   surf_type: 'FYSI', 'MYSI', 'water', 'land' (only for data_type=SI_*)
%
% OUTPUT: interpolated data, same size as prof_times
%
%@Kristof Bognar, 2019
%@Kristof Bognar, 2020: modified to be more general instead of focusing
%                        on SI contact


%% load data

if strcmp(data_type(1:2),'SI')

    si_file=['FP_' surf_type '_contact_' num2str(bt_len) 'day.mat'];

    if strcmp(data_type,'SI_exact')
        load(['/home/kristof/work/BEEs/flexpart_SI_contact/' si_file]);
    elseif strcmp(data_type,'SI_approx')
        load(['/home/kristof/work/BEEs/flexpart_SI_contact/approximate/' si_file]);
    end
    
    times_in=FP_SI_contact;
    data_in=FP_SI_contact.contact;
    
elseif strcmp(data_type(1:4),'traj')

    load(['/home/kristof/work/BEEs/trajectory_details/FP_trajectory_details_'...
          num2str(bt_len) 'day.mat'])
    
    times_in=traj_details;
    
    if strcmp(data_type,'traj_len')
        data_in=traj_details.length;
    elseif strcmp(data_type,'traj_hmix')
        data_in=traj_details.mixing_height;
    elseif strcmp(data_type,'traj_fmix')
        data_in=traj_details.frac_in_mix;
    end
    
else
    error('see documentation for valid data_type entries')
end

%% define output

data_out=NaN(size(prof_times));

%% find nearest FP run for each profile time

% time diff of each profile to nearest FP run (in hours)
t_diffs=min(abs(bsxfun(@minus,datenum(times_in.run_times),datenum(prof_times)')))*24;

% max halfwidth of FP run windows (in hours)
FP_max_diff=hours((max(times_in.run_end-times_in.run_start)/2));


%% find contact value

switch interp_type

    % get nearest contact value from flexpart runs -- each profile within
    % flexpart run start window will have the same output
    case 'nearest'
        
        % get rid of profiles that are not actually part of a flexpart run
        % (single measurements far from other data)
        % any profile that's farther from an FP run than the max should be
        % excluded, since no FP runs were performed for those measurements (this
        % might still let some datapoints slip, but if they are closer than ~2h to a
        % FP run, then it doesn't matter)
        
        good_ind=(t_diffs<=FP_max_diff);
        
        % calculate contact time for selected profiles
        data_out(good_ind)=interp1(times_in.run_times,data_in,...
                                      prof_times(good_ind),interp_type,'extrap');
        
        
    case 'linear'
   
        % linear interpolation between FP contact values: interpolate each
        % day separatey, so the contact times for the profiles before/after
        % the first/last FP run mean time are extrapolated using values for
        % that day only (and not interpolated using the current day, and
        % the previous/next available measurement, which might be days
        % away)
        
        fp_ind=[];
        
        % lop over FP runs
        for i=1:length(data_in)
            
            % append current FP run index
            fp_ind=[fp_ind, i];
            
            % check if next FP run is the next day (end and start
            % dates should be the same for same day runs)
            if i<length(data_in)
                cond=times_in.run_end(i)~=times_in.run_start(i+1);
            else
                cond=1;
            end
            
            if cond
                % if next FP run is on the next day (or later), do
                % interpolation for all runs in current day
                
                % find corresponding profile times
                % extend window by +-1 min; times that look the same might
                % differ on sub-second scales
                good_ind=(prof_times>=times_in.run_start(fp_ind(1))-minutes(1) & ...
                          prof_times<=times_in.run_end(fp_ind(end))+minutes(1));
                
                if length(fp_ind)==1
                    
                    % constant value
                    data_out(good_ind)=data_in(fp_ind);
                    
                else
                    
                    % interpolate data, no extrapolation
                    data_out(good_ind)=interp1(times_in.run_times(fp_ind),...
                                                  data_in(fp_ind),...
                                                  prof_times(good_ind),interp_type);
                    
                    % extrapolate data, with constant values
                    good_ind=(good_ind & isnan(data_out));
                    data_out(good_ind)=interp1(times_in.run_times(fp_ind),...
                                                  data_in(fp_ind),...
                                                  prof_times(good_ind),'nearest','extrap');
                    
                end
                
                % restart FP run index
                fp_ind=[];
                
            end
            
        end
        
%         % remove point far from FP runs, just in case
%         contact_out(t_diffs>FP_max_diff)=[];
        
end




end

