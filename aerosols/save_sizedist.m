% To read SMPS, OPC and APS data from Eureka (provided by Partick Hayes / Samantha Tremblay/ 
% Andy Vicente-Luis)
%
% OPC was replaced by APS in late 2018
%
% Use newer version provided by Andy, the OPC numbers look correct here (in
% Samantha's files the numbers were huge, probably a unit conversion issue)

read_SMPS=0;
read_OPC=0;
read_APS=1;

if read_SMPS
    %% SMPS files

    for year=2016:2019

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
        elseif year==2019
            smps_time=[smps_time;xlsread(filename,sheet,'A3:A44107')];
        else
            error(['Check data range for ', year])
        end

        % Read size distribution data
        if year==2016
            smps_data_raw=xlsread(filename,sheet,'C3:BD43099');
        elseif year==2017
            smps_data_raw=[smps_data_raw; xlsread(filename,sheet,'C3:BD43990')];
        elseif year==2018
            smps_data_raw=[smps_data_raw; xlsread(filename,sheet,'C3:BD44138')];
        elseif year==2019
            smps_data_raw=[smps_data_raw; xlsread(filename,sheet,'C3:BD44107')];
        end

        % Read integrated data
        sheet=2;
        if year==2016
            smps_tot_data=xlsread(filename,sheet,'B3:B43099');
        elseif year==2017
            smps_tot_data=[smps_tot_data; xlsread(filename,sheet,'B3:B43990')];
        elseif year==2018
            smps_tot_data=[smps_tot_data; xlsread(filename,sheet,'B3:B44138')];
        elseif year==2018
            smps_tot_data=[smps_tot_data; xlsread(filename,sheet,'B3:B44107')];
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

    clearvars -except read_OPC read_APS
    
end 

if read_OPC
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

    clearvars -except read_APS

end

if read_APS
    %% APS files
    
    % xlsread uses up al system memory and would probably take hours to
    % finish using code below... not sure why, since SMPS files (~20MB) work
    % just fine
    
    % export dataa and times manually
    % !! don't export totaldata, just recalculate it !!
    %    file might contain missing data (empty fields), and while the data
    %    csv file will contain empty fields, the single column total data
    %    will just contain line breaks, and dlmread skips those lines
    %
    %    total data is just the sum of the Dp bins for OPC and APS (no
    %    lognormal distribution)
    
    % Read partice diameters (bin mid-points)
    aps_Dp=dlmread('APS_Dp_midpoint.csv');
    
    aps_time=[];
    aps_data=[];
    aps_tot_data=[];
    
    for year=2019:2019
        
        filename=['APS_' num2str(year) '-03to' num2str(year) '-05'];

        % Read time axis
        fid = fopen([filename '_times.csv']);
        % Read all lines & collect in cell array
        txt = textscan(fid,'%s','delimiter','\n');
        aps_time=[aps_time;datetime(txt{1}, 'InputFormat', 'dd/MM/yyyy HH:mm')];
        fclose(fid);
        
        % Read size distribution data
        aps_data=[aps_data;dlmread([filename '_data.csv'])];

    end

    %calculate total data
    aps_tot_data=sum(aps_data,2);
    
    % remove missing data
    aps_data(aps_tot_data==0,:)=[];
    aps_time(aps_tot_data==0)=[];
    aps_tot_data(aps_tot_data==0)=[];
    
    % Save variables
    save aps_size_dist_all.mat aps_Dp aps_time aps_data aps_tot_data
    
    
%     error('xlsread cannot deal with a 30MB file...')
% 
%     for year=2019:2019
% 
%         filename=['APS_data_' num2str(year) '-03 to ' num2str(year) '-05.xlsx'];
% 
%         disp(['Processing ' filename]);
% 
%         sheet=1; 
% 
%         % Read partice diameters (bin mid-points)
%         range='D1:BB1';
%         aps_Dp = xlsread(filename,sheet,range);
%         aps_Dp=[0.523, aps_Dp]; % first entry is '< 0.523', xlsread would likely break
%         
%         % Read time axis
%         if year==2019
%             aps_time=xlsread(filename,sheet,'A3:A123194');
%         else
%             error(['Check data range for ' year])
%         end
% 
%         % Read size distribution data
%         if year==2019
%             aps_data=xlsread(filename,sheet,'C3:BB123194');
%         end
% 
%         % Read integrated data
%         sheet=2;
%         if year==2019
%             aps_tot_data=xlsread(filename,sheet,'B3:B123194');
%         end
% 
%     end
% 
%     % convert time to matlab datetime
%     aps_time=datetime(aps_time,'ConvertFrom','excel'); 
% 
%     % Save variables
%     save aps_size_dist_all.mat aps_Dp aps_time aps_data aps_tot_data
% 
%     clearvars

end

