% plot data from the PEARL weather station

year=2016;

load(['/home/kristof/work/weather_stations/ridge_lab/PWS_' num2str(year)]);

if year==2017
    sub=58;
elseif year==2016
    sub=59;
end

ft_wnd=ft_wnd-sub;

% smooth data with running average
wspd=boxcar(ft_wnd,wspd,20); % 20 datapoints is ~ 30 min
wdir=boxcar(ft_wnd,wdir*(pi/180),20,1)*(180/pi); % returns +- angles around 0

% get rid of directions that oscillate around +-180 (south)
for i=1:length(wdir)-1
    if wdir(i)<-90 && wdir(i+1)>90
        wdir(i)=NaN; 
    elseif wdir(i)>90 && wdir(i+1)<-90
        wdir(i)=NaN; 
    end
end

h=subplot(121);
set(h,'Position',[0.13 0.16 0.72 0.8]);


[hAx,l1,l2] = plotyy(ft_wnd,wspd,ft_wnd,wdir,'line');
set(hAx(1),'XGrid','on')
set(hAx(1),'YGrid','on')    

set(hAx(1),'Ytick',0:5:20)
set(hAx(2),'Ytick',-180:90:180)

% xlabel('Days of March, 2016 (UTC)')
if year==2017
    xlim(hAx(1),[7,21])
    xlim(hAx(2),[7,21])
elseif year==2016
    xlim(hAx(1),[19,23.18])
    xlim(hAx(2),[19,23.18])
end

l1.LineWidth=1.2;
l2.LineWidth=0.8;
%     l1.LineStyle = '--';
%     l2.LineStyle = '--';

ylabel(hAx(1),'Wind speed (m/s)') % left y-axis
ylim(hAx(1),[0,20]);
ylabel(hAx(2),'Wind direction (deg)') % right y-axis
ylim(hAx(2),[-180,180]);