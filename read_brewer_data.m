function read_brewer_data( bw_num )
%READ_BREWER_DATA 
%   Read brewer data from daily text files provided by ECCC
%   File format is similar to ozonesodes -- reuse some code from
%   read_ozonesonde.m
%
%   INPUT: Brewer number (corresponding data location set in the code)
%   OUTPUT: save file with separated DS, ZS and UV data variables
%
%   Given the complicated file structure and the fact that files are on the
%   server, the code is quite slow
%
%@Kristof Bognar, May 2020

%% setup

% bw_num=69;

filedir=['/home/kristof/aurora/ground/eureka/brewer/brewer' num2str(bw_num) '/'];
% filedir=['/home/kristof/aurora/ground/eureka/brewer/brewer69/', num2str(yr), '/'];
savedir='/home/kristof/work/brewer/';

brewer_ds=[];
brewer_zs=[];
brewer_uv=[];

%% Find all data files

% get number of years
tmp = dir(filedir); 
yr_list = {tmp.name}; % cell array of file names
yr_list(1:2)=[]; % ignore first 2 entries (. and ..)


% loop over all years
n=0;
for i=1:length(yr_list)
    
    % make list of all files
    tmp = dir([filedir yr_list{i} '/*.csv']); 
    f_list = {tmp.name}; % cell array of file names

    % loop over all data for given year
    for j=1:length(f_list)

        % display progress
        disp_str=['Processing ' yr_list{i} ' files (' num2str(j) '/' num2str(length(f_list)) ')'];
        % stuff to delete last line and reprint updated message
        fprintf(repmat('\b',1,n));
        fprintf(disp_str);
        n=numel(disp_str);    

        % get data from file
        data=read_file([filedir yr_list{i} '/' f_list{j}]);
        
        % break up DS, ZS, and UV data
        ind=find(strcmp(data.ObsCode,'DS'));
        if ~isempty(ind), brewer_ds=[brewer_ds; data(ind,:)]; end

        ind=find(strcmp(data.ObsCode,'ZS'));
        brewer_zs=[brewer_zs; data(ind,:)];

        ind=find(strcmp(data.ObsCode,'UV'));
        brewer_uv=[brewer_uv; data(ind,:)];
        
    end
    
end

% save results
save([savedir 'brewer' num2str(bw_num) '_' yr_list{1} '-' yr_list{end} '.mat'],'brewer_ds','brewer_zs','brewer_uv');

fprintf('\n')


end


%% function to read in Brewer data files
function data = read_file(fname)

fid=fopen(fname,'r');

%% find position of relevant entries (in case format changes from year to year)
search=true;
rowcount=1;
empty_lines=0;
row_time=-1;
row_data_start=-1;

% loop over the file line by line
while search

    line = fgets(fid);
    
    % count empty lines, since textscan skips them
    if strfind(line,char(13))==1, empty_lines=empty_lines+1; end
        
    % find date and time offset details
    if strcmp(cellstr(line),'#TIMESTAMP'), row_time=rowcount+2; end
    % read date and time offset
    if rowcount==row_time, time_line=line; end
    
    % find the actual data
    if strcmp(cellstr(line),'#OBSERVATIONS')
        row_data_start=rowcount+2;
    end
    % read data header
    if rowcount==row_data_start-1, header_line=line; end
    
    % find daily summary to figure out where the data ends, and quit loop
    if strcmp(cellstr(line),'#DAILY_SUMMARY'), 
        row_data_end=rowcount-2; 
        search=false;
    end

    rowcount=rowcount+1;

end
fclose(fid);


%% read data
% parse header for table column names
header_line=strsplit(char(header_line),',');

% chack format
if length(header_line)~=12, error(['File format changed in ' fname]); end

if strcmp(header_line{1},'Time')
    header_line{1}='DateTime';
else
    error(['File format changed in ' fname]);
end

% assuming that data format is the same in all files
formatSpec = '%{HH:mm:ss}D%f%s%f%f%f%f%f%f%f%f%f%[^\n\r]';

% read the data
fid = fopen(fname,'r');

% textscan reads set number of lines, EXCLUDING empty lines
% first call reads up to the start of the data array, second call reads the data
textscan(fid, '%[^\n\r]', row_data_start-empty_lines, 'WhiteSpace', '', 'ReturnOnError', false);
dataArray = textscan(fid, formatSpec, row_data_end-row_data_start+1, 'Delimiter', ',',...
                     'EmptyValue' ,NaN,'ReturnOnError', false);

fclose(fid);

data = table(dataArray{1:end-1}, 'VariableNames', header_line);

%% add date and convert to UTC
time_line=strsplit(char(time_line),',');

% add date
data.DateTime=datetime(time_line{2}, 'InputFormat', 'yyyy-MM-dd')+timeofday(data.DateTime);

% need to subtract UTC offset (offset is negative)
% can only convert positive time to datetime; add abs value of time offset 
data.DateTime=data.DateTime+timeofday(datetime(time_line{1}(2:end), 'InputFormat', 'HH:mm:ss'));

data.DateTime.Format='dd/MM/uuuu HH:mm:ss';

end



