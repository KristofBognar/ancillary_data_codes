
cur_dir=pwd();
cd('/home/kristof/work/BEEs/sea_ice_data/EASE-Grid_SI_age');

tmp = dir('*.nc'); 
f_list = {tmp.name};

t_len=zeros(1,length(f_list));
age=zeros(722,722);

date_age=[];
date_age_mid=[];

for i=1:length(f_list)

    tmp=ncinfo(f_list{i});
    tmp={tmp.Dimensions.Length};
    t_len(i)=tmp{3};
end

if unique(t_len)==52
    t_len=52;
else
    disp(t_len)
    disp('Some files are missing full year of data. Continue? ([y]/n)')
    tmp=input('','s');
    
    if strcmp(tmp,'n')
        return
    end
    
end

for i=1:length(f_list)
    
    age=cat(3,age,double(ncread(f_list{i},'age_of_sea_ice')));
    
    lat_age=double(ncread(f_list{i},'latitude'));
    lon_age=double(ncread(f_list{i},'longitude'));
    
    x_age=double(ncread(f_list{i},'x'));
    y_age=double(ncread(f_list{i},'y'));

    time_tmp=ncread(f_list{i},'time');

    % time is days since 1970-01-01 00:00:00
    mjd2k=time_tmp+ft_to_mjd2k(0,1970);
    date_age=[date_age; mjd2k_to_date(mjd2k)]; % this is the start time of the week

end

age(:,:,1)=[];

% calculate mid-week time
date_age_mid=[date_age(1:end-1)+diff(date_age)./2; date_age(end)+days(3.5)];

cd('../')

save('EASE_grid_SI_age.mat','age','lat_age','lon_age','x_age','y_age',...
     'date_age','date_age_mid');
