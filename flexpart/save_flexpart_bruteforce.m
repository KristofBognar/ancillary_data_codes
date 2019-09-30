function save_flexpart_bruteforce(time_lim_in,do_weekly)
%save_flexpart(time_lim,do_weekly) Read and save FLEXPART output
%   
% INPUT: time_lim: number of days to save for each back trajectory. Can be
%                  single number, or list of numbers between 1 and 5
%                  (FLEXPART set up for 5 day back trajectories)

% load sea ice age data
load('/home/kristof/work/BEEs/sea_ice_data/EASE_grid_SI_age.mat');
week_times=date_age;

clearvars -except time_lim_in do_weekly week_times

% no weekly calculations
if nargin==1, do_weekly=0; end

% set up weekly calculations
if do_weekly
    sens_info=[]; 
    sens_info_tmp=table;
end


for time_lim=time_lim_in

    % data folders
    flex_dir='/home/kristof/atmosp_servers/export/data/home/kbognar/FLEXPART_10.02/';
    flex_folder='BrO_back_runs_v1';

    cd([flex_dir flex_folder]);

    % get directory list
    tmp = dir('out_*'); 
    dir_list = {tmp.name}; % cell array of file names

    % initialize variables
    trajectories=[];

    if do_weekly
        sensitivities=[];
    else
        sensitivities=NaN(180,720,length(dir_list));
    end

    %%% loop over output folders
    n=0;
    for i=1:length(dir_list)
        %% display progress info
        disp_str=['Reading ' dir_list{i} ', saving ' num2str(time_lim) ...
                  ' day back trajectories'];
        % stuff to delete last line and reprint updated message
        fprintf(repmat('\b',1,n));
        fprintf(disp_str);
        n=numel(disp_str);    

        cd([flex_dir flex_folder '/' dir_list{i}]);

        %% read trajectories
        traj_tmp=dlmread('trajectories.txt','',5,0);
        traj_tmp=array2table(traj_tmp,'VariableNames',...
            {'rel_num','time','lon','lat','alt','topography','mixing_height',...
             'tropopause','PV_ind','rms_dist','rms','zrms_dist','zrms',...
             'frac_mix_layer','frac_pv_2pvu','frac_in_trop',...
             'c1_lon','c1_lat','c1_alt','c1_frac','c1_rms',...
             'c2_lon','c2_lat','c2_alt','c2_frac','c2_rms',...
             'c3_lon','c3_lat','c3_alt','c3_frac','c3_rms',...
             'c4_lon','c4_lat','c4_alt','c4_frac','c4_rms',...
             'c5_lon','c5_lat','c5_alt','c5_frac','c5_rms',...
             });

        % filter by the number of days
        traj_tmp(traj_tmp.time<time_lim*(-3600*24),:)=[];

        % add index and end time (date when trajectories end at Eureka; data
        % goes back in time from there)
        traj_tmp.ends_on=repelem(datetime(dir_list{i}(5:end),...
                            'InputFormat','yyyyMMdd_HHmmss'),size(traj_tmp,1))';
        traj_tmp.index=repelem(i,size(traj_tmp,1))';

        % save
        trajectories=[trajectories; traj_tmp];

        %% find where current run falls if times are provided
        if do_weekly

            % sort start time into datetime array
            % start time is given by trajectory end date minus desired back
            % trajectory length
            start_time_tmp=traj_tmp.ends_on(1)-days(time_lim);
            [~,tmp]=sort([week_times;start_time_tmp]);

            % end of the first (or only) week that contains the given
            % trajectories
            week_end=find(tmp==length(week_times)+1);

            % time difference between run start and start of next week (to check if
            % run covers two weeks)
            tmp=hours(week_times(week_end) - start_time_tmp);

            if tmp>time_lim*24 % don't split run results
                split_ind=0;
            else
                % split the data based in the number of hours in each week
                % since time runs backwards, indices 1:split_ind should go to
                % next week, and inds split_ind+1:end should go to the current week
                %%% no interpolation, just split at nearest hour
                split_ind=time_lim*24-round(tmp);
            end

        end

        %% read sensitivity
        % get netCDF filename (only one file per run)
        tmp = dir('*.nc'); 
        f_nc = {tmp.name}; % cell array of file names

        % read time and coordinates:
        % they don't change for individual runs, read only once
        if i==1
            % (lon x lat x alt x time x pointspec x nageclass)
            time=double(ncread(f_nc{1},'time')); 
            latitude=double(ncread(f_nc{1},'latitude'));
            longitude=double(ncread(f_nc{1},'longitude'));

            % filter by number of days
            time_ind=find(time>=time_lim*(-3600*24));
            time=time(time_ind);

            max_time_ind=max(time_ind);

            if unique(diff(time))~=-3600, error('Code assumes 1h timestep'); end

        end

        % read tracer data
        tracer=double(ncread(f_nc{1},'spec001_mr'));
        % remove extra dimensions
        % (lon x lat x time), only works if single altitude is used!
        tracer=squeeze(tracer);

        sens_info_tmp=table;

        if ~do_weekly % get total sensitivity for run

            % sum over time
            tracer_tmp=sum(tracer(:,:,time_ind),3)';

            % save
            sensitivities(:,:,i)=tracer_tmp;

        elseif split_ind==0 % get total sensitivity for run if all within one week

            tracer_tmp=sum(tracer(:,:,time_ind),3)';
            sensitivities=cat(3,sensitivities,tracer_tmp);

            % save number of run (only one entry, since all within a week)
            % save corresponding SI data index
            sens_info_tmp.run_index=i;
            sens_info_tmp.week_index=week_end-1;
            sens_info=[sens_info;sens_info_tmp];

        else

            % first part of run (time goes backwards, later indices are the
            % earlier times)
            tracer_tmp=sum(tracer(:,:,split_ind+1:max_time_ind),3)';
            sensitivities=cat(3,sensitivities,tracer_tmp);

            % part that falls on next week (time goes backwards, earlier indices
            % are the later times)
            tracer_tmp=sum(tracer(:,:,1:split_ind),3)';
            sensitivities=cat(3,sensitivities,tracer_tmp);

            % save index twice for two entries in 'sensitivities'
            % save corresponding SI data indices
            sens_info_tmp.run_index=[i;i];
            sens_info_tmp.week_index=[week_end-1;week_end];
            sens_info=[sens_info;sens_info_tmp];

        end

    end

    fprintf('\n');
    fprintf('Done\n');

    cd([flex_dir flex_folder]);

    if ~do_weekly
        save([flex_folder '_' num2str(time_lim) 'day.mat'],...
             'trajectories','sensitivities','time','latitude','longitude')
    else
        save([flex_folder '_' num2str(time_lim) 'day__weekly_sum.mat'],...
             'trajectories','sensitivities','time','latitude','longitude',...
             'sens_info','week_times')
    end

end
end

    
