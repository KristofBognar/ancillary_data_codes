function [ data_out ] = find_coincident_mean( t_lowf, t_highf, data_highf, bin_hwidth, circ )
%FIND_COINCIDENT_MEAN find mean of high frequency data around low freq
%times, within the specified time window
%
% INPUT: 
%   t_lowf: times where averages are reuired (matlab datetime)
%   t_highf: times corresponding to high frequency dataset (matlab datetime)
%   data_highf: high frequency data (same size as t_highf)
%   bin_hwidth: half-width of the averaging time window, in minutes
%   circ: optional, calculate circular mean (for wind direction data in degrees)
%
% OUTPUT:
%   data_out: averaged data (same size as t_lowf)

if nargin==4, circ=false; end

if size(t_highf)~=size(data_highf), error('Data dimension mismatch'), end

data_out=NaN(size(t_lowf));

if length(bin_hwidth)==1
    bin_hwidth=ones(size(t_lowf))*bin_hwidth;
elseif length(bin_hwidth)~=length(t_lowf)
    error('averaging window must be single number, or the same size as first argument')
end

for i=1:length(t_lowf) % couldn't be bothered to find a more efficient way...
    
    % indices of data_highf points that are within the requited time limit for the
    % given low freq time
    ind=abs(t_highf-t_lowf(i)) <= minutes(bin_hwidth(i));
    
    if isempty(ind), continue, end
    
    if ~circ % regular average

        data_out(i)=nanmean( data_highf(ind) );
        
    else % circular average
        
       data_out(i)=circ_mean( data_highf(ind)*(pi/180) ) *(180/pi);
       if data_out(i)<0, data_out(i)=360+data_out(i); end
        
    end
end


end

