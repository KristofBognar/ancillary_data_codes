function data_out = read_EWS(filename)
%read_EWS Import numeric data from a text file as a matrix.
% Auto-generated by MATLAB on 2019/01/31 13:46:05, modified by Kristof Bognar

%% Initialize variables.
delimiter = ',';
startRow = 15;
endRow = inf;

%% Read columns of data as strings:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r','n','UTF-8');
% Skip the BOM (Byte Order Mark).
fseek(fileID, 3, 'bof');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
textscan(fileID, '%[^\n\r]', startRow(1)-1, 'WhiteSpace', '', 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    textscan(fileID, '%[^\n\r]', startRow(block)-1, 'WhiteSpace', '', 'ReturnOnError', false);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric strings to numbers.
% Replace non-numeric strings with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[2,3,4,6,8,10,12,14,16,18,20,22]
    % Converts strings in the input cell array to numbers. Replaced non-numeric
    % strings with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, ',', 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end

% Convert the contents of columns with dates to MATLAB datetimes using date
% format string.
try
    dates{5} = datetime(dataArray{5}, 'Format', 'HH:mm', 'InputFormat', 'HH:mm');
catch
    try
        % Handle dates surrounded by quotes
        dataArray{5} = cellfun(@(x) x(2:end-1), dataArray{5}, 'UniformOutput', false);
        dates{5} = datetime(dataArray{5}, 'Format', 'HH:mm', 'InputFormat', 'HH:mm');
    catch
        dates{5} = repmat(datetime([NaN NaN NaN]), size(dataArray{5}));
    end
end

anyBlankDates = cellfun(@isempty, dataArray{5});
anyInvalidDates = isnan(dates{5}.Hour) - anyBlankDates;
dates = dates(:,5);

%% Split data into numeric and cell columns.
rawNumericColumns = raw(:, [2,3,4,6,8,10,12,14,16,18,20,22]);
rawCellColumns = raw(:, [1,7,9,11,13,15,17,19,21,23,24]);


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

%% Create output variable
data_out = table;
data_out.DateTime = rawCellColumns(:, 1);
data_out.Year = cell2mat(rawNumericColumns(:, 1));
data_out.Month = cell2mat(rawNumericColumns(:, 2));
data_out.Day = cell2mat(rawNumericColumns(:, 3));
data_out.Time = dates{:, 1};
data_out.TempC = cell2mat(rawNumericColumns(:, 4));
data_out.TempFlag = rawCellColumns(:, 2);
data_out.DewPointTempC = cell2mat(rawNumericColumns(:, 5));
data_out.DewPointTempFlag = rawCellColumns(:, 3);
data_out.RelHum = cell2mat(rawNumericColumns(:, 6));
data_out.RelHumFlag = rawCellColumns(:, 4);
data_out.WindDir10sdeg = cell2mat(rawNumericColumns(:, 7));
data_out.WindDirFlag = rawCellColumns(:, 5);
data_out.WindSpdkmh = cell2mat(rawNumericColumns(:, 8));
data_out.WindSpdFlag = rawCellColumns(:, 6);
data_out.Visibilitykm = cell2mat(rawNumericColumns(:, 9));
data_out.VisibilityFlag = rawCellColumns(:, 7);
data_out.StnPresskPa = cell2mat(rawNumericColumns(:, 10));
data_out.StnPressFlag = rawCellColumns(:, 8);
data_out.Hmdx = cell2mat(rawNumericColumns(:, 11));
data_out.HmdxFlag = rawCellColumns(:, 9);
data_out.WindChill = cell2mat(rawNumericColumns(:, 12));
data_out.WindChillFlag = rawCellColumns(:, 10);
data_out.Weather = rawCellColumns(:, 11);

% convert DateTime string to matlab datetime
data_out.DateTime = datetime(data_out.DateTime,'inputformat','yyyy-MM-dd HH:mm');

% remove first line (past 2018 april there's an extra header line, data
% starts one row down)
if isnan(data_out.Year(1)), data_out=data_out(2:end,:); end

% For code requiring serial dates (datenum) instead of datetime, uncomment
% the following line(s) below to return the imported dates as datenum(s).

% enghourly0301201503312015.Time=datenum(enghourly0301201503312015.Time);

