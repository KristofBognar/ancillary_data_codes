% read pTOMCAT data from global files
% get_pTOMCAT_data.m (modified from Xiaoyi's code) doesn't work for global
% files, gives out of memory error (code first interpolates avarything to 1x1 deg grid)
%
% Kristof Bognar, April 2019

%% control variables
yr_to_read=2015;

% species='tg'; % BrO (pptv in files), and O3 (ppbv in files)
species='ssa'; % ppbv in files, converted to cm-3

nbins=21; % assume number of aerosol size bins is constant

% check current files to make sure structure is the same!
% file_size=[128,64,31]; % lon, lat, alt; time variable might be different in each

% loordinates, deg north, deg east
pearl_lat=80.053;
pearl_lon=273.584;

cur_dir=pwd();
save_dir='/home/kristof/work/models/pTOMCAT/';


%% merge yearly files that have been read in already
merge_files=1;

if merge_files
    
    % merge tracegas files
    yrs=2015:2018;
    
    tmp_alt=[];
    tmp_col_bro=[];
    tmp_col_o3=[];
    tmp_P=[];
    tmp_T=[];
    tmp_prof_bro=[];
    tmp_prof_o3=[];
    tmp_time=[];
    
    for i=yrs
        
        load([save_dir 'pTOMCAT_tg_' num2str(i) '.mat']);

        tmp_alt=[tmp_alt, ptom_alt];
        tmp_col_bro=[tmp_col_bro; ptom_col_bro];
        tmp_col_o3=[tmp_col_o3; ptom_col_o3];
        tmp_P=[tmp_P, ptom_P];
        tmp_T=[tmp_T, ptom_T];
        tmp_prof_bro=[tmp_prof_bro, ptom_prof_bro];
        tmp_prof_o3=[tmp_prof_o3, ptom_prof_o3];
        tmp_time=[tmp_time; ptom_time];
        
    end
    
    ptom_alt=tmp_alt;
    ptom_col_bro=tmp_col_bro;
    ptom_col_o3=tmp_col_o3;
    ptom_P=tmp_P;
    ptom_T=tmp_T;
    ptom_prof_bro=tmp_prof_bro;
    ptom_prof_o3=tmp_prof_o3;
    ptom_time=tmp_time;
    
    save([save_dir 'pTOMCAT_tg_all.mat'],...
         'ptom_prof_bro','ptom_prof_o3','ptom_col_bro','ptom_col_o3',...
         'ptom_alt','ptom_P','ptom_T','ptom_time');

    clearvars -except save_dir yrs
    
    % merge SSA files

    tmp_alt=[];
    tmp_P=[];
    tmp_T=[];
    tmp_oossa=[];
    tmp_sissa=[];
    tmp_time=[];
    
    for i=yrs
        
        load([save_dir 'pTOMCAT_ssa_' num2str(i) '.mat']);

        tmp_alt=[tmp_alt, ptom_alt];
        tmp_P=[tmp_P, ptom_P];
        tmp_T=[tmp_T, ptom_T];
        tmp_oossa=[tmp_oossa, ptom_oossa];
        tmp_sissa=[tmp_sissa, ptom_sissa];
        tmp_time=[tmp_time; ptom_time];
        
    end
    
    ptom_alt=tmp_alt;
    ptom_P=tmp_P;
    ptom_T=tmp_T;
    ptom_oossa=tmp_oossa;
    ptom_sissa=tmp_sissa;
    ptom_time=tmp_time;
    
    save([save_dir 'pTOMCAT_ssa_all.mat'],...
         'ptom_oossa','ptom_sissa','ptom_alt','ptom_P','ptom_T','ptom_time','ptom_radius');
    
    return
    
end


%% setup and checks

if strcmp(species,'tg')
    
    read_mode=1;
    data_path='/home/kristof/atmosp_servers/net/corona/model_datasets/ptomcat/';
    
elseif strcmp(species,'ssa')
    
    read_mode=2;
    data_path=...
      '/home/kristof/atmosp_servers/net/corona/model_datasets/ptomcat/SSA_only_6hrly_60_90N/';
  
    % set up some variables
    si_name=cell(nbins,1);
    oo_name=cell(nbins,1);
    radius=NaN(nbins,1);
    rmass=NaN(nbins,1);
    
    mole_nacl=58.5; % mole weight of NaCl
    mole_air=29.0; % mole weight of air
    d_nacl=2.16; % density of NaCl in g/cm^3
    
    
    for r_ind=1:nbins
        si_name{r_ind}=['SISS' num2str(r_ind)];
        oo_name{r_ind}=['OOSS' num2str(r_ind)];
        
        % radii corresponding to size bins in microns
        radius(r_ind)=(10.0^(0.15*(r_ind)-2.0)); 

        % mass of each SSA particle in g/cm^3
        rmass(r_ind)=4.0/3.0*pi*(radius(r_ind)*1e-4)^3*d_nacl;
       
    end
    
end

cd(data_path)

if yr_to_read==2018
    
    if read_mode==1
        flist={'ptom_t042_2018030100.nc','ptom_t042_2018040100.nc','ptom_t042_2018050100.nc'};
    elseif read_mode==2
        flist={'ptom_t042_2018030100_60_90N_SSA_6hrly.nc',...
               'ptom_t042_2018040100_60_90N_SSA_6hrly.nc',...
               'ptom_t042_2018050100_60_90N_SSA_6hrly.nc'};
    end
elseif yr_to_read==2017
    
    if read_mode==1
        flist={'ptom_t042_2017030100.nc','ptom_t042_2017040100.nc','ptom_t042_2017050100.nc'};
    elseif read_mode==2
        flist={'ptom_t042_2017030100_60_90N_SSA_6hrly.nc',...
               'ptom_t042_2017040100_60_90N_SSA_6hrly.nc',...
               'ptom_t042_2017050100_60_90N_SSA_6hrly.nc'};
    end
elseif yr_to_read==2016
    
    if read_mode==1
        flist={'ptom_t042_2016030100.nc','ptom_t042_2016040100.nc','ptom_t042_2016050100.nc'};
    elseif read_mode==2
        flist={'ptom_t042_2016030100_60_90N_SSA_6hrly.nc',...
               'ptom_t042_2016040100_60_90N_SSA_6hrly.nc',...
               'ptom_t042_2016050100_60_90N_SSA_6hrly.nc'};
    end
elseif yr_to_read==2015
    
    if read_mode==1    
        flist={'ptom_t042_2015030100.nc','ptom_t042_2015040100.nc','ptom_t042_2015050100.nc'};
    elseif read_mode==2
        flist={'ptom_t042_2015030100_60_90N_SSA_6hrly.nc',...
               'ptom_t042_2015040100_60_90N_SSA_6hrly.nc',...
               'ptom_t042_2015050100_60_90N_SSA_6hrly.nc'};
    end
end

% pTOMCAT time: 'days since 1970-01-01 00:00:00'
pivot_time = datenum('1970-01-01 00:00:00','yyyy-mm-dd HH:MM:SS'); 

% check size consistency and get time dimension
time_size=[];

for i=1:length(flist)
    
    % get file size info
    tmp=ncinfo(flist{i});
    
    dims=cell(5,1);
    for j=1:5
    dims{j}=tmp.Dimensions(j).Name;
    end    
    
    time_ind=find_in_cell(dims,'time');
    lat_ind=find_in_cell(dims,'lat');
    lon_ind=find_in_cell(dims,'lon');
    alt_ind=find_in_cell(dims,'niv');
    
    % file dimensions
    file_size=[tmp.Dimensions(lat_ind).Length, ...
               tmp.Dimensions(lon_ind).Length, ...
               tmp.Dimensions(alt_ind).Length];
     
    % file size check
    if i==1
        size_check=file_size;
    else
        if any(size_check-file_size ~= 0), error('File structure changed'), end
    end
    
    time_size=[time_size, tmp.Dimensions(time_ind).Length];
    
    % check coordinate arrays
    % lon indices on either side of Eureka: 98, 99 (272.8125, 275.6250) (deg east)
    % lat indices on either side of Eureka: 3, 4 (82.3128, 79.5255) (deg north)

    lon=ncread(flist{i},'lon');
    lat=ncread(flist{i},'lat');
    
    if any(lon(98:99) - [272.8125; 275.6250] > 1e4), error('Longitude array changed'), end
    if any(lat(3:4) - [82.3128; 79.5255] > 1e4), error('Latitude array changed'), end
    
end

% initialize variables

if read_mode==1
    
    % profiles: alt by time
    ptom_prof_bro=NaN(file_size(3),sum(time_size));
    ptom_prof_o3=NaN(file_size(3),sum(time_size));
    
elseif read_mode==2
    
    % aerosol: alt by time by size bin
    ptom_sissa=NaN(file_size(3),sum(time_size),nbins);
    ptom_oossa=NaN(file_size(3),sum(time_size),nbins);
    
end

ptom_alt=NaN(file_size(3),sum(time_size));
ptom_P=NaN(file_size(3),sum(time_size));
ptom_T=NaN(file_size(3),sum(time_size));

ptom_time=[];

time_ind=[0, cumsum(time_size(1:end-1))];

%% read files
n=0;
for i=1:length(flist)
    %% read data
    % read in target species
    if read_mode==1 % ozone or BrO
        
        tmp_bro=ncread(flist{i},'BrO'); % BrO in ppt
        tmp_o3=ncread(flist{i},'O3'); % O3 in ppb
        
    elseif read_mode==2 % aerosols, 21 size bins
        
        for r_ind=1:nbins
            
            tmp_sissa.(si_name{r_ind})=ncread(flist{i},si_name{r_ind}); % in ppb
            tmp_oossa.(oo_name{r_ind})=ncread(flist{i},oo_name{r_ind}); % in ppb
            
        end
    end

    % read other variables
    tmp_alt=ncread(flist{i},'gl3d'); % altitude in m
    tmp_P=ncread(flist{i},'p'); % pressure in Pa
    tmp_T=ncread(flist{i},'t3d'); % temperature in K
    
    tmp_time=double(ncread(flist{i},'time') + pivot_time);
    ptom_time=[ptom_time; datetime(tmp_time,'convertfrom','datenum')];
    
    %% loop over each time step in file
    for t_ind=1:time_size(i) 
        
        % display progress info
        disp_str=[flist{i} ', timestep ' num2str(t_ind) '/' num2str(time_size(i)) ];
        % stuff to delete last line and reprint updated message
        fprintf(repmat('\b',1,n));
        fprintf(disp_str);
        n=numel(disp_str);    

        %% loop over each altitude level
        for h_ind=1:file_size(3) 
            % 2d interpolation, model grid (4 points surrounding PEARL) is hard coded
            
            if read_mode==1
                ptom_prof_bro(h_ind,t_ind+time_ind(i))=interp2(...
                                                    [82.3128, 79.5255],[272.8125, 275.6250],...
                                                    tmp_bro(98:99,3:4,h_ind,t_ind),...
                                                    pearl_lat,pearl_lon);

                ptom_prof_o3(h_ind,t_ind+time_ind(i))=interp2(...
                                                    [82.3128, 79.5255],[272.8125, 275.6250],...
                                                    tmp_o3(98:99,3:4,h_ind,t_ind),...
                                                    pearl_lat,pearl_lon);

            elseif read_mode==2
                %% extra size bin loop for aerosols
                for r_ind=1:nbins
                    
                    ptom_sissa(h_ind,t_ind+time_ind(i),r_ind)=interp2(...
                               [82.3128, 79.5255],[272.8125, 275.6250],...
                               tmp_sissa.(si_name{r_ind})(98:99,3:4,h_ind,t_ind),...
                               pearl_lat,pearl_lon);
                    
                    ptom_oossa(h_ind,t_ind+time_ind(i),r_ind)=interp2(...
                               [82.3128, 79.5255],[272.8125, 275.6250],...
                               tmp_oossa.(oo_name{r_ind})(98:99,3:4,h_ind,t_ind),...
                               pearl_lat,pearl_lon);
                    
                end
                
            end
            
            ptom_alt(h_ind,t_ind+time_ind(i))=interp2(...
                                                [82.3128, 79.5255],[272.8125, 275.6250],...
                                                tmp_alt(98:99,3:4,h_ind,t_ind),...
                                                pearl_lat,pearl_lon);

            ptom_P(h_ind,t_ind+time_ind(i))=interp2(...
                                                [82.3128, 79.5255],[272.8125, 275.6250],...
                                                tmp_P(98:99,3:4,h_ind,t_ind),...
                                                pearl_lat,pearl_lon);
                                            
            ptom_T(h_ind,t_ind+time_ind(i))=interp2(...
                                                [82.3128, 79.5255],[272.8125, 275.6250],...
                                                tmp_T(98:99,3:4,h_ind,t_ind),...
                                                pearl_lat,pearl_lon);
                                            
        end
    end
end

% flip arrays so low index is low altitude
ptom_alt=flipud(ptom_alt);
ptom_P=flipud(ptom_P);
ptom_T=flipud(ptom_T);

if read_mode==1
    %% calculate columns for BrO and O3
    
    ptom_prof_bro=flipud(ptom_prof_bro);
    ptom_prof_o3=flipud(ptom_prof_o3);

    % air number density in molec/m3
    n_air=(6.022141e23*ptom_P)./(8.3144598*ptom_T); 

    % species profile in molec/m3
    tmp_bro=(ptom_prof_bro*1e-12).*n_air;
    tmp_o3=(ptom_prof_o3*1e-9).*n_air;
    
    % species column calculation (molec/m2)
    ptom_col_bro=NaN(size(ptom_time));
    ptom_col_o3=NaN(size(ptom_time));

    for i=1:size(tmp_bro,2)

        ptom_col_bro(i)=integrate_nonuniform(...
                            ptom_alt(:,i), tmp_bro(:,i), 0, 4000, 'trapez', 1);
        ptom_col_o3(i)=integrate_nonuniform(...
                            ptom_alt(:,i), tmp_o3(:,i), 0, 4000, 'trapez', 1);

    end

    % convert column to molec/cm2
    ptom_col_bro=ptom_col_bro*1e-4;
    ptom_col_o3=ptom_col_o3*1e-4;
    
    
    %% save data
    save([save_dir 'pTOMCAT_tg_' num2str(yr_to_read) '.mat'],...
         'ptom_prof_bro','ptom_prof_o3','ptom_col_bro','ptom_col_o3',...
         'ptom_alt','ptom_P','ptom_T','ptom_time');


elseif read_mode==2
    %% calculate aerosol number densities (code from Xin)
    
    ptom_sissa=flipud(ptom_sissa);
    ptom_oossa=flipud(ptom_oossa);
    
    % air density in g/cm^3
    d_air=( ptom_P./(287.058*ptom_T) )*1e3*1e-6;

    % SSA number densities in particle/cm^3
    for r_ind=1:nbins

        ptom_sissa(:,:,r_ind) = 1e-9*ptom_sissa(:,:,r_ind)/rmass(r_ind)*...
                                mole_nacl/mole_air./d_air;
                            
        ptom_oossa(:,:,r_ind) = 1e-9*ptom_oossa(:,:,r_ind)/rmass(r_ind)*...
                                mole_nacl/mole_air./d_air;

    end    

    %% save data
    ptom_radius=radius;
    save([save_dir 'pTOMCAT_ssa_' num2str(yr_to_read) '.mat'],...
         'ptom_sissa','ptom_oossa',...
         'ptom_alt','ptom_P','ptom_T','ptom_time','ptom_radius');

    
end


cd(cur_dir)

fprintf('\n');

    
    
    
    





