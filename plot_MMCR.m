
% data in fractional time
% to get days of March:
% corr=59; % for leap years (2016)
corr=58; % otherwise

%%% to produce plots from PACES/EGU posters: run this code for given year,
%%% then run plot_profiles all with the countour lines (make sure lines to 
%%% add zeros are uncommented), then run plot weather to add extra weather
%%% info

figure(1)
% subplot(212)
% ind1=find(mode==0);
% ind1=find(~isnan(height(end,:)));
ind1=find(isnan(height(141,:)));

% ind2=find(ft>=79 & ft<80);
% ind2=find(ft>=78 & ft<82);

% ind=sort(intersect(ind1,ind2));

% 2017
ind2=find(ft>=65 & ft<79);
ind=ind2;
height(:,184289:184290)=NaN(size(height(:,184289:184290)));

ind3=find(ref>20);
ref(ind3)=NaN;

height=height(:,ind);
ft=ft(ind);
ref=ref(:,ind);

% plot only every nth profile
plotind=2:2:length(ft);

%surf(ft(ind)-corr,height(:,ind)./1000,ref(:,ind),'EdgeColor','None', 'facecolor', 'flat'), hold on
surf(ft(plotind)-corr,height(:,plotind)./1000,ref(:,plotind),'EdgeColor','None', 'facecolor', 'flat'), hold on
c=colorbar();
ylim([0,4])
xlim([7,21])
% xlim([19,23])
grid off

% xlabel('Days of March, 2017 (UTC)')
ylabel('Altitude (km)')
ylabel(c,'Reflectivity (dBz)')

view(2)
colormap(jet(300))


