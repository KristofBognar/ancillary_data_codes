function get_trajectory_details( time_lim_in )
%GET_TRAJECTORY_DETAILS get info about each trajectory
%   
% For each trajectory in the flexpart database, this function saves:
%       trajectory length
%       mean mixing layer height
%       mean fraction of particles in the mixing layer
% Code loops over back trajectory lengths as specified in time_lim_in,
% default is [1:5]

% check for back trajectory lengths
if nargin==0
    time_lim_in=1:5;
end

% load saved flexpart data (use max length)
load(['/home/kristof/berg/FLEXPART_10.02/BrO_back_runs_v2/BrO_back_runs_v2_5day.mat'])

% flexpart times
load('/home/kristof/berg/FLEXPART_10.02/BrO_back_runs_v2/flexpart_times_2016-2019.mat')

% % set trajectory time required (days)
% time_lim=3;

% loop over trajectory lengths
for time_lim=time_lim_in

    % select lines withng that time period only
    time_good=(trajectories.time>=time_lim*(-3600*24));

    % get run indices (should just be 1:n)
    run_inds=unique(trajectories.index)';
    if ~isequal(run_inds,[1:max(run_inds)]), error('WTF'), end

    % initialize variables
    traj_len=NaN(length(run_inds),1); % length
    traj_hmix=NaN(length(run_inds),1); % mean mixing layer height
    traj_fmix=NaN(length(run_inds),1); % mean fraction of particles in mixing layer

    % loop over individual trajectories
    for i=run_inds

        % indices in current trajectory that are within required time limit
        ind_curr=find(trajectories.index==i & time_good);

        % calculate cummulative distance between each point along the clustered
        % trajectory (trajectory length)
        dist=0;
        for j=ind_curr(2:end)'

            tmp=dist_tmp(trajectories.lat(j-1),trajectories.lon(j-1),...
                         trajectories.lat(j),trajectories.lon(j));

            dist=dist+tmp;   

        end

        % save trajectory length
        traj_len(i)=dist;

        % average mixing layer height
        traj_hmix(i)=mean(trajectories.mixing_height(ind_curr));

        % average fraction of particles in mixing layer
        traj_fmix(i)=mean(trajectories.frac_mix_layer(ind_curr));

    end

    % assign results
    traj_details=table();

    traj_details.run_times=run_times';
    traj_details.run_start=run_start';
    traj_details.run_end=run_end';
    traj_details.length=traj_len;
    traj_details.mixing_height=traj_hmix;
    traj_details.frac_in_mix=traj_fmix;

    % save results

    save(['/home/kristof/work/BEEs/trajectory_details/FP_trajectory_details_' ...
          num2str(time_lim) 'day.mat'],'traj_details')
     
end

end

function dist_km=dist_tmp(loc1_lat,loc1_lon,loc2_lat,loc2_lon)

    % calculate arc lengths
    [arclen,~]=distance(loc1_lat,loc1_lon, loc2_lat, loc2_lon);

    % calculate distances
    R_e = 6378.1;
    dist_km = arclen * (pi/180) * R_e;

end