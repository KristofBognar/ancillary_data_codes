
%% control variables
read_backrun=0;

time_lim=3;

plot_traj=1;
plot_sens=1;

% 1: subplot with worldmap, 0: sinle plots with axesm(globe)
plot_subplot=1; 

% number of plots/subplots
num_plots=3;

% subplot layout
plotrow=1;
plotcol=3;

load coast;

wdir_key={'Wind: \bf{N}','Wind: \bf{SE}','Wind: \bf{other}'};

flex_dir='/home/kristof/atmosp_servers/export/data/home/kbognar/FLEXPART_10.02/';
flex_folder='BrO_back_runs_v1';
    
cur_dir=pwd();
cd([flex_dir flex_folder]);

if ~read_backrun

    % load data
    load('/home/kristof/work/BEEs/BEE_dataset_flexpart.mat')
    load([flex_folder '_' num2str(time_lim) 'day.mat']);
    
    
    %% plotting indices (use logical so dimensions are always the same)
    p1=(bee_fp.wdir==1 & bee_fp.bro_m==2); % N winds and above average BrO cols
    p2=(bee_fp.wdir==2 & bee_fp.bro_m==2); % SE winds and above average BrO cols
    p3=(bee_fp.wdir==3 & bee_fp.bro_m==2); % other winds and above average BrO cols
    p4=(bee_fp.dT==1); % strong/weak T inversion
    %p4=(bee_fp.ssa_m==2 & bee_fp.bro_m==2); % all winds and above average supermicron aer
    %p4=(bee_fp.bro_m==1); % all winds and below average BrO cols

%     p1=(bee_fp.o3==1); % o3 < 5 (ppb)
%     p2=(bee_fp.o3==2); % 5 <= o3 < 10 
%     p3=(bee_fp.o3==3); % 10 <= o3 < 20 
%     p4=(bee_fp.o3==4); % 20 <= o3 
    
    

    
    plot_ind=[p1,p2,p3,p4];
             
             
    %% plot results   
    
    if plot_subplot
        
        figure
        for i=1:num_plots
            subplot(plotrow,plotcol,i)
            ax = worldmap([61,90], [-180,180]);
            geoshow(ax, lat, long,'DisplayType', 'polygon', 'FaceColor', [0.7,0.7,0.7])
            hold on
            title(wdir_key{i},'fontweight','normal','FontSize',19)
        end
    
        set(gcf, 'Position', [100, 100, 1200, 330]);
        
    else
    
        for i=1:num_plots
            figure(i)
            hold on
            ax=axesm('MapProjection','globe');
            axis off
            gridm on
            framem on

            % mlabel on
            plabel on;
            setm(gca,'MLabelParallel',50)
            % setm(gca,'PLabelMeridian',180)
            % setm(gca,'MLabelParallel',0)

            for i=1:36
                geoshow(ax, [0,90,0,0], [10*i,10*i,10*i-10,10*i],'DisplayType','polygon',...
                        'facecolor','w', 'edgecolor','w')
            end

            geoshow(ax, lat, long,'DisplayType', 'polygon', 'FaceColor', [0.7,0.7,0.7])

            view(4,82)
            zoom(2.9)  
            
            set(gcf, 'Position', [100, 100, 320, 300]);
            
        end

    end
    
    if plot_sens
        
        sensitivities(sensitivities==0)=NaN;

        for i=1:num_plots % results in inds have to be 1-4, other indices excluded from average
           
