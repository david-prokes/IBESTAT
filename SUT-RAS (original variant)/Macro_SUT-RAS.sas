

/*===========================================================================================*/
/*============================ SUT-RAS-INE MACRO DEFINITION =================================*/
/*===========================================================================================*/


%macro SUT_RAS(PROD, CI, IMPOR, MARG, IMPU, DEMF, TPROD, TCI, TIMPOR, TMARG, TIMPU, TDEMF, TOL, PPROD, PCI, PIMPOR, PMARG, PIMPU, PDEMF);
/* Entradas:
ImplementaciÃ³n en SAS del proceso de proyecciÃ³n de tablas origen y destino descrito en:
Temurshoev, U. and Timmer, M.P. (2011), Joint estimation of supply and use tables. Papers in Regional Science, 90: 863-882.
(DOI https://doi.org/10.1111/j.1435-5957.2010.00345.x)
*********************** ENTRADAS ****************************************************
Tablas origen y destino base:
PROD: Agregado ProducciÃ³n de la tabla origen. Variables R_PRODUCTO, C_RAMA, VALOR.
CI: Agregado Consumos Intermedios de la tabla destino. Variables R_PRODUCTO, C_RAMA, VALOR.
IMPOR: Importaciones. Variables: R_PRODUCTO, C_AGREGADO, VALOR.
MARG: MÃ¡rgenes. Variables: R_PRODUCTO, C_AGREGADO, VALOR.
IMPU: Impuestos. Variables: R_PRODUCTO, C_AGREGADO, VALOR.
DEMF: Demanda final. Variables: R_PRODUCTO, C_AGREGADO, VALOR.

Totales a los que hay que ajustar la tabla proyectada:
TPROD: ProducciÃ³n de la tabla origen. Variables C_RAMA, VALOR.
TCI: Agregado Consumos Intermedios de la tabla destino. Variables C_RAMA, VALOR.
TIMPOR: Importaciones. Variables: R_PRODUCTO, VALOR.
TMARG: MÃ¡rgenes. Variables: C_AGREGADO, VALOR.
TIMPU: Impuestos. Variables: C_AGREGADO, VALOR.
TDEMF: Demanda final. Variables: C_AGREGADO, VALOR.

*********************** SALIDAS ****************************************************
Tablas origen y destino proyectadas:
PPROD: Agregado ProducciÃ³n de la tabla origen. Variables R_PRODUCTO, C_RAMA, VALOR.
PCI: Agregado Consumos Intermedios de la tabla destino. Variables R_PRODUCTO, C_RAMA, VALOR.
PIMPOR: Importaciones. Variables: R_PRODUCTO, C_AGREGADO, VALOR.
PMARG: MÃ¡rgenes. Variables: R_PRODUCTO, C_AGREGADO, VALOR.
PIMPU: Impuestos. Variables: R_PRODUCTO, C_AGREGADO, VALOR.
PDEMF: Demanda final. Variables: R_PRODUCTO, C_AGREGADO, VALOR.
*/


/* Lo primero nos aseguramos de que las tablas estan completas, incluidas las celdas a cero*/


/* Lista con los productos de todas las tablas */
proc sql;
	create table productos as
	select distinct r_producto from (
		select r_producto from &PROD.
		union all
		select r_producto from &CI.
		union all
		select r_producto from &IMPOR.
		union all
		select r_producto from &MARG.
		union all
		select r_producto from &IMPU.
		union all
		select r_producto from &DEMF.
	);
quit; 


/* Vamos creando una base para cada tabla */
/* Objetivo: para cada tabla y nombre de columna correspondiente, se devuelve la
misma tabla pero añadiendo todas las combinaciones posibles entre productos
y las columnas únicas originales, con valor 0 en caso de dar NULL. */
%crea_base(&PROD., C_RAMA);
%crea_base(&CI., C_RAMA);
%crea_base(&IMPOR., C_AGREGADO);
%crea_base(&MARG., C_AGREGADO);
%crea_base(&IMPU., C_AGREGADO);
%crea_base(&DEMF., C_AGREGADO);


