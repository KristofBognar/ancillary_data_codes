function [ ind1, ind2 ] = find_coincidences_time_general( times1, times2, dt )
%find_coincidences_time_general( table1, table2, dt )
%
% Find temporal coincidences within specified time window. Each point in
% both datasets is matched to the nearest point in the other dataset,
% within the time window. dt is in hours.
%

%% setup
% convert time difference to days
dt=dt/24;

% check input

if isdatetime(times1)
    [ft,year]=fracdate(times1);
    times1=ft_to_mjd2k(ft,year);
end

if isdatetime(times2)
    [ft,year]=fracdate(times2);
    times2=ft_to_mjd2k(ft,year);
end

if size(times1,1)==1, times1=times1'; end
if size(times2,1)==1, times2=times2'; end

%% find temporal coincidences

% find differences between each element
% bsxfun uses less memory (and requires fewer lines of code) compared to repmat
diff=abs(bsxfun(@minus,times2,times1'));
% each column represents the difference of one table1 time to all the table2 times
% each row represents the difference of one table2 time to all the table1 times

% indices of minima in table2, corresponding to each table1 element
% (closest times to each table1 time)
[min_val12,min_ind12]=min(diff,[],1);

% indices of minima in table1, corresponding to each table2 element
% (closest times to each table2 time)
[min_val21,min_ind21]=min(diff,[],2);

% save all coincidences: we want each value compared to the nearest meas. in
% the other dataset, and do this MUTUALLY (datasets are treated as equal)
% coincidences array has columns:
%   table1 indices
%   table2 indices
%   time difference (in mjd, so it's days)

% all table1 indices, with corresponding closest table2 values
coincidences=[[1:length(min_ind12)]', min_ind12', min_val12'];

% all table2 indices, with corresponding closest table1 values
coincidences=[coincidences;...
              [min_ind21, [1:length(min_ind21)]', min_val21]];

% discard coincidences outside time window
coincidences(coincidences(:,3)>dt,:)=[];

% remove double-counted entries
coincidences=unique(coincidences,'rows');

%% addign output
ind1=coincidences(:,1);
ind2=coincidences(:,2);

end

