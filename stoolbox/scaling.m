% Funcion de escalaje de malla
function geom = scaling(geom,optesc,ErrorVol)

% recupere las variabels geometricas
NormalAtNodes = geom.normal;
NodesBC = geom.nodes;
VolumeIni = geom.volini;

% recupere las opciones
if nargin < 2
    % opciones por defecto
    TolErrorVol = 1e-3;
    maxit = 15000;
    Kp = 20;
    DeltaTe = 0.01;
else
    TolErrorVol = optesc.tolerrorvol;
    maxit = optesc.maxit;
    Kp = optesc.kp;
    DeltaTe = optesc.deltate;
end
    
% opciones para la rutina de calculo de volumen
normalandgeoopt.normal = 0;
normalandgeoopt.areas = 1;
normalandgeoopt.vol = 1;

% Bandera para entrar al bucle de correccion

% Velocidad de correccion
VelCor = 1;

k = 0;
while abs(ErrorVol)>TolErrorVol
    k = k +1;
        
    % Accion de Control CORRECION
    VelCorN = ErrorVol*VelCor*Kp;
    % Actualice los nodos a la nueva pos corregida Correccion
    VelDesp = (DeltaTe).*(VelCorN.*NormalAtNodes);
    
    geom.nodes = geom.nodes + VelDesp;
     
    % Calculo de Volumen antes de la correccion
    geomprop = normalandgeo(geom,normalandgeoopt);
    geom.dsi = geomprop.dsi;
    geom.ds = geomprop.ds;
    geom.s = geomprop.s;
    geom.vol = geomprop.vol;

    % Calculo del Error en Volumen despues de correccion
    ErrorVol = (VolumeIni - geom.vol)/VolumeIni; 
    
    if k == maxit
        % deje la gota como esta
        geom.nodes = NodesBC;
        geom = normalandgeo(geom,normalandgeoopt);
        error ('El escalaje no convergio');
        break
    end
end
disp(['Rescaling: ' num2str(ErrorVol), ' it: ', num2str(k)]);