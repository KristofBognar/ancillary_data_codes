%%%OBSOLETE, use read_EWS.m and read_PWS.m; plot_EWS.m and plot_PWS.m

% create plots from weather station data

% select station; Eureka: 1, Ridge Lab: 2, eureka radiosonde ptu : 3 or 4
option = 1;

% Eureka weather station data
if option==1
    % import file manually; leave out data quality and flag columns
    % data is in local time!
    
    % create fractional day data
    frac_day=[1:1/24:32-1/24]';        
    
    % find blowing snow
    indcell = strfind(Weather, 'Blowing Snow');
    ind_bs = find(not(cellfun('isempty', indcell)));

    % find snow
    indcell = strfind(Weather, 'Snow');
    ind_s = find(not(cellfun('isempty', indcell)));

    % find ice crystals
    indcell = strfind(Weather, 'Ice Crystals');
    ind_ic = find(not(cellfun('isempty', indcell)));
    
%     figure(1)
%     plot(frac_day, WindSpdkmh*0.277778, 'b.'), hold on
    
    % plot wind data
%     figure('Position', [100, 100, 1400, 700])
    
%     count=1;
%     for days=18:22
%         
%         subplot(2,3,count)
%         
%         % find indices of given days
%         ind=[];
%         for i=size(days,2)
%             ind=[ind; find(Day==days(i))];
%         end
%                 
%         % fix for inability to limit radius
%         t = 0:0.01:2*pi;
%         P = polar(t, 50 * ones(size(t))); hold on
%         set(P, 'Visible', 'off')
% 
%         % polar plot of wind
%         p1=polar(WindDir10sdeg(ind).*(10*pi/180), WindSpdkmh(ind), 'bo'); hold on
%         p2=polar(WindDir10sdeg(intersect(ind, ind_bs)).*(10*pi/180),...
%             WindSpdkmh(intersect(ind,ind_bs)), 'b+'); hold on
% 
%         view([90 -90])
% 
%         title_str=['March ',num2str(days)];
%         title(title_str)
%         
%         if count==2, legend([p1,p2],{'Wind direction (deg) and speed (km/h)',...
%                 'Blowing snow'},'Position',[0.682987980298815 0.226826373566508 0.23620932935994 0.0904684951694411]), end
%         
%         count=count+1;
%     end
    
    % plot wind speed and direction similar to RL plot
    avgdir=WindDir10sdeg.*10;
    
    figure()
    h=subplot(121);
 
    % plot in UTC
    x=frac_day+(5/24);
    y1=WindSpdkmh*0.277778; % convert to m/s
    y2=avgdir;
        
    ind=find(y2 >180);
    y2(ind)=y2(ind)-360;
%     ind1=find(y1>0 & y1<200);
    
    [hAx,l1,l2] = plotyy(x,y1,x,y2,'stairs'); hold on
    set(hAx(1),'XGrid','on')
    set(hAx(1),'YGrid','on')    
     
    xlabel('Days of March, 2017 (UTC)')
%     xlim(hAx(1),[77-60,83-60])
%     xlim(hAx(2),[77-60,83-60])
    xlim(hAx(1),[65-59,83-59])
    xlim(hAx(2),[65-59,83-59])

    l1.LineWidth=1.5;
    l2.LineWidth=1;
%     l1.LineStyle = '--';
%     l2.LineStyle = ':';
    
    ylabel(hAx(1),'Wind speed (m/s)') % left y-axis
    ylim(hAx(1),[0,20]);
    ylabel(hAx(2),'Wind direction (deg)') % right y-axis
    ylim(hAx(2),[-180,180]);
    
    set(h,'Position',[0.13 0.16 0.72 0.8]);

    % get proper time info
    [ft]=fracdate(DateTime,'yyyy-mm-dd HH:MM');
    sub=58; % for 2017
%     sub=59; % for 2016
    
    % plot just blowing snow/snow/ice crystas
    figure(1)
%     plot(frac_day(ind_bs),WindSpdkmh(ind_bs).*0.277778, 'kx')
%     xlim([7,23])

    plot(ft(ind_bs)-sub,ones(size(ft(ind_bs)))*0.037, 'ks','MarkerFaceColor','k')

