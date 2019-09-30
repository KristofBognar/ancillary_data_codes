
[header,y]=flex_header('C:\Users\Output\',0,0,0); %Change File Location%

[a,b,c,d]=flex_read_V7(header,1,1,1,1,0);

[ar,vo]=calculate_grid_area_eff(header);
 
[name,loc,conc]=flex_read_recepconc(header,1,6);

[xgrid,ygrid,zgrid,xdum,ydum,zdum,numT]=size(a);

sample_avg=header.loutaver/60;  %average time in minutes%

%need 1 hour averages%
num1hr=numT*sample_avg/60; %number of 1hour average samples%

[dum,latgrid]=size(header.latp);
[dum,longrid]=size(header.latp);
avg1hr=repmat(0,[latgrid,longrid]);
hr_cnt=0;
num_dig=4; %number of digits the average 1hour matrix will be rounded to%


for i=1:num1hr
    for j=1:round(60/sample_avg);
       avg1hr=avg1hr+a(:,:,1,1,1,1,j+hr_cnt);
    end
    
    avg1hr=((avg1hr*((0.001*24.5)/(64.1*1000)))/(round(60/sample_avg))); %convert nearest integer in ppm%
    avg1hr = round(avg1hr*(10^num_dig))/(10^num_dig); %rounding to four digits only%
    
    %max_element=max(max(avg1hr));
    %copyt=avg1hr;
    %copyt(copyt==0)=Inf;
    %min_element=min(min(copyt));
    %v=linspace(min_element,max_element,15);
    %which_elem=[];
    
    %for ielem=1:2:size(v,2)-1;
    %    cnt_elem(ielem)=numel(avg1hr(avg1hr(:)>v(ielem) & avg1hr(:)<v(ielem+1)));
    %    if cnt_elem(ielem)< 2;
    %       which_elem=[which_elem;ielem];
    %       which_elem=[which_elem;ielem+1];
    %    end
    %end
    
    %which_elem=[which_elem;(max(which_elem)+1)];
          
    %if max(which_elem) == size(linspace(min_element,max_element,10),2)-1;
    %   which_elem=[which_elem;max(which_elem)+1];
    %end 
    
    %v(:,which_elem)=[];
    
    %[val,index]=max(cnt_elem);
    
    %v=linspace(min_element,v(index+1),10);
    
    %run_kml=1;
    %if max(cnt_elem)==5;
    %   run_kml=0;
    %end
    
    %if max_element>0 & run_kml==1
     try
       filenam=sprintf('my_kml_%i',i)
       k=kml(filenam);
       [xm,ym]=meshgrid(header.latp,header.lonp);
       [min_element,max_element,v]=get_ContourRange(avg1hr)
       my_levels=v
       %my_levels=[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.5 2 3 4 5]
       k.contour(ym,xm,avg1hr,'numberOfLevels',my_levels);
       k.save(filenam);      
       avg1hr=repmat(0,[latgrid,longrid]);
     catch exception
       %[min_element, max_element,v]=get_ContourRangeAgain(v,avg1hr)
       disp(sprintf('zero concentrations detected in the %ith 1-hour sample', hr_cnt));
    end
    hr_cnt=hr_cnt+1;
end