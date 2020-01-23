% read Photoacoustic Extinctiometer (PAX) data
% instruments are located in the Ridge Lab
%
% latest file from Andy Vicente-Luis contains 2017-2019 data for March May,
% from PAX405 and PAX870 (numbers are wavelength in nm)

%% setup

cd('/home/kristof/work/SMPS/')

filename='PAX_BCmass_Spring_2017_to_2019.xlsx';

startrow='5';
endrow='2212';

pax405=table();
pax870=table();

%% read file

for sheet=1:2

    % Read time axis
    pax_time=[xlsread(filename,sheet,['A' startrow ':A' endrow]);...
              xlsread(filename,sheet,['E' startrow ':E' endrow]);...
              xlsread(filename,sheet,['I' startrow ':I' endrow])];
          
    pax_time=datetime(pax_time,'ConvertFrom','excel');    
    
    % Read absorption data
    pax_abs=[xlsread(filename,sheet,['B' startrow ':B' endrow]);...
             xlsread(filename,sheet,['F' startrow ':F' endrow]);...
             xlsread(filename,sheet,['J' startrow ':J' endrow])];

    % Read BC mass concentration data
    pax_BC=[xlsread(filename,sheet,['C' startrow ':C' endrow]);...
            xlsread(filename,sheet,['G' startrow ':G' endrow]);...
            xlsread(filename,sheet,['K' startrow ':K' endrow])];
         
    if sheet==1
        pax405.DateTime=pax_time;
        pax405.absorption=pax_abs;
        pax405.BC_mass_conc=pax_BC;
    elseif sheet==2
        pax870.DateTime=pax_time;
        pax870.absorption=pax_abs;
        pax870.BC_mass_conc=pax_BC;
    end
        
end

% Save variables
save PAX_BC.mat pax405 pax870



