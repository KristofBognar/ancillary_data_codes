% function read_PWS( year )
% Read PEARL weather station data for given year
% select setra or campbell files based on what's available
    
% wind speed is in knots (!!!) for some stupid reason
% 1 knot = 0.514444 m/s
year=2019;

merge_all=true;

%% input variables
    
cur_dir=(pwd);

% merge files, of required (rest of code doesn't run)
if merge_all
    
    cd('/home/kristof/work/weather_stations/ridge_lab');
    for year=2015:2019
        load(['PWS_' num2str(year) '.mat']);
        if year==2015
            data_all=data;
        else
            data_all=vertcat(data_all, data);
        end
    end
    
    data=data_all;
    save PWS_all.mat data
    cd(pwd)
    return
end

path='/home/kristof/cube/PWS/torcube8/PWS';

cd(path)
    
    
if any([2017:2019]==year)
    
    % 'campbell-report' data
    file_select=1;
    
    % make list of all files
    tmp = dir([num2str(year) '*.csv']); 
    f_list = {tmp.name}; % cell array of file names    
    
elseif any([2015:2016]==year)
    
    % setra data, yearly folders
    file_select=2;
    
    % make list of all files
    cd(['Setra_' num2str(year)]);
    tmp = dir(['*.' num2str(year)]); 
    f_list = {tmp.name}; % cell array of file names    
    
else
    error('Figure out what data is available for this year');
end
    
   
%% read files
n=0;
for i=1:length(f_list)
    
    % import data for given day
    if file_select==1
        tmp=import_PWS(f_list{i});
        try tmp.year=ones(size(tmp.ft))*year; end
    elseif file_select==2
        tmp=import_PWS_setra(f_list{i});
    end
    
    % display progress info
    disp_str=['Reading file ',num2str(i),'/',num2str(size(f_list,2)),' (',f_list{i},')'];
    % stuff to delete last line and reprint updated message
    fprintf(repmat('\b',1,n));
    fprintf(disp_str);
    n=numel(disp_str);    
    
    if isempty(tmp), continue, end
    
    if i==1
        data=tmp;
    else
        data=[data;tmp];
    end

    
    
end
fprintf('\n');
fprintf('Done\n');

cd(cur_dir)

% convert to m/s
data.WindSpd=data.WindSpd*0.514444;

% filter out bad values 
ind=find(data.WindSpd<0 | data.WindSpd>35);
data(ind,:)=[];

% sort by date, just in case
data=sortrows(data,'DateTime');

% save results
save(['/home/kristof/work/weather_stations/ridge_lab/PWS_' num2str(year) '.mat'],'data');


% figure(1)
% plot(ft,wspd)
    
% smooth data (~5 min)
wspd_smooth=boxcar(data.ft,data.WindSpd,5);

figure(1)
plot(data.ft,wspd_smooth)


