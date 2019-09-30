% To read SMPS and OPC data from Eureka (provided by Partick Hayes / Samantha Tremblay/ 
% Andy Vicente-Luis)
%
% Use newer version provided by Andy, the OPC numbers look correct here (in
% Samantha's files the numbers were huge, probably a unit conversion issue)

read_SMPS=true;

if read_SMPS
    %% SMPS files

    for year=2016:2018

        filename=['SMPS_data_' num2str(year) '-03 to ' num2str(year) '-05.xlsx'];

        disp(['Processing ' filename]);

        sheet=1; 
        
        % Read partice diameters
        range='C1:BD1';
        smps_Dp = xlsread(filename,sheet,range);

        % Read time axis
        if year==2016
            smps_time=xlsread(filename,sheet,'A3:A43099');
        elseif year==2017
            smps_time=[smps_time;xlsread(filename,sheet,'A3:A43990')];
        elseif year==2018
            smps_time=[smps_time;xlsread(filename,sheet,'A3:A44138')];
        end

        % Read size distribution data
        if year==2016
            smps_data_raw=xlsread(filename,sheet,'C3:BD43099');
        elseif year==2017
            smps_data_raw=[smps_data_raw; xlsread(filename,sheet,'C3:BD43990')];
        elseif year==2018
            smps_data_raw=[smps_data_raw; xlsread(filename,sheet,'C3:BD44138')];
        end

        % Read integrated data
        sheet=2;
        if year==2016
            smps_tot_data=xlsread(filename,sheet,'B3:B43099');
        elseif year==2017
            smps_tot_data=[smps_tot_data; xlsread(filename,sheet,'B3:B43990')];
        elseif year==2018
            smps_tot_data=[smps_tot_data; xlsread(filename,sheet,'B3:B44138')];
        end

    end

    % convert time to matlab datetime
    smps_time=datetime(smps_time,'ConvertFrom','excel'); 

    % convert dN/dlog10(Dp) to N
    
    smps_data=NaN(size(smps_data_raw));
    
    Dp_edge=(smps_Dp(2:end)+smps_Dp(1:end-1))/2;
    Dp_edge=[10,Dp_edge,500];
    logDp=log10(Dp_edge(2:end)./Dp_edge(1:end-1));
    
    for i=1:length(logDp)
        smps_data(:,i)=smps_data_raw(:,i)*logDp(i);
    end
    
    
    % Save variables
    save smps_size_dist_all.mat smps_Dp smps_time smps_data_raw smps_data smps_tot_data

    clearvars    
    
    
else 
    %% OPC files

    for year=2016:2018

        filename=['OPC_data_' num2str(year) '-03 to ' num2str(year) '-05.xlsx'];

        disp(['Processing ' filename]);

        sheet=1; 

        % Read time axis
        if year==2016
            opc_time=xlsread(filename,sheet,'A3:A34231');
        elseif year==2017
            opc_time=[opc_time;xlsread(filename,sheet,'A3:A35115')];
        elseif year==2018
            opc_time=[opc_time;xlsread(filename,sheet,'A3:A46693')];
        end

        % Read size distribution data
        if year==2016
            opc_data=xlsread(filename,sheet,'C3:H34231');
        elseif year==2017
            opc_data=[opc_data; xlsread(filename,sheet,'C3:H35115')];
        elseif year==2018
            opc_data=[opc_data; xlsread(filename,sheet,'C3:H46693')];
        end

        % Read integrated data
        sheet=2;
        if year==2016
            opc_tot_data=xlsread(filename,sheet,'B3:B34231');
        elseif year==2017
            opc_tot_data=[opc_tot_data; xlsread(filename,sheet,'B3:B35115')];
        elseif year==2018
            opc_tot_data=[opc_tot_data; xlsread(filename,sheet,'B3:B46693')];
        end

    end

    % Partice diameters
    opc_Dp=[300,500,1000,2000,5000,10000];

    % convert time to matlab datetime
    opc_time=datetime(opc_time,'ConvertFrom','excel'); 

    % Save variables
    save opc_size_dist_all.mat opc_Dp opc_time opc_data opc_tot_data

    clearvars

end


