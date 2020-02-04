% find appropriate times for back trajectory calculations

%% setup
%%% old version: not a great idea in case retrievals change and more data
%%% passes filter
% % % load('/home/kristof/work/BEEs/BEE_dataset_all.mat')

%%% nev version: use retrieval times without any filter
load('/home/kristof/work/profile_retrievals/profile_results/tracegas_profiles_filt_all.mat','times');


% select year to run FLEXPART for (single year or list of years)
year=2016:2019;
% year=2019;

% length of gaps used to break up measurements (in hours)
gap_length=1.5;

% approximate time interval for single flexpart run (in hours)
run_dt=3;

% if only part of the dataset is needed, anything before cutoff date is ignored
cutoff=0;
% cutoff_date=datetime(2018,03,22,17,00,00);

% copy runs from previous version?
% if yes, run script is modified to not run times that match times of
% previous flexpart runs. Those files are copied from the old version
% (FLEXPART runs only depend on mean time and met data -- if neither changed,
% results are the same)
copy_old=1;
old_dir='BrO_back_runs_v1/';
p_dir='/home/kristof/berg/FLEXPART_10.02/';

%% find meean times, along with start/end of time interval
% mean time is used as the time the back trajectory arrives in Eureka
% start and end times are used for later processing only

% get times from given year
% % % times=bee_dataset.times(bee_dataset.times.Year>=year(1) & ...
% % %                         bee_dataset.times.Year<=year(end));
times=times(times.Year>=year(1) & times.Year<=year(end));


% index at the start of each gap longer than specifiec time
ind_gap=find(times(2:end)-times(1:end-1) > duration(hours(gap_length)));

% convert to index at end of each gap (start of new continuous measurement
% sequence), and add first/last index for completeness 
ind_gap=[1;ind_gap+1;length(times)+1];

run_times=[];
run_start=[];
run_end=[];

for i=1:length(ind_gap)-1
    
    % times in given sequence
    times_tmp=times(ind_gap(i):ind_gap(i+1)-1);
    
    if length(times_tmp)<2, continue; end
    
    % number of intervals
    times_diff=times_tmp(end)-times_tmp(1);
    [hh,mm]=hms(times_diff);
    dt=hh+mm/60;
    
    n_int=floor((dt+run_dt/2)/run_dt);
    
    if n_int<=1
        run_times_tmp=mean([times_tmp(1),times_tmp(end)]);
        run_start=[run_start, times_tmp(1)];
        run_end=[run_end, times_tmp(end)];
    else
        step=times_diff/n_int;
        run_times_tmp=times_tmp(1)+step/2:step:times_tmp(end);

        run_start=[run_start, times_tmp(1):step:times_tmp(end)-step/2];
        run_end=[run_end, times_tmp(1)+step:step:times_tmp(end)];
        
    end
    
    run_times=[run_times, run_times_tmp];

end

% round to nearest minute
run_times=dateshift(run_times, 'start', 'minute', 'nearest');

% select dates
if cutoff
    run_times(run_times<cutoff_date)=[];
    year=1;
end

%% if reusing old runs, select appropriate indices
if copy_old
    
    % check if folder exists
    if ~isdir([fp_dir old_dir]), error('old version not found'), end
    
    % load old times
    tmp=load([fp_dir old_dir 'flexpart_times_2015-2019.mat'],'run_times');
    old_times=tmp.run_times;    
    
    % get matching times
    % where ind_copy is true, FLEXPART will not run
    ind_copy=ismember(run_times,old_times);
    
    % write script that copies files
    to_copy_date=datestr(run_times(ind_copy),'yyyymmdd');
    to_copy_time=datestr(run_times(ind_copy),'HHMMSS');
    
    copy_script=[fp_dir 'copy_old.sh'];
    % check if script exists, wipe if yes
    if exist(copy_script,'file')
        system(['rm ' copy_script]);
        system(['touch ' copy_script]);
    else
        system(['touch ' copy_script]);
    end

    fid=fopen(copy_script, 'w');

    % header info
    fprintf(fid,'#!/bin/bash');
    fprintf(fid,'\n');
    fprintf(fid,'\n');
    fprintf(fid,'# Script to copy FLEXPART runs from old version\n');
    fprintf(fid,'# A new version of the back trajectories was generated, but some\n');
    fprintf(fid,'# of the start times match -- no ned to rerun those dates\n');
    fprintf(fid,'\n');
    fprintf(fid,'# File must be run on Berg, in the flexpart directory\n');
    fprintf(fid,'\n');
    
    for i=1:sum(ind_copy)
        
        fprintf(fid,['cp -r ' old_dir 'out_' to_copy_date(i,:) '_' to_copy_time(i,:) ...
                     '/ .\n']);
        
    end
    
    fprintf(fid,'\n');
    fclose(fid);
    
    disp(['Wrote script to copy ' num2str(sum(ind_copy)) ' back trajectories from ' old_dir])
    
else
    %run flexpart for all times
    ind_copy=logical(zeros(1,length(run_times)));
end


%% generate script, save times

% write script that runs FLEXPART
write_run_script(run_times(~ind_copy), 5, year);
disp(['Wrote script to run ' num2str(sum(~ind_copy)) ' new back trajectories'])

% save times and start/end dates that correspond to each FLEXPART run
% save all the times, regardless of which ones are rerun and which are
% copied
if length(year)==1
    save(['/home/kristof/work/BEEs/flexpart_times_' num2str(year) '.mat'],...
          'run_times','run_start','run_end');
else
    save(['/home/kristof/work/BEEs/flexpart_times_' num2str(year(1)) '-'...
          num2str(year(end)) '.mat'],'run_times','run_start','run_end');
end

% plot(bee_dataset.times(bee_dataset.N_SE_rest==1),bee_dataset.bro_col(bee_dataset.N_SE_rest==1),'ro'), hold on
% plot(bee_dataset.times(bee_dataset.N_SE_rest==2),bee_dataset.bro_col(bee_dataset.N_SE_rest==2),'bo'), hold on
% plot(bee_dataset.times(bee_dataset.N_SE_rest==3),bee_dataset.bro_col(bee_dataset.N_SE_rest==3),'go'), hold on
% plot(bee_dataset.times(isnan(bee_dataset.N_SE_rest)),bee_dataset.bro_col(isnan(bee_dataset.N_SE_rest)),'ko'), hold on

