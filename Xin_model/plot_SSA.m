% function [  ] = plot_SSA(  )
%PLOT_SSA Summary of this function goes here
%   Detailed explanation goes here

% if true, loads SSA from sea ice, else loads SSA from open ocean
from_ice=true;

%% read/load SSA fields in g/cm3

if from_ice
    SSA_file='/home/kristof/work/models/p-TOMCAT/SISS.mat';
else
    SSA_file='/home/kristof/work/models/p-TOMCAT/OOSS.mat';
end

if exist(SSA_file,'file')
    % data has been read in
    load(SSA_file)
else
    % read in data from .nc files (returns profile in g/cm3)
    
    ssa=[];

    for i=1:21

        disp(i)
        if from_ice
            [ ft,ssa(:,:,i),~,~,h] = get_pTOMCAT_data(['SISS' num2str(i)],'prof');
        else
            [ ft,ssa(:,:,i),~,~,h] = get_pTOMCAT_data(['OOSS' num2str(i)],'prof');
        end

    end
    
    % save file
    save(SSA_file,'ft','h','ssa');
    
end
    
%% calculate number density

% dry sea salt particle radius (um) of each bin in model output 
% indices run from 0 to 20 for bins 1-21!
r_bin=(10.0.^(0.15*([0:20])-2.0));  

% unit particle mass (g) in each bin
% Xin used 2.16 for NaCl density (g/cm3)
m_bin=2.16*4*pi*(r_bin*1e-4).^3 /3;

ssa_nd=ssa;

for i=1:21
   
    ssa_nd(:,:,i)=ssa_nd(:,:,i)./m_bin(i);
    
end



% h_lab=ones(size(h))*0.65;
% [~,h_ind]=min(abs(h-h_lab),[],2);

nd_sum=sum(ssa_nd(:,:,15:19),3);

% nd_sum=sum(nd_sum(:,1:5),2);

figure(1)

plot(ft-58,nd_sum(:,5)'*4e4)
% plot(ft-58,nd_sum(:,5)')

% xlim([7,21])

% end

