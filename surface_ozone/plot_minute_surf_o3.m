% plot surface ozone data from Eureka (one minute resolution)

cd /home/kristof/work/surface_ozone;

%% read files?
% if true, code will download all data for selected year and create .mat file 
download_files=true;

% merge yearly files?
merge_files=true;

% plot yearly file?
plot_yearly=true;

year='2018';

x_date=0;


varname=['surf_o3_minute_' year '.mat'];

%%
if download_files
    %% read files
    
    if str2double(year)>2018, error('Get minute resolution foles first'), end
    
    cd(['./minute_data/' year '/'])
    
    % download files from NOAA FTP
%     system('./get_surf_o3');
    
    % final variables
    o3_ft=[];
    o3_ppb=[];

    % make list of all files
    tmp = dir('*.txt'); 
    f_list = {tmp.name}; % cell array of file names

    n=0;
    for i=1:length(f_list)

        % display progress info
        disp_str=['Reading file ', num2str(i), '/', num2str(size(f_list,2))];
        % stuff to delete last line and reprint updated message
        fprintf(repmat('\b',1,n));
        fprintf(disp_str);
        n=numel(disp_str);    

        % read given file
        [t_tmp,o3_tmp]=read_minute_surf_o3(f_list{i});

        % convert time to fractional date
        t_tmp2=zeros(size(t_tmp));
        for j=1:length(t_tmp)
            [t_tmp2(j)]=fracdate(t_tmp{j}, 'HH:MM mm-dd-yy');
        end

        % store results
        o3_ft=[o3_ft;t_tmp2];
        o3_ppb=[o3_ppb;o3_tmp];

    end
    fprintf('\n');
    
    % save variables
    cd('../../')
    save(varname,'o3_ft','o3_ppb');
    
elseif plot_yearly
    %% load variables and plot
    
    load(varname)
    
    % time in file is fractional time (jan 1, 00:00 = 0)

    % plotting limits (enter day number in brackets)
    limits=[60,155]-1;
    
    o3_ppb(o3_ft<limits(1) | o3_ft>limits(2))=[];
    o3_ft(o3_ft<limits(1) | o3_ft>limits(2))=[];
    
    figure(99)
    ax_o3=subplot(311);
    if x_date

        plot(yeartime(str2num(year))+o3_ft,o3_ppb,'b.')
        xlim(yeartime(str2num(year))+limits);
        datetick('x','mmmdd','keeplimits')

    else
        
        plot(o3_ft,o3_ppb,'b.')
        xlim(limits)

    end

    grid on
%     grid minor
    
%     xlabel('Days of March, 2017 (UTC)')
    ylabel ('Ozone conc. (ppbv)')
    ylim([-1,50])
    
    
end

if merge_files
    
    load('surf_o3_minute_2017.mat');
    
    o3_ft_all=o3_ft;
    o3_ppb_all=o3_ppb;
    
    time=ft_to_date(o3_ft,2017);
    
    year=ones(size(o3_ft))*2017;
    
    load('surf_o3_minute_2018.mat');
    
    o3_ft_all=[o3_ft_all; o3_ft];
    o3_ppb_all=[o3_ppb_all; o3_ppb];
    
    time=[time;ft_to_date(o3_ft,2018)];
    
    year=[year;ones(size(o3_ft))*2018];
    
    surf_o3_minute=table();
    surf_o3_minute.DateTime=time;
    surf_o3_minute.year=year;
    surf_o3_minute.ft=o3_ft_all;
    surf_o3_minute.o3_ppb=o3_ppb_all;
    
    save surf_o3_minute_all.mat surf_o3_minute
    
end

