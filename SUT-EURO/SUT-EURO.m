%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% SCRIPT DEL MÉTODO SUT-EURO-1 %%%%%%%%%%%
%%%%%% CON TRATAMIENTO EXPLÍCITO DE LOS IMP. NETOS S/ PRODUCTOS %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Elaborado por Juan Manuel Valderas Jaramillo
% Julio/2015
% Departamento de Economía Aplicada I
% Universidad de Sevilla
% Este programa efectúa la proyección de una Tablas de Origen y Destino a
% precios básicos de acuerdo con la metodología SUT-EURO desarrollada por
% Beutel (2008) en la que los impuestos netos de subvenciones sobre
% los productos son tratados de manera explícita.
% Reseteamos todo
clear all
clc
% cd('C:\Users\u156024\Projects\SUT_projection\Data\SUT-EURO')
cd('C:\Users\u156024\Projects\SUT_projection\Data\SUT-EURO_example')
% Toda la información para la proyección se obtiene de las siguientes matrices:
% TO_0 es la Tabla de Origen del año de referencia (Producto x Rama) incluyendo
% en la última columna el vector de importaciones por producto. En nuestro caso
% como se trata de la simétrica contiene datos en la diagonal principal.
TO_0=csvread('TOsim_0.csv');
% TD_int_0 es la Tabla de Destino de los productos interiores (Producto x
% Rama+DF), contiene tanto la demanda intermedia como final. En las 2 últimas
% filas se incluyen tres vectores: el primero con los TLS para cada rama y la DF,
% el segundo con el VAB para cada rama y el tercero con la producción total por
% ramas en el caso de dos componente de demanda es la suma de los consumos
%(interiores e importados) y los TLS para los componentes de la demanda final.
TD_int_0=csvread('TDdom_0.csv');
% TD_imp_0 es la Tabla de Destino de los productos importados (Producto x
% Rama+DF), contiene tanto la demanda intermedia como final.
TD_imp_0=csvread('TDimp_0.csv');
% mod es el vector con las tasas de variación objetivio. Contiene los crecimientos
% del vab, la demanda, las M y los imp netos sobre los productos es (1x58).
% 52 vab por ramas, 1 GCF, 1 FBK, 1 X, 1 M, 1 Imp sobre los productos, 1 VAB total
mod=csvread('mod.csv');
% Información necesaria para el método. Se obtiene a partir de las matrices
% anteriores
% Información correspondiente al año de referencia (año 0)
% V0 Make-Matrix (traspuesta de la tabla de Origen) (Rama x Producto)
% Ud0 Matriz de empleos interiores de la Demanda Intermedia a p.b. (Producto x Rama)
% Um0 Matriz de empleos importados de la Demanda Intermedia a p.b. (Producto x Rama)
% Yd0 Matriz de empleos interiores de la Demanda Final a p.b. (Producto x Comp. D.F.)
% Ym0 Matriz de empleos importados de la Demanda Final a p.b. (Producto x Comp. D.F.)
% VAB0 Vector de total de valores añadidos por rama a p.b. (Rama x 1)
% DF0 Vector con los totales de la Demanda Final por componente a
% p.b.(Componentes de la Demanda Final x 1)
% Sea t0 el vector de impuestos netos de subvenciones sobre los productos
% (Rama Componentes de la DF x 1)
% m0 vector de importaciones del año base (Productos x 1)
% x0 Vector con la Producción Total por Ramas (Ramas x 1)
% tM0 Escalar con Total de importaciones (1x1)
% Información correspondiente al año de proyección (año t)
% VABt Vector de total de valores añadidos por rama (Rama x 1)
#VABt=csvread('VABt.csv');
% DFt Vector con los totales de la Demanda Final por componente a
% p.adq.(Componentes de la Demanda Final x 1)
#DFt=csvread('DFt.csv');
% tMt Escalar con Total de importaciones (1x1)
#tMt=csvread('tMt.csv');
% TLSt Escalar con el total de INSP (1x1)
#TLSt=csvread('TLSt.csv');
% Variables auxiliares
% Nº de Productos Interiores, Importados y Nº de Ramas
p=size(TO_0,1);
r=size(TO_0,2)-1;
m=1;
pimp=size(TD_imp_0,1);
f=size(TD_int_0,2)-r;
tls=1;
% Vectores Auxiliares de Unos
ir=ones(r,1);
ip=ones(p,1);
idf=ones(f,1);
irf=ones(r+f,1);
im=ones(m,1);
ipimp=ones(pimp,1);
I=eye(p);
% Preparando matrices
V0=TO_0(1:p,1:r)'; % Make matrix
m0=TO_0(:,end);
tM0=ipimp'*m0;
Ud0=TD_int_0(1:p,1:r);
Um0=TD_imp_0(1:pimp,1:r);
Yd0=TD_int_0(1:p,r+1:r+f);
Ym0=TD_imp_0(1:pimp,r+1:r+f);
t0=TD_int_0(p+1,1:r+f)';
VAB0=TD_int_0(p+2,1:r)';
x0=TD_int_0(p+3,1:r)';
DF0=TD_int_0(p+3,r+1:r+f)';
TLS0=irf'*t0;
% Comprobación de coherencia de la información suministrada
if abs(V0*ip-x0)>0.000001;
error('Tabla de Origen no consistente con Producción por Ramas')
end
if abs(V0'*ir-Ud0*ir-Yd0*idf)>0.000001;
error('No existe equilibrio entre oferta de productos y demanda de productos interiores')
end
if abs(m0'*ipimp-tM0)>0.000001;
error('Vector de Importaciones inconsistente con total de importaciones')
end
if abs(m0-Um0*ir-Ym0*idf)>0.000001;
error('No existe equlibrio entre oferta y demanda de importaciones')
end
if abs(Ud0'*ip+Um0'*ipimp+t0(1:r)-x0+VAB0)>0.000001;
error('No existe equilibrio entre Consumos Intemerdios a Precios de Adquisición')
end
%el excel trabaja con una precisión de 15 dígitos incluidos decimales.
%$Octave con 16 decimales.por eso aparecen discrepancias t bajamos el umbral de error
if abs(Yd0'*ip+Ym0'*ipimp+t0(r+1:r+f)-DF0)>0.001;
error('No existe equilibrio en Demanda Final a precios de Adquisición')
end
if abs(t0'*irf-TLS0)>0.000001
error('No coincide total de INSP con TLS0');
end

% Vectores con tasas de variación objetivo
% gv (vab de las 52 ramas de actividad)
gv=mod(1,1:length(VAB0))';
% gy (demanda GCF, FBK, X)
gy=mod(1,length(VAB0)+1:length(VAB0)+length(DF0))';
% gm (importaciones)
gm=mod(1,length(VAB0)+length(DF0)+1:length(VAB0)+length(DF0)+1)';
% gtls (impuestos netos sobtre los productos)
gtls=mod(1,length(VAB0)+length(DF0)+2:end-1);

% Segregación de vectores de impuestos
tDI0=t0(1:r);
tDF0=t0(r+1:r+f);
% Inicio de la primera iteración
% Primera Etapa: Obtención del market-share de la economía
% Output por productos
q0d=Ud0*ir+Yd0*idf;
% Market-share año base
D0=V0/diag(q0d);
% Segunda etapa: Actualización de las tablas de Origen y de Destino
% (Inconsistentes)
% Definición de wf y wc
wf=diag([gv;gv;gtls]);
wc=diag([gv;gy]);
% Construcción de T0
T0=[Ud0 Yd0;Um0 Ym0;tDI0' tDF0'];
% Matrices T1 y T2
T1=wf*T0;
T1(isnan(T1))=0;
T2=T0*wc;
% Matriz T3
% Versión Media Aritmética
% T3=(T1+T2)/2;
% Versión Media Geométrica;
T3=(T1.*T2);
T3=T3.^0.5;
T3=T3.*sign(T1);
% Descomposición de T3
Ud1=T3(1:p,1:r);
Yd1=T3(1:p,r+1:r+f);
Um1=T3(p+1:p+pimp,1:r);
Ym1=T3(p+1:p+pimp,r+1:r+f);
tDI1=T3(p+pimp+1,1:r)';
tDF1=T3(p+pimp+1,r+1:r+f)';
% Actualización del VAB
v1=diag(gv)*VAB0;
% Actualización de Make-Matriz
q1d=Ud1*ir+Yd1*idf;
V1=D0*diag(q1d);
% Tercera etapa: Obtención de la producción total por ramas consistente
% Estructuras productivas
xinp1=Ud1'*ip+Um1'*ipimp+v1+tDI1;
Bd1=Ud1/diag(xinp1);
Bm1=Um1/diag(xinp1);
Btls1=tDI1./xinp1;
Btls1(isnan(Btls1))=0;
fd1=Yd1*idf;
% Producción de equilibrio
x2=(I-D0*Bd1)\(D0*fd1);
% Cuarta Etapa: Nuevas tablas de Origen y de Destino consistentes
Ud2=Bd1*diag(x2);
Um2=Bm1*diag(x2);
tDI2=Btls1.*(x2);
Yd2=Yd1;
Ym2=Ym1;
tDF2=tDF1;
v2=x2-(Ud2'*ip+Um2'*ipimp)-tDI2;
q2d=Ud2*ir+Yd2*idf;
V2=D0*diag(q2d);
m2=(Um2*ir+Ym2*idf);
% Quinta Etapa: Comprobación de convergencia
% Proyecciones para el VAB por ramas
proyvab=v2;
% Proyecciones para la DF por componentes
proydf=(Yd2'*ip+Ym2'*ipimp+tDF2);
% Proyecciones para el total de importaciones
proym=m2'*ipimp;
% Proyecciones para el total de impuestos
proyTLS=tDI2'*ir+tDF2'*idf;

% Valores que deseamos conseguir
VABt=[VAB0].*[gv];
DFt=[DF0].*[gy];
tMt=[tM0].*[gm];
TLSt=[TLS0].*[gtls];

% gtls (impuestos netos sobtre los productos)
gtls=mod(1,length(VAB0)+length(DF0)+2:end-1);

% Vector de desviaciones y vector de errores
dev=[VABt;DFt;tMt;TLSt]./[proyvab;proydf;proym;proyTLS];
dev(isnan(dev))=1;
err=dev-1;
% Fin de la primera iteración
% Criterio de convergencia
% Cuenta de Iteraciones
iter = 1;
% Margen para Convergencia
eps = 0.000001;
% Factor de elasticidad del ajuste
c=0.92;
% Error máximo
Maxerror=max(abs(err));
% Comienzo de las segunda y sucesivas iteraciones
% Definimos factores de crecimiento para iteración y los multiplicadores
fv=gv;
fy=gy;
fm=gv;
ftls=gtls;
corr=ones(length(dev),1);
while Maxerror>eps
  for i=1:length(dev)
if dev(i)>=1
corr(i)=1+(abs((dev(i)-1)*100)^c)/100;
else
corr(i)=1-(abs((1-dev(i))*100)^c)/100;
end
end
% Factores corregidos por los multiplicadores
fv=fv.*corr(1:r);
fy=fy.*corr(r+1:r+f);
fm=fm.*corr(r+f+1:r+f+1);
ftls=ftls.*corr(r+f+2:r+f+2);
% Nuevos wf y wc. Nótese que cambia el multiplicador de las importaciones
wf=diag([fv;fm;ftls]);
wc=diag([fv;fy]);
% Repetición del proceso de actualización
T1=wf*T0;
%T1(isnan(T1))=0; %Al corregir el vector error T1 ya no tiene NAN
T2=T0*wc;
% T3=(T1+T2)/2;
% Versión Media Geométrica;
T3=(T1.*T2);
T3=T3.^0.5;
T3=T3.*sign(T1);
Ud1=T3(1:p,1:r);
Yd1=T3(1:p,r+1:r+f);
Um1=T3(p+1:p+pimp,1:r);
Ym1=T3(p+1:p+pimp,r+1:r+f);
tDI1=T3(p+pimp+1,1:r)';
tDF1=T3(p+pimp+1,r+1:r+f)';
v1=diag(fv)*VAB0;
q1d=Ud1*ir+Yd1*idf;
V1=D0*diag(q1d);
xinp1=Ud1'*ip+Um1'*ipimp+v1+tDI1;
Bd1=Ud1/diag(xinp1);
Bm1=Um1/diag(xinp1);
Btls1=tDI1./xinp1;
fd1=Yd1*idf;
x2=(I-D0*Bd1)\(D0*fd1);
Ud2=Bd1*diag(x2);
Um2=Bm1*diag(x2);
tDI2=Btls1.*x2;
Yd2=Yd1;
Ym2=Ym1;
tDF2=tDF1;
v2=x2-(Ud2'*ip+Um2'*ipimp)-tDI2;
q2d=Ud2*ir+Yd2*idf;
V2=D0*diag(q2d);
m2=(Um2*ir+Ym2*idf);
proyvab=v2;
proydf=(Yd2'*ip+Ym2'*ipimp+tDF2);
proym=m2'*ipimp;
proyTLS=tDI2'*ir+tDF2'*idf;
dev=[VABt;DFt;tMt;TLSt]./[proyvab;proydf;proym;proyTLS];
dev(isnan(dev))=1;
err=dev-1;
Maxerror = max(abs(err));
iter = iter+1;
end
% Comprobación de coherencia de la información proyectada
if abs(V2*ip-Ud2'*ip-Um2'*ipimp-tDI2-VABt)>0.001
error('Matriz de Oferta no consistente con Producción por Ramas')
end
if abs(V2'*ir-Ud2*ir-Yd2*idf)>0.001
error('No existe equilibrio entre oferta de productos y demanda de productos interiores')
end
if abs(m2'*ipimp-tMt)>10000%cambiados los limites
error('Vector de Importaciones inconsistente con total de importaciones')
end
if abs(m2-Um2*ir-Ym2*idf)>0.001
error('No existe equlibrio entre oferta y demanda de importaciones')
end
if abs(Yd2'*ip+Ym2'*ipimp+tDF2-DFt)>10000%cambiados los limites
error('No existe equilibrio en Demanda Final a precios de Adquisición')
end
if abs(tDI2'*ir+tDF2'*idf-TLSt)>0.001e
error('No coincide total de INSP con TLSt');
end
% Reconstruyendo matrices proyectadas
X_TO_t=[V2' m2]; % Matriz de Oferta Proyectada
X_TDu_t=[Ud2;Um2;tDI2';v2']; % Matriz de Destino Interior para DI Proyectada
X_TDu_t(isnan(X_TDu_t))=0;
X_TDy_t=[Yd2;Ym2;tDF2';[0;0;0]']; % Matriz de Destino Interior para DF Proyectada
X_tD_t=[tDI2;tDF2]';% Vectod de Impuestos
X_v_t=[v2;[0;0;0]]';%Vector del VAB + tres ceros en la demanda final
% Reconstruyendo la tabla simetrica proyectada
X_TST_t=[X_TDu_t,X_TDy_t];
X_TST_t(isnan(X_TST_t))=0;
% Reconstruyendo matrices de referencia
A_TO_0=TO_0;
A_TDu_0=[TD_int_0(1:p,1:r);TD_imp_0(1:p,1:r);TD_int_0(p+1,1:r)];
A_TDy_0=[TD_int_0(1:p,r+1:r+f);TD_imp_0(1:p,r+1:r+f);TD_int_0(p+1,r+1:r+f)];

%%%%METER IMPUESTOS Y VAB (DOS FILAS MAS)
% Exportar ficheros
csvwrite("TD_t.csv",X_TST_t);
csvwrite("TO_t.csv",X_TO_t);
disp("SUT-EURO applied");
