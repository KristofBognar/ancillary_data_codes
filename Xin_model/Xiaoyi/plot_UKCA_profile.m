function plot_UKCA_profile()
save_fig = 1;
species = 'mmr'; % 'tracer1' is O3, 'mmr' is BrO 
profile_type = 'vmr'; % only 'vmr', we do not have p, T profiles! 
data_path = 'E:\Xin\UKCA\';
year = '2011';

if strcmp(year,'2007')
    file_nm = 'UKCA-O3-BrO-23-Feb-7-Mar-2007.nc';
    plot_path = ['plot_profile_' species '_' profile_type '_2007'];
    pivot_time_stamp = '2007-02-01 00:00:00';
elseif strcmp(year,'2011')
    file_nm = 'UKCA-O3-BrO-27-MArch-6-April-2011.nc';
    plot_path = ['plot_profile_' species '_' profile_type '_2011'];
    pivot_time_stamp = '2011-03-01 00:00:00';
end

cd(data_path);

%plot_path = ['plot_profile_' species '_' profile_type];
site_lon = 360-86.416;
site_lat = 80.053;


try 
    mkdir(plot_path);
end

pivot_time = datenum(pivot_time_stamp,'yyyy-mm-dd HH:MM:SS'); % UKCA model use different pivot time for each run!!


time = double(ncread(file_nm,'t') + pivot_time); % convert to MATLAB serial time
N = size(time);
time_stamp = datestr(time,'yyyymmdd HH');

for i = 1:1:N(1)
    [output_profile(:,i),output_h(:,i)] = read_profile_single_time_step(i,species ,file_nm,time_stamp,profile_type,site_lon,site_lat);
end

cd(plot_path);
plot_1D_profile(output_profile,output_h,time,species,profile_type);
print_setting(1/2,save_fig,['UKCA_' species '_1D_profile']);
plot_2D_profile(output_profile,output_h,time,species,profile_type,year)
print_setting(1/2,save_fig,['UKCA_' species '_2D_profile']);
close all;
output.time = time;
output.profile = output_profile;
output.h = output_h;
clearvars -except output;
save('profile_data');
cd ..;


%% 
function [output_profile,output_h] = read_profile_single_time_step(time_step,species,file_nm,time_stamp,profile_type,site_lon,site_lat)
do_interp = 1; % 1 = yes, interp data to 1*1 degree grid
Aav = 6.02e23;
R = 8.314;
DU = 2.69e20;
data = ncread(file_nm,species);% 4D [lon,lat,model level,time]
if strcmp(species,'tracer1')
    vmr = data(:,:,:,time_step).*28.8/48*1e9; % convert MMR [kg/kg] to VMR [ppbv]
elseif strcmp(species,'mmr')
    vmr = data(:,:,:,time_step).*28.8/43*1e12; % convert MMR [kg/kg] to VMR [pptv]
end

trop_height = ncread(file_nm,'ht_1'); % height @ tropopause [m]

h = ncread(file_nm,'hybrid_ht');% height for each model level [m]

M = size(trop_height);



lon = ncread(file_nm,'longitude');
lat = ncread(file_nm,'latitude');
lon = double(lon);
lat = double(lat);

[lon_diff, lon_index] = min(abs(lon - site_lon));
[lat_diff, lat_index] = min(abs(lat - site_lat));


vmr_site = vmr(lon_index,lat_index,:);
output_profile = reshape(vmr_site,[60,1]);

output_h = h; % please note UKCA use fixed height


%%

function plot_1D_profile(output_profile,output_h,time,species,profile_type)
figure;hold all;
plot(output_profile,output_h);
xlabel([species ' ' profile_type]);
ylim([0 9000]);
ylabel(['Height [m]']);

function plot_2D_profile(output_profile,output_h,time,species,profile_type,year)
fixed_h = 0:50:30000;
N = size(output_h);
for i = 1:1:N(2)
    profile_interp(:,i) = interp1(output_h(:,i),output_profile(:,i),fixed_h);
end
figure;hold all;
imagesc(time,fixed_h,profile_interp);

datetick('x','dd-mm');
ylim([0 4000]);
ylabel(['Height [km]']);
ax = gca;
ax.YTick = [0 1000 2000 3000 4000];
ax.YTickLabel = {'0', '1', '2', '3', '4'};


xlabel([year]);

colorbar;
if strcmp(species,'tracer1')
    title([ 'O3' ' ' profile_type ' [ppbv]']);
    caxis([0 50]);
elseif strcmp(species,'mmr')
    title(['BrO' ' ' profile_type ' [pptv]']);
    caxis([0 10]);  
end

