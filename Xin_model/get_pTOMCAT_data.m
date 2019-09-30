function [ ft, vcd_out, lat_out, lon_out, h_out ] = get_pTOMCAT_data(species,VCD_type,yr_to_read)
%GET_PTOMCAT_DATA Summary of this function goes here
%   Detailed explanation goes here
%
%%% old version from Xiaoyi, interpolates all data -- slow for global files

% species = 'BrO'; % could be 'O3', 'H2O', 'BrO', 'OOSS#', and 'SISS#'
% species = 'SISS10'; % could be 'O3', 'H2O', 'BrO', 'OOSS#', and 'SISS#'
% VCD_type = 'prof'; % could be 'total', 'trop', 'strat' or 'prof'

data_path = '/home/kristof/atmosp_servers/net/corona/model_datasets/ptomcat';
cd(data_path)
% flist = {'ptom_t042_2017030100-45N-90N.nc','ptom_t042_2017040100-45N-90N.nc'}; %2017 old

if yr_to_read==2018
    flist={'ptom_t042_2018030100.nc','ptom_t042_2018040100.nc','ptom_t042_2018050100.nc'}; %2018
end

onepoint=true;


% pTOMCAT 'days since 1970-01-01 00:00:00'
pivot_time = datenum('1970-01-01 00:00:00','yyyy-mm-dd HH:MM:SS'); 

time=[];
lat_out=[];
lon_out=[];
vcd=[];
vcd_out=[];
h=[];
h_out=[];

t1=0;
for files=1:length(flist)

    % convert to MATLAB serial time
    tmp = double(ncread(flist{files},'time') + pivot_time); 
    time=[time;tmp];
    
    for i=1:length(tmp)
        
        [tmp_lat,tmp_lon, tmp_vcd, tmp_h]=read_ptomcat_data(i,species ,flist{files},VCD_type);

        lat_out=tmp_lat;
        lon_out=tmp_lon;
        vcd(:,:,:,i+t1)=tmp_vcd;
        h(:,:,:,i+t1)=tmp_h;

    end
    
    t1=t1+length(tmp);
end

if onepoint
    
    [~,ind_lat]=min(abs(lat_out-80.05));
    [~,ind_lon]=min(abs(lon_out-273.75));

    if size(vcd,3)==1
        for i=1:size(vcd,4)
            vcd_out(i)=vcd(ind_lon,ind_lat,1,i);
        end
    else
        for i=1:size(vcd,4)
            vcd_out(i,:)=vcd(ind_lon,ind_lat,:,i);
            h_out(i,:)=h(ind_lon,ind_lat,:,i);
        end
        
        vcd_out=fliplr(vcd_out);
        h_out=fliplr(h_out)./1000; % convert to km
    end
end


[ft,year]=fracdate(datetime(time,'convertfrom','datenum'));

end


%% stuff
function [lat_out,lon_out,vcd, h_interp]=read_ptomcat_data(time_step,species,file_nm,VCD_type)

do_interp = 1; % 1 = yes, interp data to 1*1 degree grid
Aav = 6.02e23;
R = 8.314;
R_spec=287.05;
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
        elseif strcmp(VCD_type , 'prof')
%             inds=find(h(i,j,:)<4000);
            if strcmp(species,'BrO') || strcmp(species,'O3')
                % BrO profile in pptv
                vcd(i,j,:)=vmr(i,j,:);
            elseif ~isempty(strfind(species,'SISS')) || ~isempty(strfind(species,'OOSS'))
                % SSA profile in g/cm3
                % convert vmr to mmr first, using Xin's molar masses
                % air: 29 g/mol; NaCl: 58.5 g/mol
                % then multiply by dry air density (converted to g/cm3)
                vcd(i,j,:)=vmr(i,j,:) *(58.5/29) *1e-9... 
                           .* (p(i,j,:)./ (R_spec.*T(i,j,:))) *1e-6 *1e3 ;
            end
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
    lat_out=lat_interp;
    %lon_interp = [min(lon):1:max(lon)+1]';
    lon_interp = [0:1:360]';
    lon_out=lon_interp;
    [lat_interp,lon_interp] = meshgrid(lat_interp,lon_interp);
    [lat,lon] = meshgrid(lat,lon);
    
    h_interp=[];

    if size(vcd,3)==1
        vcd = [vcd;vcd(end,:)];
        vcd_interp = interp2(lat,lon,vcd,lat_interp,lon_interp);
        
    else
        vcd_interp=[];
        for levels=1:size(vcd,3)
            tmp = [vcd(:,:,levels);squeeze(vcd(end,:,levels))];
            tmp_interp = interp2(lat,lon,tmp,lat_interp,lon_interp);
            
            vcd_interp(:,:,levels)=tmp_interp; 
            
            tmp = [h(:,:,levels);squeeze(h(end,:,levels))];
            tmp_interp = interp2(lat,lon,tmp,lat_interp,lon_interp);
            
            h_interp(:,:,levels)=tmp_interp; 

        end
    end
    
    vcd = vcd_interp;
    
    lat = lat_interp;
    lon = lon_interp;   
            
    
end

end