% read and plot Eureka weather station data

% Got data from:
% http://climate.weather.gc.ca/historical_data/search_historic_data_e.html
%
% There are two or three results for Eureka on ECCC's weather database, plus a
% 'Eureka Climate' entry
% 
% All three have TC Identifier:WEU, while the 'climate' data is NEK
% (and the longitude is different)
% 
% Only some of the three datasets have the visual weather observations, even though the
% measurement data are the same (unless the data are missing altogether). The files with
% weather obs have 2h missing almost every day...
% 
% Downloaded multiple sets of files, to get the most complete meaurement record
% 
% Only one dataset has info before 2016
% 
% 
% Files in ../from_Xiaoyi seem different again, with an extra data quality flag, and no
% weather observations for 2016-2017

cur_dir=pwd;

read_data=true;

if ~read_data

else %% read files and save data

    % make list of files in 'with_weather' folder: files with weather obs
    cd('/home/kristof/work/weather_stations/Eureka/mix_and_match/with_weather');
    
    % make list of all files
    temp = dir('*.csv'); 
    f_list = {temp.name}; % cell array of file names    
    
    %% read data
    for i=1:length(f_list)
        
        % read file
        tmp=read_EWS(f_list{i});
        % try to read 'no weather' file as well (might not exist)
        try 
            tmp2=read_EWS(['../no_weather/' f_list{i}]); 
        catch
            tmp2=[];
        end
        
        % save/append to all results
        if i==1
            data=tmp;
            if ~isempty(tmp2), 
                data_noweather=tmp2; 
            else
                data_noweather=tmp; 
            end
        else
            data=[data;tmp];
            if ~isempty(tmp2)
                data_noweather=[data_noweather; tmp2]; 
            else
                data_noweather=[data_noweather; tmp]; 
            end
        end

    end
    
    % sort, since files are sorted by month, not year
    data=sortrows(data);
    data_noweather=sortrows(data_noweather);
    

    %% combine measurement fields
    % assume that missing T field indicates missing measurement data
    % also assume that noweather file has data for the same time (if not,
    % it doesn't matter anyway)
    
    % find rows in no weather file that correspond to missing rows in the
    % first file (files should have the same rows, but sometimes they don't)
    ind_in_data=find(isnan(data.TempC));
    [~,ind_in_noweather,tmp]=intersect(data_noweather.DateTime,data.DateTime(ind_in_data));
    
    ind_in_data=ind_in_data(tmp);
    
    % replace all fields exept date/time, visibility, and weather description
    data(ind_in_data,6:15)=data_noweather(ind_in_noweather,6:15);
    data(ind_in_data,18:23)=data_noweather(ind_in_noweather,18:23);
    
    % add fractional time
    data.ft=fracdate(data.DateTime);
    
    %% save file
    
    cd('/home/kristof/work/weather_stations/Eureka/');
    
    save EWS_PTU_and_weather_complete.mat data
    
    cd(cur_dir);

end




