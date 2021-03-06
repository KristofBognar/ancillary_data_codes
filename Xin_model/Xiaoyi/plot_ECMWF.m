function plot_ECMWF()
save_fig = 1;
species = 'blh'; % could be 'fg10','blh' or 't2m'. Check the info of the nc file to look what is available

data_path = 'E:\Xin\ECMWF';
file_nm = '2007.nc';

cd(data_path);
plot_path = ['plot_ECMWF_surface_' species];


try 
    mkdir(plot_path);
end
pivot_time = datenum('1900-01-01 00:00:00','yyyy-mm-dd HH:MM:SS'); % pTOMCAT 'days since 1970-01-01 00:00:00'
time = double(ncread(file_nm,'time'))./24 + pivot_time; % convert to MATLAB serial time
N = size(time);
time_stamp = datestr(time,'yyyymmdd HH');

%for i = 1:1:N(1)
for i = 9:1:9
    plot_single_time_step(i,species,file_nm,time_stamp);    
    cd(plot_path);
    print_setting(1/2,save_fig,['ECMWF_surface_' species '_' time_stamp(i,:)]);
    cd ..;
    %close all;
end

%% 
function plot_single_time_step(time_step,species,file_nm,time_stamp)
do_interp = 1;
data = ncread(file_nm,species);% 4D [lon,lat,vmr,time]

vmr = data(:,:,time_step);
lon = ncread(file_nm,'longitude');
lat = ncread(file_nm,'latitude');
    lon = double(lon);
    lat = double(lat);

if do_interp == 0
    [lat,lon] = meshgrid(lat,lon);

else
    lon = [lon;360];
    lat_interp = [min(lat):0.2:max(lat)]';
    %lon_interp = [min(lon):1:max(lon)+1]';
    lon_interp = [0:0.2:360]';
    [lat_interp,lon_interp] = meshgrid(lat_interp,lon_interp);
    [lat,lon] = meshgrid(lat,lon);
    vmr = [vmr;vmr(end,:)];
    vmr_interp = interp2(lat,lon,vmr,lat_interp,lon_interp);
    vmr = vmr_interp;
    lat = lat_interp;
    lon = lon_interp;   
end



figure('Color','white'); hold all;
ncpolarm('seaice','label');
%ncpolarm('asm');
%axesm miller
%axis off; framem on; gridm on;
%pcolorm(lat,lon,vmr');
pcolorm(lat,lon,vmr);
%imagesc(lat,lon,vmr');
load coastlines
plotm(coastlat, coastlon);
colorbar;
%caxis([0 30]);
title([ species ' ' time_stamp(time_step,:)]);
%ylim([-0.5 0.3]);
%xlim([-0.5 0.1]);
xlim([-0.4 0.09]);
ylim([-0.3 0.3]);
caxis([200 800]);
%caxis([5 25]);

%% 
function plot_VCD_single_time_step(time_step,species,file_nm,time_stamp,VCD_type)
do_interp = 1; % 1 = yes, interp data to 1*1 degree grid
Aav = 6.02e23;
R = 8.314;
DU = 2.69e20;
data = ncread(file_nm,species);% 4D [lon,lat,model level,time]
%vmr = data(:,:,31,1);
vmr = data(:,:,:,time_step);

ptrop1 = ncread(file_nm,'ptrop2');%troppause pressure Pa [lon,lat,time]
ptrop1 = ptrop1(:,:,time_step);
p = ncread(file_nm,'p');% pressure Pa [lon,lat,sigma,time]
p = p(:,:,:,time_step);
T = ncread(file_nm,'t3d');% temepature K [lon,lat,sigma,time]
T = T(:,:,:,time_step);
h = ncread(file_nm,'gl3d');% inter level geopotential height in m [lon,lat,sigma,time]
h = h(:,:,:,time_step);
M = size(p);
for i = 1:1:M(1)
    for j = 1:1:M(2)
        TF = p(i,j,:) >= ptrop1(i,j).*100;
        vmr_4sum = vmr(i,j,:).*1e-9;% vmr read in is ppbv for ozone, h2o, SSA, and OOA [note, for BrO the unit is pptv, but we will convert it later]
        p_4sum = p(i,j,:);
        T_4sum = T(i,j,:);
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
        if strcmp(VCD_type, 'trop')
            vmr_4sum(~TF) = [];
            p_4sum(~TF) = [];
            T_4sum(~TF) = [];
            delta_h_4sum(~TF) = [];
        elseif strcmp(VCD_type , 'start')
            vmr_4sum(TF) = [];
            p_4sum(TF) = [];
            T_4sum(TF) = [];
            delta_h_4sum(TF) = [];
        elseif strcmp(VCD_type , 'total')
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
        %vcd(i,j) = sum(p_vcd(:,:,11:31));
        if strcmp(VCD_type, 'total') % for the quality of integrated column, we only use profile from surface up to ~90 km
            %vcd(i,j) = sum(p_vcd(1,1,11:31));
            vcd(i,j) = sum(p_vcd(1,1,:));
        elseif strcmp(VCD_type , 'start')
            %vcd(i,j) = sum(p_vcd(1,1,11:end));
            vcd(i,j) = sum(p_vcd(1,1,:));
        elseif strcmp(VCD_type , 'trop')
            vcd(i,j) = sum(p_vcd(1,1,:));
        end
    end
end

    

lon = ncread(file_nm,'lon');
lat = ncread(file_nm,'lat');
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
%caxis([1e13 1e14]); % BrO trop VCD
%caxis([0 25]); % PWV
caxis([0 1e14]); % SISS
title([ species ' ' time_stamp(time_step,:)]);