%     plot(ft(ind_bs)-sub,ones(size(ft(ind_bs)))*0.01, 'kx')
%     plot(ft(ind_s)-sub,ones(size(ft(ind_s)))*0.1, 'ko')
%     plot(ft(ind_ic)-sub,ones(size(ft(ind_ic)))*0.05, 'k.','marker','diamond')

    
%     uicontrol('Style', 'text',...
%        'String', 'Wind speed (km/h)',... 
%        'Units','normalized',...
%        'Position', [0.7 0.2, 0.1, 0.1]);

    
%     plot(WindDir10sdeg(ind).*10, WindSpdkmh(ind), 'o'), hold on
%     plot(WindDir10sdeg(intersect(ind, ind_bs)).*10,...
%         WindSpdkmh(intersect(ind,ind_bs)), 'x')
%     xlim([0,370])
%     xlabel('Wind Direction')
%     ylabel('Wind Speed')

elseif option==2
    
    %% use new file: read_PWS
    
    % ridge lab weather station data from
    % deluge/projectsPEARL_FTS/Setra/Setra_2016
    % should be UTC, but check
    clear all

    header={'year', 'day_number', 'hour', 'fractional_day_number',...
        'air_temp', 'relative_humidity', 'wind_speed',...
        'wind_direction', 'pressure'};

    %read all available data into cell array, indexed by day of year
    %specific to given year!
    weather=cell(2,366);

    for i=1:366
       fname=['30_day',num2str(i),'.2016'];

       if exist(fname,'file')

           %read data
           fulldata=dlmread(fname,' ',1,0);

           % average hourly winds, save them in array as
           % [hour:windspeed:winddir:frac_day:p]
           avg=zeros(24,3);
           for j=0:23
               ind=find(fulldata(:,3)==j & fulldata(:,7)>0);

               avgwind=mean(fulldata(ind,7));
               %from circstat toolbox, needs radians, gives +- angle around 0
               avgdir=circ_mean(fulldata(ind,8)*(pi/180))*(180/pi);
               if avgdir<0, avgdir=360+avgdir; end
               avgfrac=mean(fulldata(ind,4));
               avgp=mean(fulldata(ind,9));

               avg(j+1,1)=j;
               avg(j+1,2)=avgwind;
               avg(j+1,3)=avgdir;
               avg(j+1,4)=avgfrac;
               avg(j+1,5)=avgp;
           end    

           %allocate results
           weather{1,i}=fulldata;
           weather{2,i}=avg;
       end
    end    

    % plot wind data
%     figure('Position', [100, 100, 1410, 1050])
%     count=1;
%     for days=78:82
%         
%         subplot(2,3,count)
%         
%         % fix for inability to limit radius
%         t = 0:0.01:2*pi;
%         P = polar(t, 50 * ones(size(t))); hold on
%         set(P, 'Visible', 'off')
% 
%         % polar plot of wind
%         p1=polar(weather{2,days}(:,3).*(pi/180),...
%                 weather{2,days}(:,2).*1.852, 'bo'); hold on
% 
%         view([90 -90])
% 
%         title_str=['March ',num2str(days-60)];
%         title(title_str)
%         
%         if count==2, legend([p1],{'Wind direction (deg) and speed (km/h)'},...
%                 'Position',[0.682987980298815 0.226826373566508 0.23620932935994 0.0904684951694411]), end
%         
%         count=count+1;
%     end    
%     
    figure('Position', [100, 100, 800, 600])
    h=subplot(121);
    x=[];
    y1=[];
    y2=[];
    
    ft=[];
    wspd=[];
    wdir=[];
    
    for i=75:84
        % plot in UTC
%         plot(weather{2,i}(:,4)+(5/24),weather{2,i}(:,2),'bo'), hold on
        x=[x; weather{2,i}(:,4)+(5/24)-60];
        y1=[y1; weather{2,i}(:,2)*0.514444];
        y2=[y2; weather{2,i}(:,3)];
        
        ft=[ft; weather{1,i}(:,4)+(5/24)-1]; % convert to fractional time in UTC
        wspd=[wspd; weather{1,i}(:,7)*0.514444]; % convert to m/s
        wdir=[wdir; weather{1,i}(:,8)];
    end

    % filter out bad values and keep March data only
    ind=find(wspd>0 & wspd<30 & ft>59 & ft<90);
    ft=ft(ind);
    wspd=wspd(ind);
    wdir=wdir(ind);    
    
    save PWS_03_2016.mat ft wspd wdir
    
    ind=find(y2 >180);
    y2(ind)=y2(ind)-360;
