% find appropriate times for back trajectory calculations

%% setup
load('/home/kristof/work/BEEs/BEE_dataset_all.mat')

% select year to run FLEXPART for (single year or list of years)
% year=2015:2018;
year=2019;

% length of gaps used to break up measurements (in hours)
gap_length=1.5;

% approximate time interval for single flexpart run (in hours)
run_dt=3;

% if only part of the dataset is needed, anything before cutoff date is ignored
cutoff=0;
% cutoff_date=datetime(2018,03,22,17,00,00);

%%

% get times from given year
times=bee_dataset.times(bee_dataset.times.Year>=year(1) & ...
                        bee_dataset.times.Year<=year(end));

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

% write script that runs FLEXPART
write_run_script(run_times, 5, year);

% save times and start/end dates that correspond to each FLEXPART run
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

