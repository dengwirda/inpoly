function polydemo(varargin)
%POLYDEMO run a series of point-in-polygon demos.
%   POLYDEMO(II) runs the II-th demo, where +1 <= II <= +3. 
%   Demo problems illustrate varying functionality for the 
%   INPOLY2 routine.
%
%   See also INPOLY2, INPOLYGON

%   Darren Engwirda : 2018 --
%   Email           : d.engwirda@gmail.com
%   Last updated    : 19/12/2020

    if (nargin>=1) 
        id = varargin{1}; 
    else
        id =   +1;
    end

%------------------------------------------------- call demo
    switch (id)
        case 1, demo1;
        case 2, demo2;
        case 3, demo3;
        
        case-1, test1;
        case-2, test2;
        case-3, test3;

        otherwise
    error('polydemo:invalidInput','Invalid demo selection.');
    end

end

function demo1
%-----------------------------------------------------------
    fprintf(1,[...
'   INPOLY2 provides fast point-in-polygon queries for ob-\n',... 
'   jects in R^2. Like INPOLYGON, it detects points inside\n',...
'   and on the boundary of polygonal geometries.\n\n']);

    filename = mfilename('fullpath');
    filepath = fileparts( filename );

    addpath([filepath,'/mesh-file']);

    node = [
        4,0         % outer nodes
        8,4
        4,8
        0,4
        3,3         % inner nodes
        5,3
        5,5
        3,5
        ] ;
    edge = [
        1,2         % outer edges
        2,3
        3,4
        4,1
        5,6         % inner edges
        6,7
        7,8
        8,5
        ] ;

   [xpos,ypos] = meshgrid(-1.:0.2:+9.) ;
    xpos = xpos(:) ;
    ypos = ypos(:) ;

   [stat,bnds] = ...
        inpoly2([xpos,ypos],node,edge) ; 

    figure;
    plot(xpos(~stat),ypos(~stat),'r.', ...
        'markersize',14) ;
    axis equal off; hold on;
    plot(xpos( stat),ypos( stat),'b.', ...
        'markersize',14) ;
    plot(xpos( bnds),ypos( bnds),'ks') ;

end

function demo2
%-----------------------------------------------------------
    fprintf(1,[...
'   INPOLY2 supports multiply-connected geometries, consi-\n',... 
'   sting of arbitrarily nested sets of outer + inner bou-\n',...
'   ndaries.\n\n']);

    filename = mfilename('fullpath');
    filepath = fileparts( filename );

    addpath([filepath,'/mesh-file']);

    geom = loadmsh( ...
        [filepath,'/test-data/lakes.msh']);
    
    node = geom.point.coord(:,1:2);
    edge = geom.edge2.index(:,1:2);

    emid = .5 * node(edge(:,1),:) ...
         + .5 * node(edge(:,2),:) ;
    
    half = max (node,[],1) ...
         + min (node,[],1) ;
    half = half * +0.5 ;
    scal = max (node,[],1) ...
         - min (node,[],1) ;

    rpts = rand(7500,2) ;
    rpts(:,1) = ...
    1.10*scal(1)*(rpts(:,1)-.5)+half(1);
    rpts(:,2) = ...
    1.10*scal(2)*(rpts(:,2)-.5)+half(2);

    xpos = [ ...
    node(:,1); emid(:,1); rpts(:,1)] ;
    ypos = [ ...
    node(:,2); emid(:,2); rpts(:,2)] ;
    
   [stat,bnds] = ...
        inpoly2([xpos,ypos],node,edge) ; 

    figure;
    plot(xpos(~stat),ypos(~stat),'r.', ...
        'markersize',14) ;
    axis equal off; hold on;
    plot(xpos( stat),ypos( stat),'b.', ...
        'markersize',14) ;
    plot(xpos( bnds),ypos( bnds),'ks') ;

end