%     ind1=find(y1>0 & y1<200);

    [hAx,l1,l2] = plotyy(x,y1,x,y2,'stairs');
    set(hAx(1),'XGrid','on')
    set(hAx(1),'YGrid','on')    

    xlabel('Days of March, 2016 (UTC)')
    xlim(hAx(1),[77-60,83-60])
    xlim(hAx(2),[77-60,83-60])

    l1.LineWidth=1.5;
    l2.LineWidth=1;
%     l1.LineStyle = '--';
%     l2.LineStyle = ':';

    ylabel(hAx(1),'Wind speed (m/s)') % left y-axis
    ylim(hAx(1),[0,20]);
    ylabel(hAx(2),'Wind direction (deg)') % right y-axis
    ylim(hAx(2),[-50,150]);

    set(h,'Position',[0.13 0.16 0.72 0.8]);

    fd_march = x;
    wind_speed = y1;
    wind_dir = y2;
%     save rl_wind.mat fd_march wind_speed wind_dir

    % set font on plots
%     set(findall(gcf,'-property','FontSize'),'FontSize',24)
%     set(findall(gcf,'-property','FontName'),'FontName','Times New Roman') 
%     f=gcf; 
%     figpos=getpixelposition(f); 
%     resolution=get(0,'ScreenPixelsPerInch'); 
%     set(f,'paperunits','inches','papersize',figpos(3:4)/resolution,'paperposition',[0 0 figpos(3:4)/resolution]); 
%     path='/home/kristof/work/summer_school/poster/'; 
%     name='RL_wind'; 
%     print(f,fullfile(path,name),'-dpng','-r300','-opengl') %save file  

 elseif option==3
    clear all

    %read march radiosonde data, time is UTC
    header_ptu={'min','sec','P (hPa)','alt (gpm)','T (C)','RH (%)','DewP (C)'};
    header_wind={'min','sec','P (hPa)','alt (gpm)','m','speed (m/s)','dir (deg)'};
    sonde=cell(4,31);

    for i=10:31
        
        % ptu data
        ptupath='/home/kristof/work/weather_stations/Eureka/eu1602-04/Radiosonde ptu (2016 ACE campaign)/TU_removed/';
        fname1=[ptupath,'1603',num2str(i),'11.ptu.tsv'];
        fname2=[ptupath,'1603',num2str(i),'23.ptu.tsv'];
        if exist(fname1,'file')
            sonde{1,i}=importdata(fname1,' ',49);
        end
        if exist(fname2,'file')
            sonde{2,i}=importdata(fname2,' ',49);
        end

        % wind data
        windpath='/home/kristof/work/weather_stations/Eureka/eu1602-04/Radiosonde wind (2016 ACE campaign)/dfv_removed/';
        fname1=[windpath,'1603',num2str(i),'11.wnd.tsv'];
        fname2=[windpath,'1603',num2str(i),'23.wnd.tsv'];
        if exist(fname1,'file')
            sonde{3,i}=importdata(fname1,' ',49);
        end
        if exist(fname2,'file')
            sonde{4,i}=importdata(fname2,' ',49);
        end
        
    end
    
    % convert alt to km
    conv=1000;
    
    % plot relevat data
