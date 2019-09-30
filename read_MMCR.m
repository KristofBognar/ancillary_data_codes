function read_MMCR( year, doy)
%UNTITLED2 read MMCR data for given day
%   Read MMCR reflectivity from data files on Cube
%   INPUT: year, list of day of year (jan. 1 = 1)
%   OUTPUT: 

% ncdisp(filename) to display properties

%% generate path
yr=num2str(year);
path=['/home/kristof/cube/MMCR/tords4/MMCR/Mom/' yr '/'];

% move to correct year folder on cube
cur_dir=(pwd);
cd(path);

%% define variables
ft=[];
ref=[];
height=[];
mode=[];


%% loop over desired days
n=0;
for i=1:length(doy)
    %% switch to daily directory and list files

    day=num2str(doy(i));

    % add leading zero to day number
    if doy(i)<=99
        day=['0' day];
    end

    filedir=[path day '/'];
    
    if exist(filedir,'dir')
        cd(filedir)
    else
        fprintf(repmat('\b',1,n));
        continue
    end
    
    % make list of all files
    temp = dir('*.nc'); 
    f_list = {temp.name}; % cell array of file names

    % check if all data present 
    incomplete=false;
    if length(f_list)~=24
        disp(['only ' num2str(length(f_list)) ' files for day ' num2str(doy(i))])
        incomplete=true;
        offset=0;
    end
    
    %% loop over hourly files
    counter=0;
    for j=1:length(f_list)
        counter=counter+1;
        %% display progress info
        disp_str=['Reading file ',f_list{j}];
        % stuff to delete last line and reprint updated message
        fprintf(repmat('\b',1,n));
        fprintf(disp_str);
        n=numel(disp_str);    

        %% read time (seconds passed since hh:00 on given date)
        time=ncread(f_list{j},'time_offset');
        
        % get start hour
        temp=ncreadatt(f_list{j},'base_time','string');
        temp=datevec(temp,'dd-mmm-yyyy,HH:MM:SS');
        hour=temp(4);

        % convert to fractional time
        ft_tmp=doy(i)-1 + time./(3600*24) + hour/24;

% %         % check if an hour was skipped
% %         if incomplete && hour~=(counter+offset)
% %             ft_tmp=[ones(length(ft_tmp),hour-counter+offset)*9999;ft_tmp];
% %             offset=hour-counter;
% %         end
% %         if incomplete && j==length(f_list) && counter~=23
% %             ft_tmp=[ft_tmp;ones(size(ft_tmp),23-counter)*9999];
% %         end
            
        %% read reflectivity data (height X time)
        ref_tmp=ncread(f_list{j},'Reflectivity');
        
        % filter empty values (fill value is ~9.97e36)
        ind=find(ref_tmp>1e36);
        ref_tmp(ind)=NaN;
        
        %% read mode data (0-3?; each mode has corresponding height grid)
        % alitude/resolution variations:
        % 1 - to 6 km, ~44m resolution, 140 levels
        % 2 - same as 1, but up to 10 km, 228 levels
        % 3 - to 13 km, ~88m resolution, 154 levels
        % 4 - seems to be same as 3
        % altitude ranges don't correspond to mode index!!!
        mode_tmp=ncread(f_list{j},'ModeNum');
        
        %% read height data (height X mode, up to 10 modes)
        height_tmp=ncread(f_list{j},'Heights');

        % create height matrix matching dimensions of reflectivity data
        % index by mode
        height_arr=NaN(size(ref_tmp));
        for mm=0:max(mode_tmp)
            ind=find(mode_tmp==mm);
            for asd=1:length(ind)
                height_arr(:,ind(asd))=height_tmp(:,mm+1);
            end
        end
        % filter empty values (fill value is ~9.97e36)
        ind=find(height_arr>1e36);
        height_arr(ind)=NaN;
        
        % only save profiles for lowest part of atm
        ind1=find(isnan(height_arr(141,:)));
       
        %% update variables
        
        ft=[ft;ft_tmp(ind1)]; % time is column vector
        ref=[ref,ref_tmp(:,ind1)];
        height=[height,height_arr(:,ind1)];
        mode=[mode;mode_tmp(ind1)]; % mode is column vector
    
    end

    % change back to yearly dir
    cd('../');
    

end

fprintf('\n')

% back to working dir
cd(cur_dir);

%% save results
savename=['MMCR_' yr '_' num2str(doy(1)) '-' num2str(doy(end)) '.mat'];

save(savename,'ft','ref','height','mode');

end
