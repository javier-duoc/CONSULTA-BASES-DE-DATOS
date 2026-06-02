/*Conciertos Chile, requiere listar información específica de los trabajadores de forma
ordenada y respetando las normas de visualización.
Es importante destacar que solo serán listados todos aquellos trabajadores cuyo sueldos
base esté entre un margen de $650.000 y $3.000.000*/

SELECT 
NOMBRE || ' ' || APPATERNO || ' ' || APMATERNO AS " NOMBRE COMPLETO TRABAJADOR",
TO_CHAR(NUMRUT,'99G999G999') || '-' || DVRUT "RUT TRABAJADOR",
tt.DESC_CATEGORIA "TIPO TRABAJADOR",
NOMBRE_CIUDAD "CIUDAD TRABAJADOR",
TO_CHAR(t.SUELDO_BASE, '$9G999G999') "SUELDO BASE"
FROM TRABAJADOR t
INNER JOIN TIPO_TRABAJADOR tt 
ON tt.ID_CATEGORIA = t.ID_CATEGORIA_T
INNER JOIN COMUNA_CIUDAD c
ON c.ID_CIUDAD = t.ID_CIUDAD
WHERE t.SUELDO_BASE BETWEEN 650000 AND 3000000
ORDER BY c.NOMBRE_CIUDAD DESC, t.SUELDO_BASE ASC;
------------------------------------------------------------------------

/*Caso 2: Listado Cajeros
Especificación de Requerimientos o reglas
Con la finalidad de implementar un registro bitácora por trabajador que haya vendido tickets,
se tendrá que listar a todos los trabajadores que tengan rol de CAJERO, mostrando:
? Cantidad de tickets vendidos
? Total vendido entre los tickets
? Comisión total que estos tengan.
? Nombre de la comuna del trabajador
Es importante destacar que Conciertos Chile solo requiere información de la suma de los
montos de los tickets sea superior a $50.000.*/

SELECT 
TO_CHAR(NUMRUT, '99G999G999') || '-' || DVRUT "RUT TRABAJADOR",
NOMBRE || ' ' || APPATERNO "NOMBRE TRABAJADOR"
FROM TRABAJADOR;
---------------------------------------------------------

/*Uno de los principales módulos que se implementará por el cliente requiere información
precisa. Es necesario saber el año de ingreso de cada trabajador para saber su antigüedad,
si este tiene asignación familiar a través de las cargas familiares, además si pertenece a
ISAPRE o si es FONASA.
Si es FONASA el bono subirá un 1% en base a su sueldo. Si no es FONASA no se asignará
bono extra.
El bono por años de antigüedad se asignará a todo trabajador y se calcula de la siguiente
forma: con 10 o menos años trabajados se asignará un 10% de su sueldo, y los que tengan
11 o más años trabajados se le asignará un bono del 15% de su sueldo.
El reporte solo debe considerar aquellos trabajadores que no tenga fecha de término del
estado civil o que la fecha de término del estado civil termine posterior a la fecha de
ejecución del reporte.*/

SELECT 
TO_CHAR(t.NUMRUT, '99G999G999') "RUT TRABAJADOR",
t.NOMBRE || ' ' || t.APPATERNO || ' ' || t.APMATERNO "Trabajador Nombre",
TO_CHAR(t.FECING, 'YYYY') "AÑO INGRESO",
TRUNC(MONTHS_BETWEEN(SYSDATE, t.FECING) / 12) AS "AÑOS ANTIGUEDAD",
COUNT (a.NOMBRE_CARGA) "NUM CARGAS FAMILIARES",
i.NOMBRE_ISAPRE "NOMBRE ISAPRE",
TO_CHAR(t.SUELDO_BASE, '$9G999G999') "SUELDO BASE"
FROM TRABAJADOR t 
INNER JOIN ASIGNACION_FAMILIAR a
ON a.NUMRUT_T = t.NUMRUT 
INNER JOIN ISAPRE i
ON i.COD_ISAPRE = t.COD_ISAPRE
GROUP BY t.NUMRUT, t.NOMBRE, t.APPATERNO, t.APMATERNO, t.FECING,
i.NOMBRE_ISAPRE, i.COD_ISAPRE, i.PORC_DESCTO_ISAPRE, t.SUELDO_BASE
ORDER BY t.NUMRUT, i.COD_ISAPRE;




