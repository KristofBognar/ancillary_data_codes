% match sea ice age EASE-grid to FLEXPART grid cells
%
%

error('Use python code on berg')
% wrote code in python instead, so it can run on the server.
% saved x_FP_mesh and y_FP_mesh here
% berg/kbognar/FLEXPART_10.02/grid_data/match_fine_FLEXPART_grid_to_SI_age_grid.py


%% load data

% EASE-grid is 12.5x12.5 km (12.534 km), on an equal area grid,
% coordinates in the .nc files are grid centres
load('/home/kristof/work/BEEs/sea_ice_data/EASE_grid_SI_age.mat')

% save x_age.mat x_age;
% save y_age.mat y_age;

% FLEXPART was run using a NH 0.5°x0.5° grid, so actual size of cells
% changes with latitude (55.7 km tall, with from 55 km at 0° --> 5 km at 85°)
% coords are cell centres, bottom left of grid is lat=0, lon=-179
load('/home/kristof/work/flexpart/BrO_back_runs_v1/BrO_back_runs_v1_3day.mat')

% convert to 0-360, east of Greenwich
longitude(longitude<0)=longitude(longitude<0)+360;

%% Get fine FP grid and convert to equal area projection

% make fine FP grid (custom resolution)
step_lat=0.01; % cells are just over 1km tall
lat_FP_fine=[30+step_lat/2:step_lat:90-step_lat/2]'; % need only 30N and higher
step_lon=0.025; % cells are ~1km at 70°, smaller above
lon_FP_fine=[0+step_lon/2:step_lon:360-step_lon/2]';

% sensitivities are lat,lon for rows, columns, but mexhgrid is x,y using
% function notation (columns, rows)
[lon_FP_mesh,lat_FP_mesh]=meshgrid(lon_FP_fine,lat_FP_fine);

% convert FLEXPART grid cell centres to equal area coords -- area is not known
[x_FP_mesh,y_FP_mesh]=latlon_to_EASE_grid_coord_transform(lat_FP_mesh, lon_FP_mesh);

% save x_FP_mesh.mat x_FP_mesh;
% save y_FP_mesh.mat y_FP_mesh;
% return

%% match each FP cell to a SI cell

% mask with linear index of SI cells
FP_fine_mask=NaN(size(x_FP_mesh));

% width of each SI cell (squares in the equal area projection)
SI_size=mean(diff(x_age));

% loop over entire SI age array
count=1;
n=0;
for col=1:length(x_age)
    
    % get indices here, use intersect for ech row
    ind_match_col=find(x_FP_mesh>x_age(col)-SI_size/2 & ...
                       x_FP_mesh<=x_age(col)+SI_size/2     );

    % display progress info
    disp_str=['Column ' num2str(col)];
    % stuff to delete last line and reprint updated message
    fprintf(repmat('\b',1,n));
    fprintf(disp_str);
    n=numel(disp_str);    

    for row=1:length(y_age)
        
        % indices of FP cells within given SI cell (ignore area, just check
        % center coordinates)
        ind_match_row=find(y_FP_mesh>y_age(row)-SI_size/2 & ...
                           y_FP_mesh<=y_age(row)+SI_size/2     );
                   
        % assign SI mask (count is the linear index of the SI grid)
        ind_match=intersect(ind_match_col,ind_match_row);
        FP_fine_mask(ind_match)=count;
    
        % advance linear index
        count=count+1;
    end
end

fprintf('\n')




%% old approach, would take hours, and results are not reuseable
% % %% convert FLEXPART grid cell centres to equal area coords -- area is not known
% % 
% % % sensitivities are lat,lon for rows, columns, but mexhgrid is x,y using
% % % function notation (columns, rows)
% % [lon_FP_mesh,lat_FP_mesh]=meshgrid(longitude,latitude);
% % 
% % [x_FP_mesh,y_FP_mesh]=latlon_to_EASE_grid_coord_transform(lat_FP_mesh, lon_FP_mesh);
% % 
% % 
% % %% redefine SI grid
% % 
% % 
% % % make fine SI grid -- area is known!!
% % % break up each cell into 11x11 cells: area of small cells is 1.2983075 km^2
% % fine=11; 
% % step=mean(diff(x_age))/fine;
% % x_age_fine=[x_age(1):step:x_age(end)]'; % half of edge cells missing, no SI there anyway
% % y_age_fine=[y_age(1):step:y_age(end)]';
% % 
% % % make meshgrids for SI grids
% % [x_age_mesh,y_age_mesh]=meshgrid(x_age,y_age);
% % [x_age_fine_mesh,y_age_fine_mesh]=meshgrid(x_age_fine,y_age_fine);
% % 
% % % assign SI mask values to fine grid
% % i=1;
% % age_fine=interp2(x_age_mesh,y_age_mesh,age(:,:,i),...
% %                  x_age_fine_mesh,y_age_fine_mesh,'nearest');
% % 
% % % first year sea ice mask
% % fysi_ind=find(age_fine==1);
% % 
% % 
% % %% get sensitivity 
% % % need to use griddata, sice interp2 takes equally spaced grids only
% % sens_vector=sensitivities(:,:,i);
% % 
% % % use SI cells with fysi mask only to speed up interpolation
% % 
% % tic 
% % si_sens_tmp=griddata(x_FP_mesh(:),y_FP_mesh(:),sens_vector(:),...
% %                      x_age_fine_mesh(fysi_ind),y_age_fine_mesh(fysi_ind),'nearest');
% % 
% % si_sens=si_sens_tmp.*age_fine(fysi_ind);
% % toc
% % % 4 min for single run if full si array is used
% % % use coordinates for SI age of interest only, speeds up code dramatically
% % 
% % 