%     figure('Position', [100, 100, 1410, 1050])
    figure()
    count=1;
    C = ['r','m','g','b','y','c']; 
    for sp=1:6
        h=subplot(2,3,count);
                
        % create subplots
        if sp<3
            % add days around BEE
            for days=17:19
                p1=plot(sonde{1,days}.data(:,sp+4),sonde{1,days}.data(:,4)./conv,...
                    'color',C(days-16),'linewidth',1.5); hold on
                p2=plot(sonde{2,days}.data(:,sp+4),sonde{2,days}.data(:,4)./conv,...
                    'color',C(days-13),'linewidth',1.5); hold on
            end
            % add ozonesonde days (only pm radiosondes)
            % mar 14 23pm file buggy, use mar 14 11 am
            p1=plot(sonde{1,14}.data(:,sp+4),sonde{1,14}.data(:,4)./conv,...
                'color',C(1),'linewidth',1.5,'linestyle',':'); hold on
            p2=plot(sonde{2,16}.data(:,sp+4),sonde{2,16}.data(:,4)./conv,...
                'color',C(4),'linewidth',1.5,'linestyle',':'); hold on

         elseif sp>=4 && sp<6
            % BEE days
            for days=20:22
                p1=plot(sonde{1,days}.data(:,sp+1),sonde{1,days}.data(:,4)./conv,...
                    'color',C(days-19),'linewidth',1.5); hold on
                p2=plot(sonde{2,days}.data(:,sp+1),sonde{2,days}.data(:,4)./conv,...
                    'color',C(days-16),'linewidth',1.5); hold on
            end
            % ozonesonde days
            p1=plot(sonde{2,23}.data(:,sp+1),sonde{2,23}.data(:,4)./conv,...
                'color',C(1),'linewidth',1.5,'linestyle',':'); hold on
            p2=plot(sonde{2,30}.data(:,sp+1),sonde{2,30}.data(:,4)./conv,...
                'color',C(4),'linewidth',1.5,'linestyle',':'); hold on

        elseif sp==3
            % ozonesonde days
            p1=plot(sonde{3,14}.data(:,6),sonde{3,14}.data(:,4)./conv,...
                'color',C(1),'linewidth',1.5,'linestyle',':'); hold on
            p2=plot(sonde{4,16}.data(:,6),sonde{4,16}.data(:,4)./conv,...
                'color',C(4),'linewidth',1.5,'linestyle',':'); hold on
            % BEE days
            for days=17:19
                p1=plot(sonde{3,days}.data(:,6),sonde{3,days}.data(:,4)./conv,...
                    'color',C(days-16),'linewidth',1.5); hold on
                p2=plot(sonde{4,days}.data(:,6),sonde{4,days}.data(:,4)./conv,...
                    'color',C(days-13),'linewidth',1.5); hold on
            end
        elseif sp==6
            % BEE days
            for days=20:22
                p1=plot(sonde{3,days}.data(:,6),sonde{3,days}.data(:,4)./conv,...
                    'color',C(days-19),'linewidth',1.5); hold on
                p2=plot(sonde{4,days}.data(:,6),sonde{4,days}.data(:,4)./conv,...
                    'color',C(days-16),'linewidth',1.5); hold on
            end
            % ozonesonde days
            p1=plot(sonde{4,23}.data(:,6),sonde{4,23}.data(:,4)./conv,...
                'color',C(1),'linewidth',1.5,'linestyle',':'); hold on
            p2=plot(sonde{4,30}.data(:,6),sonde{4,30}.data(:,4)./conv,...
                'color',C(4),'linewidth',1.5,'linestyle',':'); hold on
            
        end
        
        % arrange plots manually so legend fits on the right
        limx=2;
        tlimx=limx*0.85;
        
        if sp==1
            set(h,'Position',[0.08 0.57 0.2 0.35]); 
            title('a','position',[-13,tlimx])
            ylabel('Altitude (km)')
            xlim([-40,-10])
        elseif sp==2
            set(h,'Position',[0.33 0.57 0.2 0.35]); 
            title('b','position',[92,tlimx])
            xlim([20,100])            
        elseif sp==3
            legend('03/14, 11:00','03/16, 23:00','03/17, 11:00',...
                '03/17, 23:00','03/18, 11:00',...
                '03/18, 23:00','03/19, 11:00','03/19, 23:00',...
                'location','eastoutside') 
            set(h,'Position',[0.58 0.57 0.2 0.35]);
            title('c','position',[18,tlimx])
            xlim([0,20])
        elseif sp==4
            set(h,'Position',[0.08 0.11 0.2 0.35]); 
            title('d','position',[-13,tlimx])
            ylabel('Altitude (km)')
            xlabel('Temperature (\circ C)')
            xlim([-40,-10])
        elseif sp==5
            set(h,'Position',[0.33 0.11 0.2 0.35]); 
            title('e','position',[92,tlimx])
            xlabel('Relative humidity (%)')
            xlim([20,100])
        elseif sp==6,
            legend('03/20, 11:00','03/20, 23:00','03/21, 11:00',...
                '03/21, 23:00','03/22, 11:00','03/22, 23:00',...
                '03/23, 23:00','03/30, 23:00','location','eastoutside')
            set(h,'Position',[0.58 0.11 0.2 0.35]); 
            title('f','position',[18,tlimx])
            xlabel('Windspeed (m/s)')
            xlim([0,20])
        end
        ylim([0,2])
        grid on
        h.GridAlpha=0.4;
        grid minor
        count=count+1;
        
        
    end
    
    figure(999)

    ls={'-','-.',':'};
    for i=1:3
        subplot(121)
        % 11UT T data
        plot(sonde{1,18+i}.data(:,5),sonde{1,18+i}.data(:,4),'color',C(i),'linewidth',2,'linestyle',ls{i}), hold on
        % 23UT T data
        plot(sonde{2,18+i}.data(:,5),sonde{2,18+i}.data(:,4),'color',C(i+3),'linewidth',2,'linestyle',ls{i}), hold on
        subplot(122)
        % 11UT windspeed
        plot(sonde{3,18+i}.data(:,6),sonde{3,18+i}.data(:,4),'color',C(i),'linewidth',2,'linestyle',ls{i}), hold on
        % 23UT windspeed
        plot(sonde{4,18+i}.data(:,6),sonde{4,18+i}.data(:,4),'color',C(i+3),'linewidth',2,'linestyle',ls{i}), hold on

    end
    ylim([0,2000])
    xlabel('Wind speed (m/s)')
    subplot(121)
    legend('03/19 11:00','03/19 23:00','03/20 11:00','03/20 23:00','03/21 11:00','03/21 23:00','location','northwest')
    ylim([0,2000])
    xlabel('Temperature (\circC)')
    ylabel('Altitude (m)')    
    
    % set font on plots
