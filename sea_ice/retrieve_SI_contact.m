function contact_out = retrieve_SI_contact( prof_times, bt_len, surf_type )
%contact_interp = retrieve_SI_contact( prof_times, bt_len, si_age ) 
%
% Returns sea ice/water/land contact for the given BrO profile
% Use get_SI_contact.m to extract contact times from FLEXPART back
% trajectories and sea ice age data
%
% INPUT:
%   prof_times: times to match to start interval of FLEAXPART run (same
%               value is returned for all prof_times within the start interval)
%   bt_len: length of back trajectory used to save SI contact (1-5)
%   surf_type: 'FYSI', 'MYSI', 'water', 'land'
%
% OUTPUT: interpolated contact data, same size as prof_times
%
%@ Kristof Bognar, 2019


%% load data

si_file=['FP_' surf_type '_contact_' num2str(bt_len) 'day.mat'];

load(['/home/kristof/work/BEEs/flexpart_SI_contact/' si_file]);


%% find contact value

% get nearest contact value from flexpart runs -- each profile within
% flexpart run start window should have the same SI contact (no
% linear interpolation)
contact=interp1(FP_SI_contact.run_times,FP_SI_contact.contact,prof_times,...
                'nearest','extrap');

%% get rid of profiles that are not actually part of a flexpart run
% (single measurements far from other data)

% time diff of each profile to nearest FP run (in hours)
t_diffs=min(abs(bsxfun(@minus,datenum(FP_SI_contact.run_times),datenum(prof_times)')))*24;

% max halfwidth of FP run windows (in hours)
FP_max_diff=hours((max(FP_SI_contact.run_end-FP_SI_contact.run_start)/2));

% any profile that's farther from an FP run than the max should be
% excluded, since no FP runs were performed for those measurements (this
% might still let some datapoints slip, but if they are closer than ~2h to a
% FP run, then it doesn't matter)
contact(t_diffs>FP_max_diff)=NaN;

contact_out=contact;

end

