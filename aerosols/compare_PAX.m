% compare pax data to BrO partial columns
% thrown together to get some quick look plots

if ~exist('dmean_bro','var')
    % load data
    load('/home/kristof/work/SMPS/PAX_BC.mat')
    load('/home/kristof/work/BEEs/BEE_dataset_all.mat')
    bee_dataset(bee_dataset.times.Year==2015,:)=[];

    %% get daily mean values
    %%% BrO
    unique_days=unique(...
        [bee_dataset.times.Year,bee_dataset.times.Month,bee_dataset.times.Day],'rows');

    dmean_bro=NaN(size(unique_days,1),4);

    % loop over unique days
    for i=1:size(unique_days,1)

        tmp=bee_dataset.bro_col( bee_dataset.times.Year==unique_days(i,1) & ...
                                 bee_dataset.times.Month==unique_days(i,2) & ...
                                 bee_dataset.times.Day==unique_days(i,3)          );

        dmean_bro(i,1)=mean(tmp);
        dmean_bro(i,2)=std(tmp);
        dmean_bro(i,3)=min(tmp);
        dmean_bro(i,4)=max(tmp);

    end

    % save results in a table
    dmean_bro=array2table(dmean_bro,'variablenames',{'mean','std','min','max'}); 
    dmean_bro.DateTime=datetime(unique_days)+hours(12);

    %%% PAX 405
    % find unique days
    unique_days=unique(...
        [pax405.DateTime.Year,pax405.DateTime.Month,pax405.DateTime.Day],'rows');

    dmean_405=NaN(size(unique_days,1),4);

    % loop over unique days
    for i=1:size(unique_days,1)

        tmp=pax405.BC_mass_conc( pax405.DateTime.Year==unique_days(i,1) & ...
                                 pax405.DateTime.Month==unique_days(i,2) & ...
                                 pax405.DateTime.Day==unique_days(i,3)          );

        dmean_405(i,1)=nanmean(tmp);
        dmean_405(i,2)=nanstd(tmp);
        dmean_405(i,3)=min(tmp);
        dmean_405(i,4)=max(tmp);

    end

    % save results in a table
    dmean_405=array2table(dmean_405,'variablenames',{'mean','std','min','max'}); 
    dmean_405.DateTime=datetime(unique_days)+hours(12);
    dmean_405(isnan(dmean_405.mean),:)=[];

    %%% PAX 870
    unique_days=unique(...
        [pax870.DateTime.Year,pax870.DateTime.Month,pax870.DateTime.Day],'rows');

    dmean_870=NaN(size(unique_days,1),4);

    % loop over unique days
    for i=1:size(unique_days,1)

        tmp=pax870.BC_mass_conc( pax870.DateTime.Year==unique_days(i,1) & ...
                                 pax870.DateTime.Month==unique_days(i,2) & ...
                                 pax870.DateTime.Day==unique_days(i,3)          );

        dmean_870(i,1)=nanmean(tmp);
        dmean_870(i,2)=nanstd(tmp);
        dmean_870(i,3)=min(tmp);
        dmean_870(i,4)=max(tmp);

    end

    % save results in a table
    dmean_870=array2table(dmean_870,'variablenames',{'mean','std','min','max'}); 
    dmean_870.DateTime=datetime(unique_days)+hours(12);
    dmean_870(isnan(dmean_870.mean),:)=[];
end


%% plot results
figure
set(gcf, 'Position', [100, 100, 950, 750]);
fig_ax = tight_subplot(2,2,[0.09,0.07],[0.08,0.08],[0.08,0.06]);