%     set(findall(gcf,'-property','FontSize'),'FontSize',18)
%     set(findall(gcf,'-property','FontName'),'FontName','Times New Roman') 
    
%     f=gcf; 
%     figpos=getpixelposition(f); 
%     resolution=get(0,'ScreenPixelsPerInch'); 
%     set(f,'paperunits','inches','papersize',figpos(3:4)/resolution,'paperposition',[0 0 figpos(3:4)/resolution]); 
%     path='/home/kristof/work/summer_school/poster/'; 
%     name='T_RH_wind'; 
%     print(f,fullfile(path,name),'-dpng','-r300','-opengl') %save file

    
%     for days=16:24
%         subplot(3,3,count)
%         p1=plot(sonde{1,days}.data(:,6),sonde{1,days}.data(:,4),'r-',...
%             'linewidth',1.5); hold on
%         p2=plot(sonde{2,days}.data(:,6),sonde{2,days}.data(:,4),'b-',...
%             'linewidth',1.5); hold on
% %         xlim([-40,-10]);
%         xlim([40,100]);
%         ylim([0,500]);
%         title_str=['March ',num2str(days)];
%         title(title_str)
%         if count==4, ylabel('Height (m)'), end
% %         if count==8, xlabel('Temperature (\circ C)'), end
%         legend([p1,p2],{'11 UTC','23 UTC'},'location','best');
% %         if count==2, legend([p1,p2],{'11 UTC','23 UTC'},...
% %                 'Position',[0.682987980298815 0.226826373566508 0.23620932935994 0.0904684951694411]), end
%         count=count+1;
%     end    

 elseif option==4
    clear all

    %read march radiosonde data, time is UTC
    header_ptu={'min','sec','P (hPa)','alt (gpm)','T (C)','RH (%)','DewP (C)'};
    header_wind={'min','sec','P (hPa)','alt (gpm)','m','speed (m/s)','dir (deg)'};
    sonde=cell(4,31);

    for i=10:31
        
        % ptu data
        ptupath='/home/kristof/work/weather_stations/Eureka/eu1602-04/Radiosonde ptu (2016 ACE campaign)/TU_removed/';
        fname1=[ptupath,'1603',num2str(i),'11.ptu.tsv'];
        fname2=[ptupath,'1603',num2str(i),'23.ptu.tsv'];
        if exist(fname1,'file')
            sonde{1,i}=importdata(fname1,' ',49);
        end
        if exist(fname2,'file')
            sonde{2,i}=importdata(fname2,' ',49);
        end

        % wind data
        windpath='/home/kristof/work/weather_stations/Eureka/eu1602-04/Radiosonde wind (2016 ACE campaign)/dfv_removed/';
        fname1=[windpath,'1603',num2str(i),'11.wnd.tsv'];
        fname2=[windpath,'1603',num2str(i),'23.wnd.tsv'];
        if exist(fname1,'file')
            sonde{3,i}=importdata(fname1,' ',49);
        end
        if exist(fname2,'file')
            sonde{4,i}=importdata(fname2,' ',49);
        end
        
    end
    
    % convert alt to km
    conv=1000;
    
    % plot relevat data
