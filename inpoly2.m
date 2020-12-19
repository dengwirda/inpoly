function [STAT,BNDS] = inpoly2(varargin)
%INPOLY2 compute "points-in-polygon" queries.  
%   [STAT] = INPOLY2(VERT,NODE,EDGE) returns the "inside/ou-
%   tside" status for a set of vertices VERT and a polygon 
%   {NODE,EDGE} embedded in a two-dimensional plane. General
%   non-convex and multiply-connected polygonal regions can 
%   be handled. VERT is an N-by-2 array of XY coordinates to 
%   be tested. STAT is an associated N-by-1 logical array,
%   with STAT(II) = TRUE if VERT(II,:) is an interior point.
%   The polygonal region is defined as a piecewise-straight-
%   line-graph, where NODE is an M-by-2 array of polygon ve-
%   rtices and EDGE is a P-by-2 array of edge indexing. Each
%   row in EDGE represents an edge of the polygon, such that
%   NODE(EDGE(KK,1),:) and NODE(EDGE(KK,2),:) are the coord-
%   inates of the endpoints of the KK-TH edge. If the argum-
%   ent EDGE is omitted it assumed that the vertices in NODE
%   are connected in ascending order.
%
%   [STAT,BNDS] = INPOLY2(..., FTOL) also returns an N-by-1 
%   logical array BNDS, with BNDS(II) = TRUE if VERT(II,:)
%   lies "on" a boundary segment, where FTOL is a floating-
%   point tolerance for boundary comparisons. By default, 
%   FTOL = EPS ^ 0.85.
%
%   See also INPOLYGON

%   This algorithm is based on a "crossing-number" test, co-
%   unting the number of times a line extending from each 
%   point past the right-most region of the polygon interse-
%   cts with the polygonal boundary. Points with odd counts 
%   are "inside". A simple implementation requires that each
%   edge intersection be checked for each point, leading to 
%   O(N*M) complexity...
%
%   This implementation seeks to improve these bounds:
%
% * Sorting the query points by y-value and determining can-
%   didate edge intersection sets via binary-search. Given a
%   configuration with N test points, M edges and an average 
%   point-edge "overlap" of H, the overall complexity scales 
%   like O(M*H + M*LOG(N) + N*LOG(N)), where O(N*LOG(N))
%   operations are required for sorting, O(M*LOG(N)) operat-
%   ions required for the set of binary-searches, and O(M*H) 
%   operations required for the intersection tests, where H 
%   is typically small on average, such that H << N. 
%
% * Carefully checking points against the bounding-box asso-
%   ciated with each polygon edge. This minimises the number
%   of calls to the (relatively) expensive edge intersection 
%   test.

%   Darren Engwirda : 2017 --
%   Email           : d.engwirda@gmail.com
%   Last updated    : 19/12/2020

%---------------------------------------------- extract args
    node = []; edge = []; vert = []; 
    
    fTOL = eps ^ .85;
    
    if (nargin>=+1), vert = varargin{1}; end
    if (nargin>=+2), node = varargin{2}; end
    if (nargin>=+3), edge = varargin{3}; end
    if (nargin>=+4), fTOL = varargin{4}; end
    
%---------------------------------------------- default args
    nnod = size(node,1) ;
    nvrt = size(vert,1) ;
    
    if (isempty(edge))
        edge = [(1:nnod-1)',(2:nnod)'; nnod,1];
    end
    
%---------------------------------------------- basic checks    
    if ( ~isnumeric(node) || ...
         ~isnumeric(edge) || ...
         ~isnumeric(vert) || ...
         ~isnumeric(fTOL) )
        error('inpoly2:incorrectInputClass' , ...
            'Incorrect input class.') ;
    end

%---------------------------------------------- basic checks
    if (ndims(node) ~= +2 || ...
        ndims(edge) ~= +2 || ...
        ndims(vert) ~= +2 || ...
        numel(fTOL) ~= +1 )
        error('inpoly2:incorrectDimensions' , ...
            'Incorrect input dimensions.');
    end
    if (size(node,2)~= +2 || ... 
        size(edge,2)~= +2 || ...
        size(vert,2)~= +2 )
        error('inpoly2:incorrectDimensions' , ...
            'Incorrect input dimensions.');
    end
    
%---------------------------------------------- basic checks
    if (min([edge(:)]) < +1 || ...
            max([edge(:)]) > nnod)
        error('inpoly2:invalidInputs', ...
            'Invalid EDGE input array.') ;
    end

    STAT = false(size(vert,1),1) ;
    BNDS = false(size(vert,1),1) ;

%----------------------------------- prune points using bbox
    nmin = min(node,[],1);
    nmax = max(node,[],1);
    ddxy = nmax - nmin ;
    
    lbar = sum(ddxy) / 2.;
    
    veps = fTOL * lbar ;

    mask = ...
    vert(:,1) >= min (node(:,1)) - veps & ...
    vert(:,1) <= max (node(:,1)) + veps & ...
    vert(:,2) >= min (node(:,2)) - veps & ...
    vert(:,2) <= max (node(:,2)) + veps ;
 
    vert = vert(mask, :) ;

    if (isempty(vert)), return; end

%-------------- flip to ensure the y-axis is the "long" axis
    vmin = min(vert,[],1);
    vmax = max(vert,[],1);
    ddxy = vmax - vmin ;    

    if (ddxy(1) > ddxy(2))
    vert = vert(:,[2,1]) ;
    node = node(:,[2,1]) ;
    end
    
%----------------------------------- sort points via y-value
    swap = ...
       node(edge(:,2),2) ...
     < node(edge(:,1),2) ;
         
    edge(swap,[1,2]) = ...
        edge(swap,[2,1]) ;    
  
   [~,ivec] = ...
        sort(vert(:,+2)) ;
    vert = vert (ivec,:) ;
    
    if (exist( ...
        'OCTAVE_VERSION','builtin')  > +0)
    
    if (exist('inpoly2_oct','file') == +3)
        
    %-- delegate to the compiled version of the code if it's
    %-- available
        
       [stat,bnds] = ...
            inpoly2_oct( ...
                vert,node,edge,fTOL,lbar) ;
    
    else
   
    %-- otherwise, just call the native m-code version
   
       [stat,bnds] = ...
            inpoly2_mat( ...
                vert,node,edge,fTOL,lbar) ;
   
    end
   
    else
        
    %-- MATLAB's JIT is generally smart enough these days to
    %-- run this efficiently
        
       [stat,bnds] = ...
            inpoly2_mat( ...
                vert,node,edge,fTOL,lbar) ;
        
    end
    
    stat(ivec) = stat ;
    bnds(ivec) = bnds ;

    STAT(mask) = stat ;
    BNDS(mask) = bnds ;

end



