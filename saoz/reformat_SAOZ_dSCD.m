function reformat_SAOZ_dSCD()
%REFORMAT_SAOZ_DSCD 

% tg='O3'; % no2 dscds will have have same time info

dscd=[];

for yy=2005:2017

    % read dSCD file
    tmp=import_saoz_dscd_o3_no2(['/home/kristof/work/SAOZ/dSCDs/O3_NO2/SAOZ_dSCD_' num2str(yy) '.asc']);
    
    % add year column
    tmp.year=ones(size(tmp.sza))*yy;
    
    % correct times that are equal due to lack of precision
    for i=2:size(tmp,1)
        
        if tmp.fd(i)==tmp.fd(i-1), tmp.fd(i)=tmp.fd(i)+0.0001; end
        
    end
    
    % add to final variable
    dscd=[dscd;tmp];
    
end

% fill in SAA 
date_tmp=datetime(dscd.fd-1+yeartime(dscd.year),'convertfrom','datenum');

[az_tmp, ~] = SolarAzEl(date_tmp,80.05*ones(size(date_tmp)),...
                        -86.42*ones(size(date_tmp)),0.6*ones(size(date_tmp)));
az_tmp=az_tmp-180;

dscd.saa=az_tmp;

% get day number
dscd.day=floor(dscd.fd);

% find indices of data that should be on previous day
prev_day_i = find(dscd.saa > 0 ...
    & rem(dscd.fd,1) < 0.25);

% find indices of data that should be pm
pm_i = find(dscd.saa > 0);

% assign ampm column and correct days 
dscd.ampm=zeros(size(dscd.sza));
dscd.ampm(pm_i) = 1;
dscd.day(prev_day_i) = dscd.day(prev_day_i) - 1;

% rename doy and add fractional time
dscd.fractional_time=dscd.fd-1;

% for O3 and NO2
dscd=[dscd(:,21),dscd(:,23:24),dscd(:,2),dscd(:,25),dscd(:,3),dscd(:,22),...
      dscd(:,13:20),dscd(:,4:12)];

save(['/home/kristof/work/SAOZ/SAOZ_dSCD.mat'],'dscd');

end

