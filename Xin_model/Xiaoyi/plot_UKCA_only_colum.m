function plot_UKCA_only_colum()
save_fig = 1;
species = 'ISY'; % could be 'field632' stand for BrO from all level, or  ‘ISY’ stand for 'BrO' only in trop
VCD_type = 'trop'; % could be 'total', 'trop', or 'strat'
data_path = 'E:\Xin\UKCA\';
%data_path = '/export/data/home/xizhao/Xin/';
%addpath('/export/data/home/xizhao/matlab/');

file_nm = 'UKCA-column-BrO-27-MArch-6-April-2011.nc';
cd(data_path);
plot_path = ['plot_vcd_' species '_' VCD_type '_Xin_integrated'];


try 
    mkdir(plot_path);
end
pivot_time = datenum('2011-03-01 00:00:00','yyyy-mm-dd HH:MM:SS'); % pTOMCAT 'days since 1970-01-01 00:00:00'
time = double(ncread(file_nm,'t') + pivot_time); % convert to MATLAB serial time
N = size(time);
time_stamp = datestr(time,'yyyymmdd HH');

for i = 1:1:N(1)
    
    plot_VCD_single_time_step(i,species ,file_nm,time_stamp,VCD_type);
    cd(plot_path);
    print_setting(1/2,save_fig,['pTOMCAT_' species '_VCD_' time_stamp(i,:)]);
    cd ..;
    close all;
end

%% 

%% 
function plot_VCD_single_time_step(time_step,species,file_nm,time_stamp,VCD_type)
do_interp = 1; % 1 = yes, interp data to 1*1 degree grid
Aav = 6.02e23;
R = 8.314;
DU = 2.69e20;
data = ncread(file_nm,species);% 4D [lon,lat,hybrid_ht,time]
%vmr = data(:,:,31,1);
p_vcd = data(:,:,:,time_step);




M = size(p_vcd);
for i = 1:1:M(1)
    for j = 1:1:M(2)
        if strcmp(species,'field632') % for total column
            vcd(i,j) =  sum(p_vcd(i,j,:));
        elseif strcmp(species,'ISY') % for trop column
            vcd(i,j) =  sum(p_vcd(i,j,:));
        end
    end
end


lon = ncread(file_nm,'longitude');
lat = ncread(file_nm,'latitude');
lon = double(lon);
lat = double(lat);

if do_interp == 0
    [lat,lon] = meshgrid(lat,lon);
else
    lon = [lon;360];
    lat_interp = [min(lat):1:max(lat)]';
    %lon_interp = [min(lon):1:max(lon)+1]';
    lon_interp = [0:1:360]';
    [lat_interp,lon_interp] = meshgrid(lat_interp,lon_interp);
    [lat,lon] = meshgrid(lat,lon);
    vcd = [vcd;vcd(end,:)];
    vcd_interp = interp2(lat,lon,vcd,lat_interp,lon_interp);
    vcd = vcd_interp;
    lat = lat_interp;
    lon = lon_interp;   
end

figure('Color','white'); hold all;
ncpolarm('seaice','label');
%ncpolarm('asm');
pcolorm(lat,lon,vcd);
load coastlines
plotm(coastlat, coastlon);
colorbar;
%caxis([200 450]); % ozone VCD DU range
caxis([1e13 1e14]); % BrO trop VCD
%caxis([0 25]); % PWV
%caxis([0 1e14]); % SISS
title([ species ' ' time_stamp(time_step,:)]);