function demo3
%-----------------------------------------------------------
    fprintf(1,[...
'   INPOLY2 implements a "pre-sorted" variant of the cros-\n',...
'   sing-number test - returning queries in approximately \n',...
'   O((N+M)*LOG(N)) time for configurations consisting of \n',...
'   N test points and M edges. This is often considerably \n',...
'   faster than conventional approaches that typically re-\n',...
'   quire O(N*M) operations.\n\n']);

    filename = mfilename('fullpath');
    filepath = fileparts( filename );

    addpath([filepath,'/mesh-file']);

    geom = loadmsh( ...
        [filepath,'/test-data/coast.msh']);
    
    node = geom.point.coord(:,1:2);
    edge = geom.edge2.index(:,1:2);

    emid = .5 * node(edge(:,1),:) ...
         + .5 * node(edge(:,2),:) ;
    
    half = max (node,[],1) ...
         + min (node,[],1) ;
    half = half * +0.5 ;
    scal = max (node,[],1) ...
         - min (node,[],1) ;

    rpts = rand(2500,2) ;
    rpts(:,1) = ...
    1.10*scal(1)*(rpts(:,1)-.5)+half(1);
    rpts(:,2) = ...
    1.10*scal(2)*(rpts(:,2)-.5)+half(2);

    xpos = [ ...
    node(:,1); emid(:,1); rpts(:,1)] ;
    ypos = [ ...
    node(:,2); emid(:,2); rpts(:,2)] ;
    
    tic
   [stat,bnds] = ...
        inpoly2([xpos,ypos],node,edge) ;
    fprintf(1,'Runtime: %f (INPOLY2)  \n',toc);
    
    tic
   [stat,bnds] = inpolygon( ...
        xpos,ypos,node(:,1),node(:,2)) ;
    fprintf(1,'Runtime: %f (INPOLYGON)\n',toc);

    figure;
    plot(xpos(~stat),ypos(~stat),'r.', ...
        'markersize',14) ;
    axis equal off; hold on;
    plot(xpos( stat),ypos( stat),'b.', ...
        'markersize',14) ;
    plot(xpos( bnds),ypos( bnds),'ks') ;

end

%-----------------------------------------------------------

function test1
%TEST-1: check "empty" case, from @vbandaruk

    filename = mfilename('fullpath');
    filepath = fileparts( filename );

    addpath([filepath,'/mesh-file']);

    node = [
        4,0         % outer nodes
        8,4
        4,8
        0,4
        3,3         % inner nodes
        5,3
        5,5
        3,5
        ] ;
    edge = [
        1,2         % outer edges
        2,3
        3,4
        4,1
        5,6         % inner edges
        6,7
        7,8
        8,5
        ] ;

   [xpos,ypos] = meshgrid(-1.:0.1:+9.) ;
    xpos = xpos(:) + 12. ;
    ypos = ypos(:) ;

   [stat,bnds] = ...
        inpoly2([xpos,ypos],node,edge) ; 

    figure;
    plot(xpos(~stat),ypos(~stat),'r.', ...
        'markersize',14) ;
    axis equal off; hold on;
    plot(xpos( stat),ypos( stat),'b.', ...
        'markersize',14) ;
    plot(xpos( bnds),ypos( bnds),'ks') ;
    plot(node(:, 1), node(:, 2), 'mo') ;

end

function test2
%TEST-2: check "on-bnds" cases, from @husdemir

    px=[+0.0 -1.0 +0.5 +2.0 +3.0 +0.0]';
    py=[-3.0 +1.0 +2.0 +3.0 +2.0 -3.0]';

    dx=0.1;
    x=linspace(min(px)-dx,max(px)+dx,200);
    y=linspace(min(py)-dx,max(py)+dx,400);
    [x,y]=meshgrid(x,y);
    x=x(:);
    y=y(:);

    plot(px,py,'b-','linewidth',4)
    hold on; axis equal
    plot(px,py,'bo','markersize',18)
    plot(x,y,'r.')

    [in,on] = inpoly2([x,y],[px,py],[],1e-2);

    in2=in & ~on;

    plot(x(in2),y(in2),'b.')
    hold on; axis equal
    plot(x(on),y(on),'ks')
    plot(px,py,'g-','linewidth',4)
    plot(px,py,'go','markersize',18)

end

function test3
%TEST-3: check domain inc. various xy "turns"

    node = [
        0,0
        4,0
        4,2
        6,2
        6,0
        8,0
        8,6
        6,6
        6,4
        4,4
        4,8
        2,8
        2,6
        0,6
        0,4
        2,4
        2,2
        0,2
        ] ;

   [xpos,ypos] = meshgrid(-1.:0.1:+9.) ;
    xpos = xpos(:) ;
    ypos = ypos(:) ;

   [stat,bnds] = ...
        inpoly2([xpos,ypos],node) ; 

    figure;
    plot(xpos(~stat),ypos(~stat),'r.', ...
        'markersize',14) ;
    axis equal off; hold on;
    plot(xpos( stat),ypos( stat),'b.', ...
        'markersize',14) ;
    plot(xpos( bnds),ypos( bnds),'ks') ;
    plot(node(:, 1), node(:, 2), 'mo') ;

end