/* Comprobamos que todas las columnas de las tablas tienen totales. Si falta un total se aplica la suma de esa columna en la tabla base*/
/*Objetivo: Se comprueban los totales por agrupación de las columnas, además de,
aplicar los totales del año base en caso de no haber para el año proyectado
para cada columna.*/
%comprueba_tot(&PROD., &TPROD., C_RAMA);
%comprueba_tot(&CI., &TCI., C_RAMA);
%comprueba_tot(&IMPOR., &TIMPOR., C_AGREGADO);
%comprueba_tot(&MARG., &TMARG., C_AGREGADO);
%comprueba_tot(&IMPU., &TIMPU., C_AGREGADO);
%comprueba_tot(&DEMF., &TDEMF., C_AGREGADO);


/*  Ahora rellenamos una macro con los numeros de filas y columnas de cada tabla */


/* El numero de filas es el mismo para todas las tablas*/
proc sql noprint;
	select count(distinct r_producto) into :filas from productos;
quit;
proc sql noprint;
	select count(distinct c_rama) into :columnas_PROD from B&PROD.;
quit;
proc sql noprint;
	select count(distinct c_rama) into :columnas_CI from B&CI.;
quit;
proc sql noprint;
	select count(distinct c_agregado) into :columnas_IMPOR from B&IMPOR.;
quit;
proc sql noprint;
	select count(distinct c_agregado) into :columnas_MARG from B&MARG.;
quit;
proc sql noprint;
	select count(distinct c_agregado) into :columnas_IMPU from B&IMPU.;
quit;
proc sql noprint;
	select count(distinct c_agregado) into :columnas_DEMF from B&DEMF.;
quit;


%let columnas_UG=%eval(&columnas_CI + &columnas_DEMF);
%let columnas_VG=%eval(&columnas_PROD + &columnas_IMPOR + &columnas_MARG + &columnas_IMPU);


PROC IML;

/* Leemos los vectores y los transformamos en matrices */
/* B&PROD: Make matrix */
USE B&PROD.; 
READ ALL var {valor} INTO VPROD;
VT=shape(VPROD, &filas, &columnas_PROD);
*Generamos la make matrix, es la transpuesta de la matriz de ORIGEN;
V=VT`;
/* B&IMPOR: Importaciones por productos y categoría de importaciones. */
USE B&IMPOR.; 
READ ALL var {valor} INTO VIMPOR;
M=shape(VIMPOR, &filas, &columnas_IMPOR);
/* B&MARG: Márgenes por productos y categoría de márgenes. */
USE B&MARG.; 
READ ALL var {valor} INTO VMARG;
T=shape(VMARG, &filas, &columnas_MARG);
/* B&IMP: TLS por productos y categorías, generalmente 1. */
USE B&IMPU.; 
READ ALL var {valor} INTO VIMPU;
n=shape(VIMPU, &filas, &columnas_IMPU);
/* B&CI: Intermediate use matrix. */
USE B&CI.; 
READ ALL var {valor} INTO VCI;
U=shape(VCI, &filas, &columnas_CI);
/* B&DEMF: Final use matrix. */
USE B&DEMF.; 
READ ALL var {valor} INTO VDEMF;
Y=shape(VDEMF, &filas, &columnas_DEMF);

*Leemos los vectores de totales;
/* TPROD: Output por indústrias. */
USE &TPROD._C; 
READ ALL var {valor} INTO TPROD;
/* TIMPR: Importaciones por productos. */
USE &TIMPOR._C; 
READ ALL var {valor} INTO TIMPOR;
/* TMARG: Total por márgenes. */
USE &TMARG._C; 
READ ALL var {valor} INTO TMARG;
/* TIMPU: Total de TLS. */
USE &TIMPU._C; 
READ ALL var {valor} INTO TIMPU;
totV0=TPROD//TIMPOR//TMARG//TIMPU;
/* TCI1: Total usos intermedios por indústrias. */
USE &TCI._C; 
READ ALL var {valor} INTO TCI;
/* TDEMF: Total usos finales por categorías de demanda final. */
USE &TDEMF._C; 
READ ALL var {valor} INTO TDEMF;
/* totU0: Total de usos por ramas y categorías de demanda final. */
totU0=TCI//TDEMF;
U0=U||Y;
V0T=VT||M||T||n;
V0=V0T`;