%             inds_tmp=inds;
%             inds_tmp(inds_tmp==0)=3;
%             sens_tmp=nanmean(sensitivities(:,:,inds_tmp==i),3);
            
            if plot_subplot
                subplot(plotrow,plotcol,i)
            else
                figure(i)
            end
            
            sens_tmp=nanmean(sensitivities(:,:,plot_ind(:,i)),3);
            
            sens_tmp(sens_tmp<0.1)=0.1;

            % plot on log scale
            sens_tmp=log10(sens_tmp);
            % replace max log value with next largest integer if difference is <0.3
            [max_val,max_ind] = max(sens_tmp(:));
            if max_val-floor(max_val) >0.7
                sens_tmp(max_ind)=ceil(max_val);
                max_val=ceil(max_val);
            end

            % plot sensitivity
            surfm(latitude,longitude,sens_tmp,'facecolor', 'interp','facealpha',0.75);
            colormap(flipud(hot))

            if plot_subplot && i==num_plots
                % add colorbar with manual labels (convert back to lin space)
                cb=colorbar('position',[0.873,0.29,0.026,0.47]);
                cb_lim=-1:ceil(max_val);
                set(cb,'YTick',cb_lim)
                set(cb,'YTick',cb_lim,'YTickLabel',cellstr(num2str(power(10,cb_lim)')))
                ylabel(cb,'Mean surf. sens. (s)','FontSize',12)
            end
            
            setm(gca,'MLineLocation',30,'PLineLocation',10,'MLabelLocation',90,...
                 'PLabelLocation',10,'MLabelParallel',65,'PLabelMeridian',0,...
                 'FontSize',10)
            
            if plot_traj
                
                to_plot=find(plot_ind(:,i)==1);
                
                for j=to_plot'
                    data=trajectories(trajectories.index==j,:);
                    plotm(data.lat,data.lon,'c','linewidth',0.6)
                end
                
            end
            
        end
        
    end
    
%     if plot_traj
%         for i=1:max(trajectories.index)
% 
%  
%             subplot(2,2,plot_ind)
% 
%             data=trajectories(trajectories.index==i,:);
%             plotm(data.lat,data.lon,'c','linewidth',0.6)
% 
%         end
%     end
    
    for i=1:num_plots
        if plot_subplot
            subplot(plotrow,plotcol,i)
        else
            figure(i)
        end
        plotm(80.053, -86.416, 'kp','markerfacecolor','k','markersize',12)
    end
    
    
    
else

    save_flexpart();
    
end

cd(cur_dir)

% load coast;
% % plot map
% % ax = worldmap([70,90], [-146.4,-26.4]);
% ax = worldmap([60,90], [-180,180]);
% geoshow(ax, lat, long,'DisplayType', 'polygon', 'FaceColor', [0.7,0.7,0.7]); hold on
% 
% 
% for i=1:5
%     
%     data=trajectories.(['traj_' datestr(run_times(i),'yyyymmdd_HHMMSS')]);
%     
%     plotm(data.lat,data.lon,'k-','linewidth',2)
%     
% end



% % figure, hold on
% % 
% % % get rid of empty frid cells and tiny values (for plotting)
% % tracer_plot(tracer_plot==0)=NaN;
% % tracer_plot(tracer_plot<0.1)=0.1;
% % 
% % % plot on log scale
% % tracer_plot=log10(tracer_plot);
% % % replace max log value with next largest integer if difference is <0.3
% % [max_val,max_ind] = max(tracer_plot(:));
% % if max_val-floor(max_val) >0.7
% %     tracer_plot(max_ind)=ceil(max_val);
% %     max_val=ceil(max_val);
% % end
% % 
% % % plot map
% % % ax = worldmap([70,90], [-146.4,-26.4]);
% % ax = worldmap([60,90], [-180,180]);
% % geoshow(ax, lat, long,'DisplayType', 'polygon', 'FaceColor', [0.7,0.7,0.7]);
% % 
% % % plot sensitivity
% % surfm(latitude,longitude,tracer_plot,'facecolor', 'interp','facealpha',0.8);
% % colormap(flipud(hot))
% % cb = colorbar();
% % 
% % % add colorbar with manual labels (convert back to lin space)
% % cb_lim=-1:ceil(max_val);
% % set(cb,'YTick',cb_lim)
% % set(cb,'YTick',cb_lim,'YTickLabel',cellstr(num2str(power(10,cb_lim)')))
% % 
% % % altitude is for the plume centroid: if there's no mixing, alt will stay
% % % around 1km, since release is from 0-2km
% % figure
% % plot(trajectories.time*-1,trajectories.alt,'k-'), hold on
% % plot(trajectories.time*-1,trajectories.alt+trajectories.zrms_dist,'k--')
% % plot(trajectories.time*-1,trajectories.alt-trajectories.zrms_dist,'k--')
% % plot(trajectories.time*-1,trajectories.topography,'r-'), hold on
% % plot(trajectories.time*-1,trajectories.topography+trajectories.mixing_height,'r--'), hold on
