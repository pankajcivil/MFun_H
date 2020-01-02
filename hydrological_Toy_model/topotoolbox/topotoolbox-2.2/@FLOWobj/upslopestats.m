function OUT = upslopestats(FD,VAR,meth)

%UPSLOPESTATS upslope statistics of a variable based on the flow direction matrix
%
% Syntax
%
%     S = upslopestats(FD,VAR,type)
%
% Description
%
%     upslopestats returns various statistical parameters such as mean and
%     standard deviation of each cell's upslope located cells in VAR based on
%     the flow direction matrix M. Note that while mean and standard 
%     deviation are calculated fairly fast, the calculation of minimum and 
%     maximum is non-vectorized and usually takes longer to evaluate.
%
% Input
%
%     FD        flow direction object (FLOWobj)
%     VAR       variable (e.g. slope calculated by gradient8) (GRIDobj)
%     type      'mean' (default), 'std' standard deviation, 
%               'var' variance, 'min', 'max'               
%
% Output
% 
%     S         array same size as VAR
%
% Example
%
%     DEM = GRIDobj('srtm_bigtujunga30m_utm11.tif');
%     FD = FLOWobj(DEM,'preprocess','c');
%     G  = gradient8(DEM);
%     Gup = upslopestats(FD,G,'mean');
%     imageschs(DEM,Gup,'caxis',[0 1])
%
% References
%
%     Lane, S. N., Brookes, C. J., Kirkby, M. J. & Holden, J. A, 2004: A
%     network-index-based version of TOPMODEL for use with high-resolution 
%     digital topographic data Hydrological Processes, 18, 191-201. 
%
% See also: FLOWDIR, FLOWACC
%
% Author: Wolfgang Schwanghart (w.schwanghart[at]geo.uni-potsdam.de)
% Date: 4. March, 2016


% 4/3/2016: the function now makes copies of FD.ix and FD.ixc (see 
% FLOWobj/flowacc

narginchk(2,3)

% check alignment
validatealignment(FD,VAR);
if isa(VAR,'GRIDobj')
    VAR = VAR.Z;
end

if nargin == 2;
    meth = 'mean';
else
    meth = validatestring(meth,{'mean','std','var','min','max','sum'});
end

switch meth
    case {'mean','std','var'}
        % Count
        n = flowacc(FD);
        n = n.Z;
        % Sum
        S = flowacc(FD,VAR);
        S = S.Z;
end
        


switch meth
    case 'sum'
        % Simply Flowacc
        VAR = flowacc(FD,VAR);
        VAR = VAR.Z;
    case 'mean'
        % Sum/Count
        VAR = S./n;
    case {'std','var'}
        % formula for calculating an unbiased estimate of the population variance
        % ! may be very much affected by round-off errors, arithmetic
        % overflow and underflow
        TEMP = flowacc(FD,VAR.^2);
        TEMP = TEMP.Z;
        
        VAR = 1./(n-1) .* ((TEMP - (S.^2)./n));
        VAR(n==1) = 0;
        if any(VAR(:)<0)
            warning('TopoToolbox:roundofferror','Results affected by numerical round-off errors')
            VAR = max(VAR,0);
        end
        switch meth
            case 'std'
                VAR = sqrt(VAR);
        end
    case 'min'
        ix = FD.ix;
        ixc = FD.ixc;
        % minimum imposition
        for r = 1:numel(ix);
            VAR(ixc(r)) = min(VAR(ix(r)),VAR(ixc(r)));
        end
    case 'max'
        ix = FD.ix;
        ixc = FD.ixc;
        % maximum imposition
        for r = 1:numel(ix);
            VAR(ixc(r)) = max(VAR(ix(r)),VAR(ixc(r)));
        end
end

%% Prepare Output
% empty GRIDobj
OUT = copy2GRIDobj(FD);
% write output to GRIDobj
OUT.Z = VAR;
OUT.zunit = '';
OUT.name  = ['upslope statistics (' meth ')'];


  