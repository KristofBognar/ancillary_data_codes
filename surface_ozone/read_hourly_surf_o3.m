function read_hourly_surf_o3()

    cd('/home/kristof/work/surface_ozone/hourly_data')
    
    surf_o3_hourly=[];
    
    %% read data by year
    for yr=2017:year(datetime(now,'convertfrom','datenum'))
        
        % make list of relevant files
        tmp = dir(['*' num2str(yr) '_hour.dat']); 
        f_list = {tmp.name}; % cell array of file names
        
        if isempty(f_list), continue, end
    
        % read files
        for i=1:length(f_list)

            tmp=read_file(f_list{i});
            surf_o3_hourly=[surf_o3_hourly; tmp];
            
        end
        
    end

    %% filter, clean up format, and save
    
    surf_o3_hourly.station=[];
    
    surf_o3_hourly(surf_o3_hourly.o3_ppb<0 | surf_o3_hourly.o3_ppb > 1000,:)=[];

    surf_o3_hourly.DateTime=datetime(surf_o3_hourly.year,surf_o3_hourly.month,...
                                     surf_o3_hourly.day,surf_o3_hourly.hour,0,0);

    surf_o3_hourly.ft=fracdate(surf_o3_hourly.DateTime);
        
    save /home/kristof/work/surface_ozone/surf_o3_hourly_all.mat surf_o3_hourly 

end

function data = read_file(filename)
%IMPORTFILE Import numeric data from a text file as a matrix.
%   EUK012017HOUR = IMPORTFILE(FILENAME) Reads data from text file FILENAME
%   for the default selection.
%
%   EUK012017HOUR = IMPORTFILE(FILENAME, STARTROW, ENDROW) Reads data from
%   rows STARTROW through ENDROW of text file FILENAME.
%
% Example:
%   euk012017hour = importfile('euk_01_2017_hour.dat', 2, 681);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2019/10/02 12:52:59

%% Initialize variables.
delimiter = ' ';
startRow = 2;
endRow = inf;

%% Format string for each line of text:
%   column1: text (%s)
%	column2: double (%f)
%   column3: double (%f)
%	column4: double (%f)
%   column5: double (%f)
%	column6: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%f%f%f%f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Create output variable
data = table(dataArray{1:end-1}, 'VariableNames', {'station','year','month','day','hour','o3_ppb'});

end