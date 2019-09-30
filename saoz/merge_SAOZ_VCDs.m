% merge and filter yearly VCD values

%% control variables

%instrument
instr='SAOZ';

% RCD calculation in the retrieval
% rcd_type='fix';
rcd_type='daily';

% trace gas (1: ozone, 2: NO2, 3: NO2 UV)
tg=1;
tgstr={'O3','NO2'};

% VCD directory
% vcd_dir='/home/kristof/work/SAOZ/VCD_results_max5_SZA/';
% vcd_dir='/home/kristof/work/SAOZ/VCD_results_fix_SZA/';
vcd_dir='/home/kristof/work/SAOZ/VCD_results_fix_SZA_sonde_to_LUT/';

% output file name (remove file if already exists)
fname=[vcd_dir instr '_' tgstr{tg} '_' rcd_type 'RCD_all.mat'];
if exist(fname,'file'), delete(fname), end

%% find files
data=[];

% make list of VCD files
tmp = dir([vcd_dir instr '_' tgstr{tg} '_VCD_*.mat']); 
f_list = {tmp.name}; % cell array of file names

%% loop over VCD files
cd(vcd_dir)

for file=f_list
    
    load(file{1})
    
    if tg==2, rcd_S2=rcd_S; end
    
    % filter out NaNs and bad RCD values
    switch rcd_type
        case 'fix'
            instr_in=3;
            [ind_goodvcd,VCD_table_tmp] = filter_VCD_output( tg+3, VCD_table,...
                                                             rcd_S, instr_in,false);
        case 'daily'
            instr_in=4;            
            [ind_goodvcd,VCD_table_tmp] = filter_VCD_output( tg+3, VCD_table2,...
                                                             rcd_S2, instr_in,false);
            
    end
    VCD_filt=VCD_table_tmp(ind_goodvcd,:);
    
%     reanalysis=vertcat(reanalysis,VCD_filt);
    data=[data;VCD_filt];

end

%% add time information
data.mjd2k=ft_to_mjd2k(data.fd-1,data.year);
data.fractional_time=data.fd-1;

%% save file

save(fname,'data');

clearvars