% BrO vs interpolated PAX data
axes(fig_ax(1))
tmp=interp1(pax405.DateTime,pax405.BC_mass_conc,bee_dataset.times);
ind=~isnan(tmp);
% ind=(~isnan(tmp) & bee_dataset.N_SE_rest==3);
dscatter(tmp(ind),bee_dataset.bro_col(ind)), hold on
xlim([-0.1,0.25])
ylim([0,8]*1e13)
ylabel('BrO part. col. (molec/cm^2)')
xlabel('PAX405 BC (\mug/m^3)')
r2=corrcoef(tmp(ind),bee_dataset.bro_col(ind));
r2=r2(1,2)^2;
text(0.05,0.93,['R^2 = ' num2str(round(r2,2))],'color','k','Units','normalized')
box on
grid on
tmp=median(tmp(ind));
plot([tmp,tmp],[0,8]*1e13,'k-')
tmp=median(bee_dataset.bro_col(ind));
plot([-0.1,0.25],[tmp,tmp],'k-')
legend('Normalized density','BrO, PAX medians')

axes(fig_ax(2))
tmp=interp1(pax870.DateTime,pax870.BC_mass_conc,bee_dataset.times);
ind=~isnan(tmp);
% ind=(~isnan(tmp) & bee_dataset.N_SE_rest==3);
dscatter(tmp(ind),bee_dataset.bro_col(ind)), hold on
xlim([-0.1,0.25])
ylim([0,8]*1e13)
xlabel('PAX870 BC (\mug/m^3)')
r2=corrcoef(tmp(ind),bee_dataset.bro_col(ind));
r2=r2(1,2)^2;
text(0.05,0.93,['R^2 = ' num2str(round(r2,2))],'color','k','Units','normalized')
box on
grid on
tmp=median(tmp(ind));
plot([tmp,tmp],[0,8]*1e13,'k-')
tmp=median(bee_dataset.bro_col(ind));
plot([-0.1,0.25],[tmp,tmp],'k-')

% daily mean values
axes(fig_ax(3))
[~,ind1,ind2]=intersect(dmean_bro.DateTime,dmean_405.DateTime);
plot(dmean_405.mean(ind2),dmean_bro.mean(ind1),'b.','markersize',10), hold on
xlim([0,0.14])
ylim([0,8]*1e13)
ylabel('Daily mean BrO part. col. (molec/cm^2)')
xlabel('Daily mean PAX405 BC (\mug/m^3)')
r2=corrcoef(dmean_405.mean(ind2),dmean_bro.mean(ind1));
r2=r2(1,2)^2;
text(0.05,0.93,['R^2 = ' num2str(round(r2,2))],'color','k','Units','normalized')
box on
grid on
tmp=median(dmean_405.mean(ind2));
plot([tmp,tmp],[0,8]*1e13,'k-')
tmp=median(dmean_bro.mean(ind1));
plot([0,0.14],[tmp,tmp],'k-')
legend('Daily mean values','Medians of daily mean data')

axes(fig_ax(4))
[~,ind3,ind4]=intersect(dmean_bro.DateTime,dmean_870.DateTime);
plot(dmean_870.mean(ind4),dmean_bro.mean(ind3),'b.','markersize',10), hold on
xlim([0,0.14])
ylim([0,8]*1e13)
xlabel('Daily mean PAX870 BC (\mug/m^3)')
r2=corrcoef(dmean_870.mean(ind4),dmean_bro.mean(ind3));
r2=r2(1,2)^2;
text(0.05,0.93,['R^2 = ' num2str(round(r2,2))],'color','k','Units','normalized')
box on
grid on
tmp=median(dmean_870.mean(ind4));
plot([tmp,tmp],[0,8]*1e13,'k-')
tmp=median(dmean_bro.mean(ind3));
plot([0,0.14],[tmp,tmp],'k-')

% figure
% subplot(121)
% pax405(isnan(pax405.BC_mass_conc),:)=[];
% pax870(isnan(pax870.BC_mass_conc),:)=[];
% [~,ind1,ind2]=intersect(pax405.DateTime,pax870.DateTime);
% dscatter(pax405.BC_mass_conc(ind1),pax870.BC_mass_conc(ind2))
% 
% subplot(122)
% [~,ind1,ind2]=intersect(dmean_405.DateTime,dmean_870.DateTime);
% plot(dmean_405.mean(ind1),dmean_870.mean(ind2),'b.','markersize',10)