%     figure('Position', [100, 100, 1410, 1050])
    figure()
    count=1;
    C = ['r','b','g','y','y','c']; 
    
    figure(1)

    %% T days 1-2
    h=subplot(221);
    days=19;
    plot(sonde{1,days}.data(:,5),sonde{1,days}.data(:,4)./conv,...
         'color',C(1),'linewidth',1.5); hold on
    plot(sonde{2,days}.data(:,5),sonde{2,days}.data(:,4)./conv,...
         'color',C(2),'linewidth',1.5); hold on
    days=20;
    plot(sonde{1,days}.data(:,5),sonde{1,days}.data(:,4)./conv,...
         'color',C(3),'linewidth',1.5); hold on
    plot(sonde{2,days}.data(:,5),sonde{2,days}.data(:,4)./conv,...
         'color',C(4),'linewidth',1.5); hold on
    legend('03/19 11am', '03/19 23am', '03/20 11am', '03/20 23am',...
        'location','northwest')
    ylabel('Altitude (km)')
    ylim([0,2])
    xlim([-40,-10])
    
    set(h,'Position',[0.13 0.56 0.36 0.37]);
    grid on
    h.GridAlpha=0.4;
%     grid minor

    
    %% T days 3-4
    h=subplot(223);
    days=21;
    plot(sonde{1,days}.data(:,5),sonde{1,days}.data(:,4)./conv,...
         'color',C(1),'linewidth',1.5); hold on
    plot(sonde{2,days}.data(:,5),sonde{2,days}.data(:,4)./conv,...
         'color',C(2),'linewidth',1.5); hold on
    days=22;
    plot(sonde{1,days}.data(:,5),sonde{1,days}.data(:,4)./conv,...
         'color',C(3),'linewidth',1.5); hold on
    plot(sonde{2,days}.data(:,5),sonde{2,days}.data(:,4)./conv,...
         'color',C(4),'linewidth',1.5); hold on
    legend('03/21 11am', '03/21 23am', '03/22 11am', '03/22 23am',...
        'location','northwest')

    ylabel('Altitude (km)')
    xlabel('Temperature (\circ C)')
    ylim([0,2])
    xlim([-40,-10])
    
    set(h,'Position',[0.13 0.11 0.36 0.37]);
    grid on
    h.GridAlpha=0.4;
%     grid minor

    
    %% wind days 1-2
    h=subplot(222);
    days=19;
    plot(sonde{3,days}.data(:,6),sonde{1,days}.data(:,4)./conv,...
         'color',C(1),'linewidth',1.5); hold on
    plot(sonde{4,days}.data(:,6),sonde{2,days}.data(:,4)./conv,...
         'color',C(2),'linewidth',1.5); hold on
    days=20;
    plot(sonde{3,days}.data(:,6),sonde{1,days}.data(:,4)./conv,...
         'color',C(3),'linewidth',1.5); hold on
    plot(sonde{4,days}.data(:,6),sonde{2,days}.data(:,4)./conv,...
         'color',C(4),'linewidth',1.5); hold on
    ylim([0,2])
    xlim([0,20])
    
    set(h,'Position',[0.54 0.56 0.36 0.37]);
    grid on
    h.GridAlpha=0.4;
