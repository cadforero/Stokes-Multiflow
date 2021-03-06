% proyecta de manera iterativa un elipsoide con volumen igual al de una
% esfera unitaria (4/3)pi y exceso de area dado por excesoareaobj y lo
% guarda en un archivo sph num2save.mat. el valor de num2save debe ser
% mayor que 5. La toleracia del error de exceso de area es de 1e-5

% generacion de elipsoides - semilla
clc;
clear;

reflevel = 3;
name2save = 'ellipsoide95';

a = .79;
b = 1.3;
c = .79;
r = 1;

noiseint = 0.025;
noiserep = 20;

% cargue la esfera
fileload = ['sph ref ' num2str(reflevel) '.mat'];
% Cargue el archivo de solucion *.mat
load([cd '/' fileload]);

% numero de gotas
geom.numdrops = 1;
% Coordenadas de los centroides de las gotas
xc =[0 0 0];
% Introduzca el/los radios de la/s gotas
xr=1;
% numero de elementos y numero de nodos

geom.nodes = Nodes;
geom.elements = Elements;
geom.numnodes = size(geom.nodes,1);
geom.numelements = size(geom.elements,1);
geom.numnodes = size(geom.nodes,1);
numnodes = geom.numnodes;

% calcule las propiedades y tablas de la malla
% Index table
geom.indextable = 1:1:geom.numnodes;
% Tabla de elementos singulares a cada nodo
geom.element2node = element2node(geom.elements);
% Tabla de conectividad de nodos, bordes, e.t.c
geom.nodecon2node = node2node(geom.elements);
% Calcule las propiedades iniciales
normalandgeoopt.normal = 1;
normalandgeoopt.areas = 1;
normalandgeoopt.vol = 1;
geomprop = normalandgeo(geom,normalandgeoopt);
geom.normalele = geomprop.normalele;
geom.normal = geomprop.normal;
geom.dsi = geomprop.dsi;
geom.ds = geomprop.ds;
geom.s = geomprop.s;
geom.vol = geomprop.vol;
geom.jacmat = geomprop.jacmat;
geom.volini = 4.*pi/3.;
geom.areaini = 4.*pi;

paropt.tipo = 'extended';
[geom.curv,geom.normal,geom.Kg] = curvparaboloid(geom,paropt);

geom.nodecon2node = node2node(geom.elements);
lmin = zeros(numnodes,1);
for k = 1:numnodes
   % extraiga los nodos vecinos a un nodo en la misma gota 
   nodesadj = geom.nodecon2node{k};
   lmin(k) = min(normesp(repmat(geom.nodes(k,:),[size(nodesadj,1) 1])...
      - geom.nodes(nodesadj,:)));  
end

% Ruido
% Longitud minima para verificacion de paso de tiempo.
lmint = min(lmin);

for k = 1:noiserep
    noisevel = ones(size(geom.nodes))...
            .*(rand(size(geom.nodes))-0.5)*lmint*noiseint;
    noisenormal = repmat(sum(noisevel.*geom.normal,2),[1 3]).*geom.normal;
    noisetan = noisevel - noisenormal;

    geom.nodes = geom.nodes + noisetan;
end

for i = 1:geom.numnodes
    x = geom.nodes(i,1)^2;
    y = geom.nodes(i,2)^2;
    z = geom.nodes(i,3)^2;
    mag = sqrt(x+y+z);
    geom.nodes(i,1) = geom.nodes(i,1)*r*a/mag;
    geom.nodes(i,2) = geom.nodes(i,2)*r*b/mag;
    geom.nodes(i,3) = geom.nodes(i,3)*r*c/mag;
end

[lapbelmat,geom.Kg] = discretelaplacebeltrami(geom);
[geom.curv] = curvlb(geom,lapbelmat);
paropt.tipo = 'extended';
[geom.curv,geom.normal,geom.Kg] = curvparaboloid(geom,paropt);

normalandgeoopt.normal = 0;
normalandgeoopt.areas = 1;
normalandgeoopt.vol = 1;
geomprop = normalandgeo(geom,normalandgeoopt);
geom.dsi = geomprop.dsi;
geom.ds = geomprop.ds;
geom.s = geomprop.s;
geom.vol = geomprop.vol;

errorvoltol = 1e-6;
optesc.maxit = 1000;
optesc.kp = 20;
optesc.deltate = 0.01;
optesc.tolerrorvol = errorvoltol;
errorvol = (geom.vol - geom.volini)./geom.volini;
geom = scaling(geom,optesc,errorvol);

disp(['Volumen: ',num2str(geom.vol)]);
disp(['Area: ',num2str(geom.s)]);
volred = 6*sqrt(pi)*geom.vol/geom.s^(3/2);
disp(['Volumen reducido: ',num2str(volred)]);

Nodes = geom.nodes;
Elements = geom.elements;

grafscfld(geom,1); xlabel('x1'); ylabel('x2'); zlabel('x3'); view(90,0); 
axis equal;
nombrearchivo = [name2save '.mat'];
save(nombrearchivo,'Nodes','Elements');
disp(['archivo ' nombrearchivo ' guardado'])

