function [ x_arr, y_arr ] = latlon_to_EASE_grid_coord_transform( lat_arr, lon_arr )
%[ x_arr, y_arr ] = latlon_to_EASE_grid_coord_transform( lat_arr, lon_arr )
%
% Converts latitude and longitude values to northern hemisphere EASE-grid x
% and y coordinates
%
% lat_arr and lon_arr must be the same size; elemens corresponds to
% pairs of coordinates
% x_arr, y_arr (units: m) is the same size as lat_arr and lon_arr
%
%
% Brodzik, M. J., B. Billingsley, T. Haran, B. Raup, M. H. Savoie. 2012. EASE-Grid 2.0: 
% Incremental but Significant Improvements for Earth-Gridded Data Sets. ISPRS 
% International Journal of Geo-Information, 1(1):32-45, doi:10.3390/ijgi1010032. 
% http://www.mdpi.com/2220-9964/1/1/32.
% 
% Brodzik, M. J., B. Billingsley, T. Haran, B. Raup, M. H. Savoie. 2014. Correction: 
% Brodzik, M. J. et al. EASE-Grid 2.0: Incremental but Significant Improvements for 
% Earth-Gridded Data Sets. ISPRS International Journal of Geo-Information 2012, 1, 
% 32-45. ISPRS International Journal of Geo-Information, 3(3):1154-1156, 
% doi:10.3390/ijgi3031154. http://www.mdpi.com/2220-9964/3/3/1154
%
% @Kristof Bognar, August 2019

if any(any(lon_arr<0)), error('Longitude must be positive, east of Greenwich'), end
if any(any(lat_arr<0)), error('Code works for northern hemisphere only'), end

%% 

% It is not clear which version on EASE-grid the SI files use. Parameters
% from the user guide on NSIDC indicate v1, but the north pole is clearly
% in the corner of the 4 northernmost cells, indicating v2 (v1 has the
% pole in the middle of a cell).
% Code reporoduces x, y coordinates in SI files with <1m accuracy by using:
%   formulas for EASE-grid v2, from citations above
%   parameters for International 1924 Authalic Sphere

%%

% parameters for EASE-grid v2 -- not what is used in SI files!!
% eq_radius=6378137; % WGS 84
% ecc=0.0818191908426;

% parameters for EASE-grid v1 -- eccentricity should be 0, but that doesn't
% work with the formula
eq_radius=6371228; % International 1924 Authalic Sphere
ecc=1e-5;

% threshold, and lat limit for NH
eps=1e-12; 
lon_0=0;

% Eqn 2
calc_q = @(lat) (1-ecc^2) .* ...
                ( ( sind(lat) ./ (1 - ecc^2 * sind(lat).^2) ) - ...
                  (0.5/ecc)* log( (1 - ecc*sind(lat)) ./ (1 + ecc*sind(lat)) ) );

q_90=calc_q(90);

q_lat=calc_q(lat_arr);

% corrected eqn 10
rho=zeros(size(q_lat));

inds=find(abs(q_90-q_lat)>=eps);

rho(inds)=eq_radius*sqrt(q_90 - q_lat(inds));

% output (eqn 11-12)

x_arr=rho.*sind(lon_arr-lon_0);

y_arr=-rho.*cosd(lon_arr-lon_0);



end

