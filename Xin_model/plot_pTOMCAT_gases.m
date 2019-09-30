function [ output_args ] = plot_pTOMCAT_gases( tg )
%PLOT_GASES Summary of this function goes here
%   Detailed explanation goes here

% if year==2016
%     %59 for leap years (2016), since data is already fractional day
%     subtract=59; 
% else
    subtract=58;
% end

% tg='O3';
tg='BrO';

load(['/home/kristof/work/models/p-TOMCAT/' tg '.mat'])
        
% index 13 is about 4km
alt_ind=13;

prof(1,1)=15;
        
h=surf(ft-subtract,h(1,1:alt_ind),prof(:,1:alt_ind)','EdgeColor','None', 'facecolor', 'interp'); hold on
view(2)

ylim([0.055,4])
xlim([7,21])

colormap(jet(300))
c=colorbar;
grid off

switch tg
    case 'BrO'
        xlabel(c,'Model BrO (pptv)')
    case 'O3'
        xlabel(c,'Model O_3 (ppbv)')
        xlabel('Days of March, 2017 (UTC)')
end

% xlabel(['Days of March, ' num2str(year) ' (UTC)'])
ylabel('Altitude (km)')


end

