
du=2.687e16;
load('/home/kristof/work/brewer/Brewer69_2004_2016_all_modes.mat');

year='2006';

brewer=eval(['combined_raw_' year]);

ind=find(strcmp(brewer.ObsCode,'DS'));

ft=brewer.UTC(ind)-yeartime(str2double(year));

time=str2double(year)+(ft./365);

plot(time,brewer.ColumnO3(ind),'k-')
