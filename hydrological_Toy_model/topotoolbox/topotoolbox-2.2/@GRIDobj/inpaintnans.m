function DEM = inpaintnans(DEM,varargin)

%INPAINTNANS interpolate missing values in a grid (GRIDobj)
%
% Syntax
%
%     DEMf = inpaintnans(DEM,type)
%     DEMf = inpaintnans(DEM,type,k)
%     DEMf = inpaintnans(DEM,DEM2)
%     DEMf = inpaintnans(DEM,DEM2,method)
%
% Description
% 
%     inpaintnans fills gaps in a grid (GRIDobj) generated by measurement
%     errors or missing values. The user may choose between different
%     techniques to fill the gaps. Note that the algorithm fills only
%     pixels not connected to the DEM grid boundaries.
%
%     inpaintnans(DEM,type) or inpaintnans(DEM,type,k) fills missing values
%     in the DEM based on the values surrounding regions with missing values.
%
%     inpaintnans(DEM,DEM2) or inpaintnans(DEM,DEM2,method) fills missing
%     values using interpolation from another grid. An example is that 
%     missing values in a SRTM DEM could be filled with values derived from
%     an ASTER GDEM.
%
% Input
%
%     DEM      digital elevation model with missing values
%               indicated by nans (GRIDobj)
%     type      fill algorithm 
%               'laplace' (default): laplace interpolation 
%                     as implemented in roifill
%               'fill': elevate all values in each connected
%                     region of missing values to the minimum
%                     value of the surrounding pixels (same as 
%                     the function nibble in ArcGIS Spatial Analyst)
%               'nearest': nearest neighbor interpolation 
%                     using bwdist
%     k         if supplied, only connected components with 
%               less or equal number of k pixels are filled. Others
%               remain nan
%     DEM2      if the second input argument is a GRIDobj, inpaintnans will
%               interpolate from DEM2 to locations of missing values in
%               DEM. This approach does not support a third input argument.
%     method    interpolation method if second input argument is a GRIDobj.
%               {'linear'},'nearest','spline','pchip', or 'cubic'.
%
% Output
%
%     DEM      processed digital elevation model (GRIDobj)
%
% Example
%     
%     DEM = GRIDobj('srtm_bigtujunga30m_utm11.tif');
%     DEM.Z(300:400,300:400) = nan;
%     subplot(1,2,1)
%     imageschs(DEM,[],'colorbar',false)
%     DEMn = inpaintnans(DEM);
%     subplot(1,2,2);
%     imageschs(DEMn,[],'colorbar',false)
%
% 
% See also: ROIFILL, FILLSINKS, BWDIST
%
% Author: Wolfgang Schwanghart (w.schwanghart[at]geo.uni-potsdam.de)
% Date: 18. September, 2017

if nargin == 1
    DEM.Z = deminpaint(DEM.Z,varargin{:});
elseif ischar(varargin{1})
    DEM.Z = deminpaint(DEM.Z,varargin{:});
elseif isa(varargin{1},'GRIDobj')
    if nargin == 2
        method = 'linear';
    else
        method = varargin{2};
        method = validatestring(method,...
        {'linear','nearest','spline','pchip','cubic'},'GRIDobj/inpaintnans','method',3);
    end
    INAN = isnan(DEM);
    IX   = find(INAN.Z);
    [x,y] = ind2coord(DEM,IX);
    znew  = interp(varargin{1},x,y,method);
    DEM.Z(IX) = znew;
end

end

function dem = deminpaint(dem,type,k)
if nargin == 1
    type = 'laplace';
    k    = inf;
elseif nargin == 2
    k    = inf;
end
   
% error checking    
% clean boundary
I = isnan(dem);
I = imclearborder(I);

if ~isinf(k)
    I = xor(bwareaopen(I,k+1),I);
end

% 
if numel(dem) < 10000^2 || ~strcmpi(type,'laplace');

% interpolation
switch lower(type)
    case 'nearest'
        % nearest neighbor interpolation
        [~,L] = bwdist(~I);
        dem = dem(L);
    case 'laplace'
        % -- use roifill (Code before 2015a)    
        % dem = roifill(dem,imdilate(I,ones(3)));
        % -- use regionfill (Code after and including 2015a)
        dem = regionfill(dem,I);
    case 'fill'
        % fill to lowest surrounding neighbor
        marker = inf(size(dem),class(dem));
        markerpixels = imdilate(I,ones(3)) & ~I;
        marker(markerpixels) = dem(markerpixels);
        mask = dem;
        mask(I | isnan(dem)) = -inf;
        marker = -marker;
        mask   = -mask;
        demrec = imreconstruct(marker,mask);
        dem(I) = -demrec(I);
    otherwise
        error('type unknown')
end

else
    CC = bwconncomp(I);
    STATS = regionprops(CC,'SubarrayIdx','Image');
   
    for r = 1:numel(STATS)
        rows = STATS(r).SubarrayIdx{1};
        rows = [min(rows)-1 max(rows)+1];
        cols = STATS(r).SubarrayIdx{2};
        cols = [min(cols)-1 max(cols)+1];
        
        demtemp = dem(rows(1):rows(2),cols(1):cols(2));
        inatemp = padarray(STATS(r).Image,[1 1],false);
        % -- Code before 2015a        
        % demtemp = roifill(demtemp,imdilate(inatemp,ones(3)));   
        % -- Code after and including 2015a
        demtemp = regionfill(demtemp,inatemp);  
        dem(rows(1):rows(2),cols(1):cols(2)) = demtemp;
    end
end
end
