% Read MODIS sea ice data
% 
% MODIS files contain individual tiles of the Lambert Azimuthal Equal-Area Tile Grid
% Only read tile over Eureka (horizontal tile 8, vertical tile 9)
% Code can read any MODIS sea ice file that uses the same grid
% Saved coordinates for pixels in Eureka tile only

% mask key in MODIS files:
% 0=missing data
% 1=no decision
% 11=night
% 25=land
% 37=inland water
% 39=ocean
% 50=cloud
% 200=sea ice
% 253=land mask
% 254=ocean mask
% 255=fill

% mask in plot_SI:
% night: 0.5
% land + inland water + land mask: 1.5
% ocean + ocean mask: 2.5
% clouds: 3.5
% sea ice: 4.5
% other: NaN


%% Setup

% folder with MODIS SI files
% file_dir='/home/kristof/work/BEEs/sea_ice_data/MODIS_Terra';
file_dir='/home/kristof/atmosp_servers/net/corona/satellite/modis/tile_h08_v09';

save_dir='/home/kristof/atmosp_servers/net/corona/satellite/modis/';

% load coordinates for each pixel in Eureka tile
% load('/home/kristof/work/BEEs/sea_ice_data/modis_grid_h8v9_lat_lon.mat');

% change directories
cur_dir=pwd();
cd(file_dir);

% get list of files, Eureka tile only
tmp = dir('*h08v09*.hdf'); 
f_list_all = {tmp.name};

% get years
dates=zeros(length(f_list_all),2);
for i=1:length(f_list_all)
    dates(i,1)=str2double(f_list_all{i}(11:14));
    dates(i,2)=str2double(f_list_all{i}(15:17));
end

y_list=unique(dates(:,1));

%% loop over each year separately, too much data
for yr=y_list'
    
    % save details/checks
    save_file=[save_dir 'MODIS_Eureka' num2str(yr) '.mat'];

    if exist(save_file,'file')

        disp(['Warning: MODIS file ' 'MODIS_Eureka' num2str(yr) '.mat' ' aready exists'])
        disp('(return): overwrite; (<text>): save file as MODIS_<text>; (n): quit')
        tmp=input('','s');

        if ~isempty(tmp)

            if strcmp(tmp,'n'), cd(cur_dir); return, end

            save_file=[save_dir 'MODIS_' tmp '.mat'];
            disp(['Will save data in ' save_file]);
        end
    else
        disp(['Reading ' num2str(yr) ' MODIS data'])
    end

    %% Read files

    % get list of files for given year, March-May only
    inds=find(dates(:,1)==yr & dates(:,2)>55 & dates(:,2)<154);
    
    f_list=f_list_all(inds);
    
    % initialize variables
    sea_ice=NaN(951,951,length(f_list));

    year=NaN(length(f_list),1);
    doy=NaN(length(f_list),1);
    sat_id=cell(length(f_list),1);

    % read all the files
    for i=1:length(f_list)

        % read current file
        try
            si=hdfread(f_list{i},'/MOD_Grid_Seaice_1km/Data Fields/Sea_Ice_by_Reflectance');
        catch
            error('HDF file format changed!')
        end

        % assign data
        sea_ice(:,:,i)=si;

        % get other info
        tmp=strsplit(f_list{i},'.');

        year(i)=str2double(tmp{2}(2:5));
        doy(i)=str2double(tmp{2}(6:8));

        if strcmp(tmp{1}(1:3),'MYD')
            sat_id{i}='Aqua';
        elseif strcmp(tmp{1}(1:3),'MOD')
            sat_id{i}='Terra';
        end

    end

    %% sort by day 
    % files are read alphabetically, so all of terra data is read first, then aqua
    % (both terra and aqua pass over Eureka multiple times a day,
    % so daily data is composed of all those measurements)
    [doy,sortind]=sort(doy);

    year=year(sortind);
    sat_id=sat_id(sortind);
    f_list=f_list(sortind);
    sea_ice=sea_ice(:,:,sortind);

%     %% create new mask
%     plot_SI=NaN(size(sea_ice));
% 
%     % night
%     plot_SI(sea_ice==11)=0.5;
% 
%     % land + inland water
%     plot_SI(sea_ice==25)=1.5;
%     plot_SI(sea_ice==253)=1.5;
%     plot_SI(sea_ice==37)=1.5;
% 
%     % water
%     plot_SI(sea_ice==39)=2.5;
%     plot_SI(sea_ice==254)=2.5;
% 
%     % clouds
%     plot_SI(sea_ice==50)=3.5;
% 
%     % sea ice
%     plot_SI(sea_ice==200)=4.5;


    %% save data
%     save(save_file, 'sea_ice','plot_SI','year','doy','sat_id','f_list');
    save(save_file, 'sea_ice','year','doy','sat_id','f_list');

    clearvars sea_ice
    
end

cd(cur_dir);