%     grid minor

    
    %% wind days 3-4
    h=subplot(224);
    days=21;
    plot(sonde{3,days}.data(:,6),sonde{1,days}.data(:,4)./conv,...
         'color',C(1),'linewidth',1.5); hold on
    plot(sonde{4,days}.data(:,6),sonde{2,days}.data(:,4)./conv,...
         'color',C(2),'linewidth',1.5); hold on
    days=22;
    plot(sonde{3,days}.data(:,6),sonde{1,days}.data(:,4)./conv,...
         'color',C(3),'linewidth',1.5); hold on
    plot(sonde{4,days}.data(:,6),sonde{2,days}.data(:,4)./conv,...
         'color',C(4),'linewidth',1.5); hold on
    xlabel('Windspeed (m/s)')
    ylim([0,2])
    xlim([0,20])
    
    set(h,'Position',[0.54 0.11 0.36 0.37]);

    grid on
    h.GridAlpha=0.4;
%     grid minor

    for sp=1:6
       
        
%         % arrange plots manually so legend fits on the right
%         limx=2;
%         tlimx=limx*0.85;
%         
%         if sp==1
%             set(h,'Position',[0.08 0.57 0.2 0.35]); 
%             title('a','position',[-13,tlimx])
%             ylabel('Altitude (km)')
%             xlim([-40,-10])
%         elseif sp==2
%             set(h,'Position',[0.33 0.57 0.2 0.35]); 
%             title('b','position',[92,tlimx])
%             xlim([20,100])            
%         elseif sp==3
%             legend('03/14, 11:00','03/16, 23:00','03/17, 11:00',...
%                 '03/17, 23:00','03/18, 11:00',...
%                 '03/18, 23:00','03/19, 11:00','03/19, 23:00',...
%                 'location','eastoutside') 
%             set(h,'Position',[0.58 0.57 0.2 0.35]);
%             title('c','position',[18,tlimx])
%             xlim([0,20])
%         elseif sp==4
%             set(h,'Position',[0.08 0.11 0.2 0.35]); 
%             title('d','position',[-13,tlimx])
%             ylabel('Altitude (km)')
%             xlabel('Temperature (\circ C)')
%             xlim([-40,-10])
%         elseif sp==5
%             set(h,'Position',[0.33 0.11 0.2 0.35]); 
%             title('e','position',[92,tlimx])
%             xlabel('Relative humidity (%)')
%             xlim([20,100])
%         elseif sp==6,
%             legend('03/20, 11:00','03/20, 23:00','03/21, 11:00',...
%                 '03/21, 23:00','03/22, 11:00','03/22, 23:00',...
%                 '03/23, 23:00','03/30, 23:00','location','eastoutside')
%             set(h,'Position',[0.58 0.11 0.2 0.35]); 
%             title('f','position',[18,tlimx])
%             xlabel('Windspeed (m/s)')
%             xlim([0,20])
%         end
%         ylim([0,2])
%         grid on
%         h.GridAlpha=0.4;
%         grid minor
%         count=count+1;
        
        
    end
    
%     figure(999)
% 
%     ls={'-','-.',':'};
%     for i=1:3
%         subplot(121)
%         % 11UT T data
%         plot(sonde{1,18+i}.data(:,5),sonde{1,18+i}.data(:,4),'color',C(i),'linewidth',2,'linestyle',ls{i}), hold on
%         % 23UT T data
%         plot(sonde{2,18+i}.data(:,5),sonde{2,18+i}.data(:,4),'color',C(i+3),'linewidth',2,'linestyle',ls{i}), hold on
%         subplot(122)
%         % 11UT windspeed
%         plot(sonde{3,18+i}.data(:,6),sonde{3,18+i}.data(:,4),'color',C(i),'linewidth',2,'linestyle',ls{i}), hold on
%         % 23UT windspeed
%         plot(sonde{4,18+i}.data(:,6),sonde{4,18+i}.data(:,4),'color',C(i+3),'linewidth',2,'linestyle',ls{i}), hold on
% 
%     end
%     ylim([0,2000])
%     xlabel('Wind speed (m/s)')
%     subplot(121)
%     legend('03/19 11:00','03/19 23:00','03/20 11:00','03/20 23:00','03/21 11:00','03/21 23:00','location','northwest')
%     ylim([0,2000])
%     xlabel('Temperature (\circC)')
%     ylabel('Altitude (m)')    
    
end