logU=U0>0.0001;
/* Dividimos las matrices en valores negativos N y positivos P.*/
PU0=U0#logU;
NU0=PU0-U0;
PU0T=PU0`;
logV=V0>0.0001;
PV0=V0#logV;
NV0=PV0-V0;
NV0T=NV0`;
/* ru: Vector aplicado por productos */
ru=shape(1, &filas, 1);
/* su: Vector aplicado por usos (indústrias + categorías finales) */
su=shape(1, &columnas_UG, 1);
/* rv: Vector aplicado a tabla de origen (ramas + importaciones + márgenes + TLS) */
rv=shape(1, &columnas_VG, 1);
rud=diag(ru);
sud=diag(su);
rvd=diag(rv);
/* TOL: Error máximo tolerado. */
TOL=&TOL.;
DIFF=100;
ITER=0;
	do until (DIFF < TOL & ITER<200);/* Si tras 200 itreaciones no converge seguramente será¡ un problema con los datos*/
		ITER=ITER+1;
		print ITER;
		/* ru_1: Cópia versión t-1 para detectar convergencia. */
		ru_1=ru;
		/* pu: Suma ponderada de usos positivos y producción negativa por producto. */
		pu=PU0*su+(NV0T)*inv(rvd)*shape(1, &columnas_VG, 1);
		/* nu: Suma ponderada de usos negativos y producción positiva por producto. */
		nu=NU0*inv(sud)*shape(1, &columnas_UG, 1)+PV0`*rv;
		/* Actualización vector ru. */
		ru=sqrt(inv(diag(pu))*nu);
		rud=diag(ru);
		irud=inv(rud);
		/* su: Proporción u (target year) / u (base year) (1 + % crecimiento). */
		su=0.5*inv(diag(PU0`*ru))*(totU0+sqrt(totU0#totU0+4*(PU0`*rud*shape(1, &filas, 1))#(NU0`*irud*shape(1, &filas, 1))));
		/* rv: Proporción x (target year) / x (base year) (1 + % crecimiento). */
		rv=0.5*inv(diag(PV0*irud*shape(1, &filas, 1)))*(totV0+sqrt(totV0#totV0+4*(PV0*irud*shape(1, &filas, 1))#(NV0*rud*shape(1, &filas, 1))));
		sud=diag(su);
		rvd=diag(rv);

		DIFF=max(abs(ru_1 - ru));
	end;
print DIFF;
/* Calculamos las tablas de origen y destino proyectadas*/
	UF=rud*PU0*sud-inv(rud)*NU0*inv(sud);
	VF=rvd*PV0*inv(rud)-inv(rvd)*NV0*rud;


CI_P=UF[1:&filas, 1:&columnas_CI];
CI_P_V=shape(CI_P, 0, 1);
inid=1+&columnas_CI;
finde=inid+&columnas_DEMF-1;
DEMF_P=UF[1:&filas, inid:finde];
DEMF_P_V=shape(DEMF_P, 0, 1);


PROD_P=VF`[1:&filas, 1:&columnas_PROD];
PROD_P_V=shape(PROD_P, 0, 1);
ini=1+&columnas_PROD;
fin=ini+&columnas_IMPOR-1;
IMPOR_P=VF`[1:&filas, ini:fin];
IMPOR_P_V=shape(IMPOR_P, 0, 1);

ini=fin+1;
fin=ini+&columnas_MARG-1;
MARG_P=VF`[1:&filas, ini:fin];
MARG_P_V=shape(MARG_P, 0, 1);

ini=fin+1;
fin=ini+&columnas_IMPU-1;
IMPU_P=VF`[1:&filas, ini:fin];
IMPU_P_V=shape(IMPU_P, 0, 1);

CREATE CI_P_V from CI_P_V[colname={"VALOR_C"}];
APPEND from CI_P_V;
CREATE DEMF_P_V from DEMF_P_V[colname={"VALOR_C"}];
APPEND from DEMF_P_V;

CREATE PROD_P_V from PROD_P_V[colname={"VALOR_C"}];
APPEND from PROD_P_V;
CREATE IMPOR_P_V from IMPOR_P_V[colname={"VALOR_C"}];
APPEND from IMPOR_P_V;
CREATE MARG_P_V from MARG_P_V[colname={"VALOR_C"}];
APPEND from MARG_P_V;
CREATE IMPU_P_V from IMPU_P_V[colname={"VALOR_C"}];
APPEND from IMPU_P_V;
quit;


data &PPROD.;
	set B&PROD.;
	set PROD_P_V;
run;

data &PIMPOR.;
	set B&IMPOR.;
	set IMPOR_P_V;
run;

data &PMARG.;
	set B&MARG.;
	set MARG_P_V;
run;


data &PIMPU.;
	set B&IMPU.;
	set IMPU_P_V;
run;


data &PCI.;
	set B&CI.;
	set CI_P_V;
run;


data &PDEMF.;
	set B&DEMF.;
	set DEMF_P_V;
run;




%mend SUT_RAS;





%macro crea_base(tabla, columna);
/*
Objetivo: para cada tabla y nombre de columna correspondiente, se devuelve la
misma tabla pero añadiendo todas las combinaciones posibles entre productos
y las columnas únicas originales, con valor 0 en caso de dar NULL.

Primera consuta SQL crea una tabla "acumula" con r_producto, columna, VALOR.
Segunda consulta SQL crea una tabla "base" a partir de una subconsulta que coge
los valores DISTINCT de la columna de "acumula" para, posteriormente, aplicar
un CROSS JOIN implícito con cada uno de los productos de "productos".
Tercera consulta SQL crea una tabla "B&tabla" a partir de un LEFT OUTER JOIN,
es decir, se unen todos los valores observados con todas las posibles
combinaciones coincidentes, dejando además, aquellas combinaciones no
observadas. Para este último caso, cuando haya valor NULL se devolverá 0 en
la agrupación por suma.
*/

proc sql;
	create table acumula as
	select r_producto, &columna., sum(valor) as VALOR 
	from &tabla.
	group by r_producto, &columna.
	;
quit;

proc sql;
	create table BASE as
	select p.r_producto, r.&columna. 
	from productos as p, (select distinct &columna. from acumula ) as r
	;
quit;

proc sql;
	create table B&TABLA. as
	select b.*, sum(0, t.VALOR) as VALOR from BASE as b 
	left outer join acumula as t on b.r_producto=t.r_producto
	and b.&columna.=t.&columna.
	order by b.r_producto, b.&columna.
	;
quit;

%mend crea_base;

%macro comprueba_tot(tabla, totales, columna);
/*
Objetivo: Se comprueban los totales por agrupación de las columnas, además de, 
aplicar los totales del año base en caso de no haber para el año proyectado 
para cada columna.

Primera consulta de SQL crea una tabla "TCOLUMNAS" para obtener el total por
columnas de las tablas originales.
Segunda consulta de SQL crea una tabla "TOTAL" para obtener el total por
columnas a partir de los totales del año a proyectar.
Tercera consulta de SQL crea una tabla de totales "..._C" para extraer
de cada columna el valor total correspondiente del año a proyectar. En
caso de que no haya valor, se escoge el valor correspondiente del año
base. Para ello se hace un LEFT OUTER JOIN.
Cuarta consulta de SQL crea una tabla de totales "..._C2" para permitir la 
comparativa de manera directa de aquellos casos en los que no haya valores
en el año proyectado y se cojan del año base.
*/
	proc sql;
		create table TCOLUMNAS as
		select &columna., sum(valor) as VALOR from &tabla
		group by &columna.
		;
	quit;
proc sql;
	create table TOTAL as
	select &columna., sum(valor) as VALOR 
	from &totales.
	group by &columna.
	;
quit;
	proc sql;
		create table &totales._C as
		select c.&columna., coalesce(t.valor, c.valor) as VALOR 
		from TCOLUMNAS as c left outer join TOTAL as t
		on c.&columna.=t.&columna.
		order by c.&columna.
		;
	quit;
	proc sql;
		create table &totales._C2 as
		select c.&columna., t.&columna. as &columna._T, coalesce(t.valor, c.valor) as VALOR
		from TCOLUMNAS as c 
		left outer join TOTAL as t on c.&columna.=t.&columna.
		order by c.&columna.
		;
	quit;

%mend comprueba_tot;
