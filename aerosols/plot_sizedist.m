%%% plot size distributions from Eureka SMPS, alongside ridge lab wind data 
%%% and PGBS BrO DSCDs

% load('/home/kristof/work/SMPS/size_dist_0317.mat')
load('/home/kristof/work/SMPS/size_dist.mat')
% load rl_wind.mat
% load('/home/kristof/work/GBS/PEARL-GBS/2016/MAX-DOAS/maxdoas_bro.mat')

% limit=1300;
limit=500;
ind=find(Dp_data>limit);
Dp_data(ind)=limit;

% contourf(Dp_data(2000:5000,:)')
% imagesc(Dp_data')

% convert time to ft, starting at 1 for Jan. 01, 00:00:00
[~,t]=fracdate(time);
% convert to days of March
t=t+1-60; %2016
% t=t+1-59; %2017

% surf(Dp_data','EdgeColor','None', 'facecolor', 'interp')
% xlim([1,size(Dp_data,1)])
% ylim([1,54])

% create numbered bins for plotting
Dpbin=[1:size(Dp,2)];

% redefine time interval (x/y limits don't scale color plot)
% % ind1=min(find(t>17));
% % ind2=max(find(t<23));
ind1=min(find(t>=19));
ind2=max(find(t<=23));
% ind1=min(find(t>=7));
% ind2=max(find(t<=21));
t=t(ind1:ind2);

figure(1)
% subplot(212);
surf(t,Dpbin,Dp_data(ind1:ind2,:)','EdgeColor','None', 'facecolor', 'interp'), hold on
% xlim([7,21.5])
xlim([19,23])
ylim([min(Dpbin),max(Dpbin)])
ylabel('D_p (nm)')
grid off

% replace tick labels with particle diameter corresponding to given index
% no point using Dp as y axis because bins are log spaced
% xx=[5:5:50];
xx=[1,10,23,33,42,54];
xxlabel=[10,20,50,100,200,500];
set(gca, 'YTick', xx)
set(gca, 'YTicklabel', xxlabel)
% set(gca, 'YTicklabel', Dp(xx))
% xlabel('Days of March, 2017 (UTC)')

% set view to see x-y plane from above
view(2)
colormap(jet(300))

c=colorbar();
ylabel(c,'dN/dlogD_p (cm^{-3})')




% % subplot(211)
% % % surf(t,Dpbin,Dp_data','EdgeColor','None', 'facecolor', 'interp')
% % surf(t,Dpbin,Dp_data(ind1:ind2,:)','EdgeColor','None', 'facecolor', 'interp')
% % xlim([min(t),max(t)])
% % ylim([min(Dpbin),max(Dpbin)])
% % ylabel('D_p (nm)')
% % 
% % % replace tick labels with particle diameter corresponding to given index
% % % no point using Dp as y axis because bins are log spaced
% % xx=[5:5:50];
% % set(gca, 'YTick', xx)
% % set(gca, 'YTicklabel', Dp(xx))
% % 
% % % set view to see x-y plane from above
% % view(2)
% % colormap(jet(300))
% % 
% % subplot(212)
% % 
% % % plot wind speed only
% % plot(fd_march,wind_speed.*1e14,'b-'), hold on
% % 
% % % plot BrO DSCDs 
% % day1 = 79; % min 66
% % day2 = 82; % max 132
% % 
% % indm1=find(dscd_S_m1.day >= day1 & dscd_S_m1.day <= day2);
% % ind0=find(dscd_S_0.day >= day1 & dscd_S_0.day <= day2);
% % ind1=find(dscd_S_1.day >= day1 & dscd_S_1.day <= day2);
% % ind2=find(dscd_S_2.day >= day1 & dscd_S_2.day <= day2);
% % ind5=find(dscd_S_5.day >= day1 & dscd_S_5.day <= day2);
% % ind10=find(dscd_S_10.day >= day1 & dscd_S_10.day <= day2);
% % ind15=find(dscd_S_15.day >= day1 & dscd_S_15.day <= day2);
% % ind30=find(dscd_S_30.day >= day1 & dscd_S_30.day <= day2);
% % 
% % msize=10;
% % 
% % % ax=subplot(2,1,1);
% % box on
% % hold on;
% % grid on
% % % ax.GridAlpha=0.4;
% % % grid minor
% % plot(dscd_S_m1.fd(indm1)-60,dscd_S_m1.mol_dscd(indm1),'r.','markersize', msize);
% % plot(dscd_S_0.fd(ind0)-60,dscd_S_0.mol_dscd(ind0),'g.','markersize', msize);
% % plot(dscd_S_1.fd(ind1)-60,dscd_S_1.mol_dscd(ind1),'b.','markersize', msize);
% % plot(dscd_S_2.fd(ind2)-60,dscd_S_2.mol_dscd(ind2),'y.','markersize', msize);
% % plot(dscd_S_5.fd(ind5)-60,dscd_S_5.mol_dscd(ind5),'m.','markersize', msize);
% % plot(dscd_S_10.fd(ind10)-60,dscd_S_10.mol_dscd(ind10),'c.','markersize', msize);
% % plot(dscd_S_15.fd(ind15)-60,dscd_S_15.mol_dscd(ind15),'k.','markersize', msize);
% % plot(dscd_S_30.fd(ind30)-60,dscd_S_30.mol_dscd(ind30),'ko','markersize', 3);
% % 
% % xlim([17,24])
% % 
% % xlabel('Days of March, 2016 (UTC)')
% % ylabel('BrO DSCDs + wind speed*10^14 (m/s)')
% % 
% % % figure(2)
% % % plot(log(Dp),Dp_data(2000,:),'ko')