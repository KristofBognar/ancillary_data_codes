

plot_data=1;

% check for water in the entire tile, or exclude nothert Baffin bay (often ice free)
all_tile=0;

% load('/home/kristof/work/BEEs/sea_ice_data/MODIS_Eureka_all.mat')
load('/home/kristof/atmosp_servers/net/corona/satellite/modis/MODIS_Eureka2015.mat')

% create new mask
plot_SI=NaN(size(sea_ice));

% night
plot_SI(sea_ice==11)=0.5;

% land + inland water
plot_SI(sea_ice==25)=1.5;
plot_SI(sea_ice==253)=1.5;
plot_SI(sea_ice==37)=1.5;

% water
plot_SI(sea_ice==39)=2.5;
plot_SI(sea_ice==254)=2.5;

% clouds
plot_SI(sea_ice==50)=3.5;

% sea ice
plot_SI(sea_ice==200)=4.5;


% find open ocean
for i=1:size(sea_ice,3)
    if all_tile
        tmp(i)=sum(sum(plot_SI(:,:,i)==2.5));
    else
        tmp(i)=sum(sum(plot_SI(1:700,:,i)==2.5));
    end
end

% plot(1:62,tmp,'b-')

ind_check=find(tmp>100);


% plot data
if plot_data

    % define five element color scale
    cmap =[0 0 0
           0.5 0.5 0.5
           0 0 1
           0.5 1 1
           1 1 0];

    % plot
    for i=1:size(sea_ice,3)

        if ~any(i==ind_check), continue, end

        % lame scaling
        plot_SI(951,1,i)=5;
        plot_SI(950,1,i)=0;

        % plot surface with custom colorbar
        surf(flipud(plot_SI(:,:,i)),'EdgeColor','None', 'facecolor', 'flat')
        cb=colorbar();
        colormap(cmap)
        view(2)

        cb.Ticks = 0.5:4.5;
        cb.TickLabels = {'Night','Land','Water','Clouds','Sea Ice'};

        title([ 'MODIS/' sat_id{i} ', day ' num2str(doy(i)) ', ' num2str(year(i)) ])

        xlim([0,951])
        ylim([0,951])    

        % pause loop until figure is clicked on
        try
            tmp=1;
            while tmp % loop so key presses (return 1) are not accepted
                tmp=waitforbuttonpress;
            end
        catch
            % returns error if figure is closed, exit when that happens
            return
        end
    end
end