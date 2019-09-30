function save_flexpart(time_lim_in,do_weekly)
%save_flexpart(time_lim,do_weekly) Read and save FLEXPART output
%   
% INPUT: time_lim: number of days to save for each back trajectory. Can be
%                  single number, or list of numbers between 1 and 5
%                  (FLEXPART set up for 5 day back trajectories)
%        do_weekly: for sea ice age data, back trajectoryes that cross into
%                   previous week are saved twice, with sensitivities for
%                   each week calculated separately
%
% OUTPUT: saved file with total sensitivities for each run, along with back
%         trajectory details. If do_weekly=1, table sens_info contains the
%         run indices to identify which sensitivity entries correspond to
%         parts of the same run, and which week the data is for.
%
% @Kristof Bognar, 2019

%% setup

% load sea ice age data
load('/home/kristof/work/BEEs/sea_ice_data/EASE_grid_SI_age.mat');
week_times=date_age;

clearvars -except time_lim_in do_weekly week_times

% no weekly calculations
if nargin==1, do_weekly=0; end

% data folders
flex_dir='/home/kristof/atmosp_servers/export/data/home/kbognar/FLEXPART_10.02/';
flex_folder='BrO_back_runs_v1';

cd([flex_dir flex_folder]);

% get directory list
tmp = dir('out_*'); 
dir_list = {tmp.name}; % cell array of file names


% check approx. memory requirements, cut off at 5 gig
array_mem=(180*720*length(dir_list)*length(time_lim_in))*8;
mem_lim=5*1024^3;

% limit size of array if too big: issue is likely the multiple back
% trajectory durations requested, cut off at number of durations that still
% fall within the limit
tmp=-1;
if do_weekly
    if array_mem*2 > mem_lim
        tmp=floor(mem_lim*length(time_lim_in)/(array_mem*2));
    end
else
    if array_mem > mem_lim
        tmp=floor(mem_lim*length(time_lim_in)/(array_mem));
    end
end

if tmp>0 
    
    if length(time_lim_in)==1,
        error('Cannot read data using a 5GB memory limit -- read it in chunks')
    end
    
    time_lim_in=time_lim_in(1:tmp);
    disp(time_lim_in)
    warning(['Not enough memory, only reading durations displayed above'])
    
end


% initialize variables
trajectories_all=[];

if do_weekly
    sensitivities_all=NaN(180,720,length(dir_list)*2,length(time_lim_in));
    sens_info_all=NaN(length(dir_list)*2,2,length(time_lim_in)); 
else
    sensitivities_all=NaN(180,720,length(dir_list),length(time_lim_in));
end

%% loop over output folders
n=0;
split_count=ones(size(time_lim_in));
for i=1:length(dir_list)
    %% display progress info
    disp_str=['Reading ' dir_list{i} ];
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
%     traj_tmp(traj_tmp.time<time_lim*(-3600*24),:)=[];

    % add index and end time (date when trajectories end at Eureka; data
    % goes back in time from there)
    traj_tmp.end_on=repelem(datetime(dir_list{i}(5:end),...
                        'InputFormat','yyyyMMdd_HHmmss'),size(traj_tmp,1))';
    traj_tmp.index=repelem(i,size(traj_tmp,1))';

    % save
    trajectories_all=[trajectories_all; traj_tmp];

    %% read sensitivity
    % get netCDF filename (only one file per run)
    tmp = dir('*.nc'); 
    f_nc = {tmp.name}; % cell array of file names

    % read time and coordinates:
    % they don't change for individual runs, read only once
    if i==1
        % (lon x lat x alt x time x pointspec x nageclass)
        time_all=double(ncread(f_nc{1},'time')); 
        latitude=double(ncread(f_nc{1},'latitude'));
        longitude=double(ncread(f_nc{1},'longitude'));


        if unique(diff(time_all))~=-3600, error('Code assumes 1h timestep'); end

    end

    % read tracer data
    tracer=double(ncread(f_nc{1},'spec001_mr'));
    % remove extra dimensions
    % (lon x lat x time), only works if single altitude is used!
    tracer=squeeze(tracer);

    count=1;
    for time_lim=time_lim_in
        
        % filter by number of days
        time_ind=find(time_all>=time_lim*(-3600*24));
%         time=time(time_ind);

        max_time_ind=max(time_ind);
        
        %% save total sensitivity
        if ~do_weekly % get total sensitivity for run

            % sum over time
            tracer_tmp=sum(tracer(:,:,time_ind),3)';

            % save
            sensitivities_all(:,:,i,count)=tracer_tmp;

            
        else
            %% find where current run falls if times are provided
            
            % sort start time into datetime array
            % start time is given by trajectory end date minus desired back
            % trajectory length
            start_time_tmp=traj_tmp.end_on(1)-days(time_lim);
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
            
            %% save total sensitivity
            if split_ind==0 % get total sensitivity for run if all within one week

                tracer_tmp=sum(tracer(:,:,time_ind),3)';
                sensitivities_all(:,:,split_count(count),count)=tracer_tmp;

                % save number of run (only one entry, since all within a week)
                % save corresponding SI data index
                sens_info_all(split_count(count),:,count)=[i,week_end-1];
                
                split_count(count)=split_count(count)+1;

            else

                % first part of run (time goes backwards, later indices are the
                % earlier times)
                tracer_tmp=sum(tracer(:,:,split_ind+1:max_time_ind),3)';
                sensitivities_all(:,:,split_count(count),count)=tracer_tmp;
                
                % save index twice for two entries in 'sensitivities'
                % save corresponding SI data indices
                % round one
                sens_info_all(split_count(count),:,count)=[i,week_end-1];
                split_count(count)=split_count(count)+1;

                % part that falls on next week (time goes backwards, earlier indices
                % are the later times)
                tracer_tmp=sum(tracer(:,:,1:split_ind),3)';
                sensitivities_all(:,:,split_count(count),count)=tracer_tmp;
                
                % round 2
                sens_info_all(split_count(count),:,count)=[i,week_end];
                split_count(count)=split_count(count)+1;

            end
        end
        
        count=count+1;

        
    end
    
end

fprintf('\n');
fprintf('Saving files\n');

%% save data
cd([flex_dir flex_folder]);

count=1;
for time_lim=time_lim_in
    
    % truncate trajectories to only include desired duration
    trajectories=trajectories_all;
    trajectories(trajectories.time<time_lim*(-3600*24),:)=[];
    
    time=time_all(time_all>=time_lim*(-3600*24));
    
    if ~do_weekly
        
        sensitivities=squeeze(sensitivities_all(:,:,:,count));
        
        save([flex_folder '_' num2str(time_lim) 'day.mat'],...
             'trajectories','sensitivities','time','latitude','longitude')
    else
        
        sensitivities=squeeze(sensitivities_all(:,:,:,count));
        sensitivities(:,:,split_count(count):end)=[];
        
        sens_info=squeeze(sens_info_all(:,:,count));
        sens_info(split_count(count):end,:)=[];
        
        sens_info=array2table(sens_info,'variablenames',{'run_index','week_index'});
        
        save([flex_folder '_' num2str(time_lim) 'day__weekly_sum.mat'],...
             'trajectories','sensitivities','time','latitude','longitude',...
             'sens_info','week_times')
    end

    count=count+1;
     
end

fprintf('Done\n');

end

    
