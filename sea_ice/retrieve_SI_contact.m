function contact_out = retrieve_SI_contact( contact_type, prof_times, bt_len, surf_type, interp_type )
%contact_interp = retrieve_SI_contact( prof_times, bt_len, si_age ) 
%
% Returns sea ice/water/land contact for the given BrO profile
% Use get_SI_contact.m to extract contact times from FLEXPART back
% trajectories and sea ice age data
%
% INPUT:
%   contact_type: how SI contact was calculated
%       'approx': SI contact is mean over all SI areas * number of cells
%       'exact': SI contact is sum of the means in individual SI cells
%   prof_times: times to match to start interval of FLEAXPART run 
%   bt_len: length of back trajectory used to save SI contact (1-5)
%   surf_type: 'FYSI', 'MYSI', 'water', 'land'
%   interp_type:
%       'nearest': same value is returned for all prof_times within the
%                  start interval
%       'linear': contact times are linearly intepolated for each day, and
%                 profiles before the first (after the last) FLEXPART run
%                 are held constant (to avoid negative values for sharp
%                 slopes)
%
% OUTPUT: interpolated contact data, same size as prof_times
%
%@ Kristof Bognar, 2019


%% load data

si_file=['FP_' surf_type '_contact_' num2str(bt_len) 'day.mat'];

if strcmp(contact_type,'exact')
    load(['/home/kristof/work/BEEs/flexpart_SI_contact/' si_file]);
elseif strcmp(contact_type,'approx')
    load(['/home/kristof/work/BEEs/flexpart_SI_contact/approximate/' si_file]);
else
    error('contact_type must be exact or approx')
end

%% define output

contact_out=NaN(size(prof_times));

%% find nearest FP run for each profile time

% time diff of each profile to nearest FP run (in hours)
t_diffs=min(abs(bsxfun(@minus,datenum(FP_SI_contact.run_times),datenum(prof_times)')))*24;

% max halfwidth of FP run windows (in hours)
FP_max_diff=hours((max(FP_SI_contact.run_end-FP_SI_contact.run_start)/2));


%% find contact value

switch interp_type

    % get nearest contact value from flexpart runs -- each profile within
    % flexpart run start window will have the same SI contact
    case 'nearest'
        
        % get rid of profiles that are not actually part of a flexpart run
        % (single measurements far from other data)
        % any profile that's farther from an FP run than the max should be
        % excluded, since no FP runs were performed for those measurements (this
        % might still let some datapoints slip, but if they are closer than ~2h to a
        % FP run, then it doesn't matter)
        
        good_ind=(t_diffs<=FP_max_diff);
        
        % calculate contact time for selected profiles
        contact_out(good_ind)=interp1(FP_SI_contact.run_times,FP_SI_contact.contact,...
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
        for i=1:length(FP_SI_contact.contact)
            
            % append current FP run index
            fp_ind=[fp_ind, i];
            
            % check if next FP run is the next day (end and start
            % dates should be the same for same day runs)
            if i<length(FP_SI_contact.contact)
                cond=FP_SI_contact.run_end(i)~=FP_SI_contact.run_start(i+1);
            else
                cond=1;
            end
            
            if cond
                % if next FP run is on the next day (or later), do
                % interpolation for all runs in current day
                
                % find corresponding profile times
                good_ind=(prof_times>=FP_SI_contact.run_start(fp_ind(1)) & ...
                          prof_times<=FP_SI_contact.run_end(fp_ind(end)));
                
                if length(fp_ind)==1
                    
                    % constant value
                    contact_out(good_ind)=FP_SI_contact.contact(fp_ind);
                    
                else
                    
                    % interpolate SI contact, no extrapolation
                    contact_out(good_ind)=interp1(FP_SI_contact.run_times(fp_ind),...
                                                  FP_SI_contact.contact(fp_ind),...
                                                  prof_times(good_ind),interp_type);
                    
                    % extrapolate SI contact, with constant values
                    good_ind=(good_ind & isnan(contact_out));
                    contact_out(good_ind)=interp1(FP_SI_contact.run_times(fp_ind),...
                                                  FP_SI_contact.contact(fp_ind),...
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

