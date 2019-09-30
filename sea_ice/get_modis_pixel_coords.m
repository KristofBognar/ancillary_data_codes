% use MODIS Lambert Azimuthal Equal-Area Tile Grid coordinate calculator to
% get pixel coordinates for given pixel


lat=NaN(951,951);
lon=NaN(951,951);
cur_dir=pwd();
cd('/home/kristof/programs/MODIS_tilemap/tilemap3_r4_0')

n=0;
for i=0:950

    for j=0:950
        
        disp_str=['Calculating line ', num2str(i+1), ', col ' num2str(j+1)];
        % stuff to delete last line and reprint updated message
        fprintf(repmat('\b',1,n));
        fprintf(disp_str);
        n=numel(disp_str);    
        
        runstr=['! ./tilemap3_linux np k inv tp 9 8 ' num2str(i) ' ' num2str(j)];
        outstr=evalc(runstr);
        
        tmp=strsplit(outstr,' ');
        lat(i+1,j+1)=str2double(tmp{13});
        lon(i+1,j+1)=str2double(tmp{15});

    end
end

cd(cur_dir)

fprintf('\n')
