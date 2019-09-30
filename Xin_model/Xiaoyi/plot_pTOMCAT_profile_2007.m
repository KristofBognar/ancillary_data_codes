function plot_pTOMCAT_profile_2007()
save_fig = 1;

species = 'SISS3'; % could be 'O3', 'H2O', 'BrO', 'OOSS#', and 'SISS#'
profile_type = 'vmr'; % could be 'vmr' or 'p-VCD' partial vertical column
data_path = 'E:\Xin\';

file_nm = 'pTOMCAT-1-7-March-2007-0N-90N.nc';
file_nm_gl3d = 'pTOMCAT-1-7-March-2007-0N-90N-gl3d.nc';
cd(data_path);
plot_path = ['plot_profile_' species '_' profile_type];
site_lon = 360-86.416;
site_lat = 80.053;


try 
    mkdir(plot_path);
end
pivot_time = datenum('1970-01-01 00:00:00','yyyy-mm-dd HH:MM:SS'); % pTOMCAT 'days since 1970-01-01 00:00:00'
time = double(ncread(file_nm,'time') + pivot_time); % convert to MATLAB serial time
N = size(time);
time_stamp = datestr(time,'yyyymmdd HH');

for i = 1:1:N(1)
    [output_profile(:,i),output_h(:,i)] = read_profile_single_time_step(i,species ,file_nm,file_nm_gl3d,time_stamp,profile_type,site_lon,site_lat);
end

cd(plot_path);
plot_1D_profile(output_profile,output_h,time,species,profile_type);
print_setting(1/2,save_fig,['pTOMCAT_' species '_1D_profile']);
plot_2D_profile(output_profile,output_h,time,species,profile_type)
print_setting(1/4,save_fig,['pTOMCAT_' species '_2D_profile']);
close all;
output.time = time;
output.profile = output_profile;
output.h = output_h;
clearvars -except output;
save('profile_data');
cd ..;


%% 
function [output_profile,output_h] = read_profile_single_time_step(time_step,species,file_nm,file_nm_gl3d,time_stamp,profile_type,site_lon,site_lat)
do_interp = 1; % 1 = yes, interp data to 1*1 degree grid
Aav = 6.02e23;
R = 8.314;
DU = 2.69e20;
data = ncread(file_nm,species);% 4D [lon,lat,model level,time]
vmr = data(:,:,:,time_step);

ptrop1 = ncread(file_nm,'ptrop2');%troppause pressure Pa [lon,lat,time]
ptrop1 = ptrop1(:,:,time_step);
p = ncread(file_nm,'p');% pressure Pa [lon,lat,sigma,time]
p = p(:,:,:,time_step);
T = ncread(file_nm,'t3d');% temepature K [lon,lat,sigma,time]
T = T(:,:,:,time_step);
h = ncread(file_nm_gl3d,'gl3d');% inter level geopotential height in m [lon,lat,sigma,time]
h = h(:,:,:,time_step);
M = size(p);
for i = 1:1:M(1)
    for j = 1:1:M(2)
        TF = p(i,j,:) >= ptrop1(i,j).*100;
        vmr_4sum = vmr(i,j,:).*1e-9;% vmr read in is ppbv for ozone, h2o, SSA, and OOA [note, for BrO the unit is pptv, but we will convert it later]
        p_4sum = p(i,j,:);
        T_4sum = T(i,j,:);
        if strcmp(profile_type,'p-VCD')
            delta_h = h(i,j,1:30) - h(i,j,2:31); % calculate delta h for integration
            for ii = 1:1:31
                if ii == 1
                    delta_h_4sum(1,1,ii) = delta_h(1,1,ii);
                elseif ii == 31
                    delta_h_4sum(1,1,ii) = delta_h(1,1,ii-1)/2;
                else
                    delta_h_4sum(1,1,ii) = (delta_h(1,1,ii)+delta_h(1,1,ii-1))/2;
                end
            end
         
            if strcmp(species,'O3')
                p_vcd = p_4sum.*vmr_4sum.*delta_h_4sum.*Aav./(R.*T_4sum)./DU; % ozone VCD unit [DU]
            elseif strcmp(species,'BrO')
                p_vcd = p_4sum.*vmr_4sum.*delta_h_4sum.*Aav./(R.*T_4sum).*1e-4.*1e-3; % BrO VCD in [molec/cm2]
            elseif strcmp(species,'H2O')
                p_vcd = p_4sum.*vmr_4sum.*18.*delta_h_4sum./(R.*T_4sum.*1000);% water vapor in [mm]
            else
                p_vcd = p_4sum.*vmr_4sum.*delta_h_4sum.*Aav./(R.*T_4sum).*1e-4; % sea-salt VCD in [molec/cm2]
            end

        end
    end
end

    

lon = ncread(file_nm,'lon');
lat = ncread(file_nm,'lat');
lon = double(lon);
lat = double(lat);

[lon_diff, lon_index] = min(abs(lon - site_lon));
[lat_diff, lat_index] = min(abs(lat - site_lat));

if strcmp(profile_type,'p-VCD')
    p_vcd_interp = interp3(lat,lon,p_vcd,site_lat,site_lon);
    output_profile = p_vcd_interp;
else
    vmr_site = vmr(lon_index,lat_index,:);
    output_profile = reshape(vmr_site,[31,1]);
    h_site = h(lon_index,lat_index,:);
    output_h = reshape(h_site,[31,1]);    
end

%%

function plot_1D_profile(output_profile,output_h,time,species,profile_type)
figure;hold all;
plot(output_profile,output_h);
xlabel([species ' ' profile_type]);
ylim([0 9000]);
ylabel(['Height [m]']);

function plot_2D_profile(output_profile,output_h,time,species,profile_type)
fixed_h = 0:50:30000;
N = size(output_h);
for i = 1:1:N(2)
    profile_interp(:,i) = interp1(output_h(:,i),output_profile(:,i),fixed_h);
end
figure;hold all;
imagesc(time,fixed_h,profile_interp);

datetick('x','dd');
ylim([0 4000]);
ylabel(['Height [km]']);
ax = gca;
ax.YTick = [0 1000 2000 3000 4000];
ax.YTickLabel = {'0', '1', '2', '3', '4'};

xlabel(['March 2007']);

colorbar;
if strcmp(species,'O3')
    title(['pTOMCAT' species ' ' profile_type ' [ppbv]']);
    caxis([0 50]);
elseif strcmp(species,'BrO')
    title(['pTOMCAT' species ' ' profile_type ' [pptv]']);
    caxis([0 10]);
elseif strcmp(species,'H2O')
    title(['pTOMCAT' species ' ' profile_type ' [ppbv]']);
    %caxis([0 10]);
else
    title([species ' ' profile_type ' [ppbv]']);
    %caxis([0 10]);    
end

