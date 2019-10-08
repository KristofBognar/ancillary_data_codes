% function merge_OPC_APS( low_Dp )
%MERGE_OPC_APS(low_Dp)
%
% Merge OPC and APS data for particles larger than low_Dp diameter. OPC
% measures physical size, while APS measures aerodynamic size, so merging
% by bins is not possible. Merging total data (or data above a DP) shold be
% fine.

load('/home/kristof/work/SMPS/smps+opc+aps/opc_size_dist_all.mat')
load('/home/kristof/work/SMPS/smps+opc+aps/aps_size_dist_all.mat')

% OPC_Dp is left boundary of size bin
% APS_Dp is middle of size bin

% define table and save datetime
tot_ssa=table();

tot_ssa.DateTime=[opc_time;aps_time];

% total particles for Dp > 1 micron
tot_ssa.supermicron=[sum(opc_data(:,3:end),2);sum(aps_data(:,11:end),2)];

% total particles for Dp > 0.5 micron
tot_ssa.halfmicron=[sum(opc_data(:,2:end),2);aps_tot_data];

save /home/kristof/work/SMPS/smps+opc+aps/tot_ssa.mat tot_ssa
% end

