--CASO 1:


INSERT INTO RECAUDACION_BONOS_MEDICOS ("RUT MEDICO", "NOMBRE_MEDICO", "TOTAL_RECAUDADO", "UNIDAD_MEDICA")
SELECT 
    -- RUT completo
    TO_CHAR(MEDICO.rut_med, 'FM00G000G000') || '-' || MEDICO.dv_run AS "RUT MEDICO",
    
    -- Nombre completo
    UPPER(TRIM(MEDICO.pnombre || ' ' || MEDICO.apaterno || ' ' || NVL(MEDICO.amaterno, ''))) AS "NOMBRE_MEDICO",
    
    -- Total recaudado (solo año anterior)
    SUM(BONO_CONSULTA.costo) AS "TOTAL_RECAUDADO",
    
    -- Unidad médica
    UPPER(UNIDAD_CONSULTA.nombre) AS "UNIDAD_MEDICA"

FROM MEDICO 
INNER JOIN BONO_CONSULTA  ON MEDICO.rut_med = BONO_CONSULTA.rut_med
    AND EXTRACT(YEAR FROM BONO_CONSULTA.fecha_bono) = EXTRACT(YEAR FROM SYSDATE) - 1
INNER JOIN UNIDAD_CONSULTA  ON MEDICO.uni_id = UNIDAD_CONSULTA.uni_id
INNER JOIN CARGO  ON MEDICO.car_id = CARGO.car_id

WHERE 
    CARGO.car_id NOT IN (100, 500, 600)
    AND UPPER(CARGO.nombre) NOT IN (
        UPPER('Presidente Junta Medica'),
        UPPER('Psiquiatra'),
        UPPER('Director Medico')
    )

GROUP BY 
    MEDICO.rut_med,
    MEDICO.dv_run,
    MEDICO.pnombre,
    MEDICO.apaterno,
    MEDICO.amaterno,
UNIDAD_CONSULTA.nombre

HAVING SUM(costo) > 0

ORDER BY SUM(costo) DESC;

COMMIT;


SELECT * FROM RECAUDACION_BONOS_MEDICOS ORDER BY "TOTAL_RECAUDADO" DESC;




SELECT 
    TO_CHAR(rut_med, 'FM00G000G000') || '-' || dv_run AS "RUT",
    UPPER(pnombre || ' ' || apaterno) AS "NOMBRE",
    UPPER(nombre) AS "CARGO_EXCLUIDO"
FROM MEDICO 
INNER JOIN CARGO  ON car_id = car_id
WHERE car_id IN (100, 500, 600)
   OR UPPER(nombre) IN (UPPER('Presidente Junta Medica'), UPPER('Psiquiatra'), UPPER('Director Medico'));

--CONSULTA FINAL
SELECT * FROM RECAUDACION_BONOS_MEDICOS ORDER BY "TOTAL_RECAUDADO" ASC;


---CASO 2:



-- PASO 2: CREAR TABLA
CREATE TABLE REPORTE_PERDIDAS_ESPECIALIDAD (
    especialidad_medica    VARCHAR2(50)   PRIMARY KEY,
    cantidad_bonos         NUMBER(10)     NOT NULL,
    monto_perdida          NUMBER(12,2)   NOT NULL,
    fecha_bono_antiguo     DATE           NOT NULL,
    estado_cobro           VARCHAR2(20)   NOT NULL
);
/

-- PASO 3: INSERTAR DATOS (BONOS NO PAGADOS)
INSERT INTO REPORTE_PERDIDAS_ESPECIALIDAD (
    especialidad_medica,
    cantidad_bonos,
    monto_perdida,
    fecha_bono_antiguo,
    estado_cobro
)
SELECT 
    ESPECIALIDAD_MEDICA.nombre AS especialidad_medica,
    COUNT(*) AS cantidad_bonos,
    SUM(BONO_CONSULTA.costo) AS monto_perdida,
    MIN(BONO_CONSULTA.fecha_bono) AS fecha_bono_antiguo,
    CASE 
        WHEN MAX(EXTRACT(YEAR FROM BONO_CONSULTA.fecha_bono)) >= EXTRACT(YEAR FROM SYSDATE) - 1 
        THEN 'COBRABLE'
        ELSE 'INCOBRABLE'
    END AS estado_cobro

FROM BONO_CONSULTA
INNER JOIN ESPECIALIDAD_MEDICA ON BONO_CONSULTA.esp_id = ESPECIALIDAD_MEDICA.esp_id

WHERE BONO_CONSULTA.id_bono NOT IN (
    SELECT PAGOS.id_bono 
    FROM PAGOS
    WHERE PAGOS.id_bono IS NOT NULL
)

GROUP BY ESPECIALIDAD_MEDICA.nombre;

COMMIT;
/

-- PASO 4: REPORTE FINAL (COMO FIGURA 4)
SELECT 
    especialidad_medica AS "ESPECIALIDAD MEDICA",
    cantidad_bonos AS "CANTIDAD BONOS",
    TO_CHAR(monto_perdida, '$999G999G990') AS "MONTO PERDIDA",
    TO_CHAR(fecha_bono_antiguo, 'DD-MM-YYYY') AS "FECHA BONO",
    estado_cobro AS "ESTADO DE COBRO"
FROM REPORTE_PERDIDAS_ESPECIALIDAD
ORDER BY monto_perdida DESC;
/

-- PASO 5: CONSULTA DIRECTA (SIN TABLA INTERMEDIA)
SELECT 
    ESPECIALIDAD_MEDICA.nombre AS "ESPECIALIDAD MEDICA",
    COUNT(*) AS "CANTIDAD BONOS",
    TO_CHAR(SUM(BONO_CONSULTA.costo), '$999G999G990') AS "MONTO PERDIDA",
    TO_CHAR(MIN(BONO_CONSULTA.fecha_bono), 'DD-MM-YYYY') AS "FECHA BONO",
    CASE 
        WHEN MAX(EXTRACT(YEAR FROM BONO_CONSULTA.fecha_bono)) >= EXTRACT(YEAR FROM SYSDATE) - 1 
        THEN 'COBRABLE'
        ELSE 'INCOBRABLE'
    END AS "ESTADO DE COBRO"
FROM BONO_CONSULTA
INNER JOIN ESPECIALIDAD_MEDICA ON BONO_CONSULTA.esp_id = ESPECIALIDAD_MEDICA.esp_id
WHERE BONO_CONSULTA.id_bono NOT IN (SELECT PAGOS.id_bono FROM PAGOS WHERE PAGOS.id_bono IS NOT NULL)
GROUP BY ESPECIALIDAD_MEDICA.nombre
ORDER BY SUM(BONO_CONSULTA.costo) DESC;

--- COMANDO FINAL:
SELECT * FROM REPORTE_PERDIDAS_ESPECIALIDAD ORDER BY monto_perdida DESC;




----CASO 3:----


-- ============================================================
-- CASO 3: TABLA CANT_BONOS_PACIENTES_ANNIO
-- REGISTRO DE BONOS POR PACIENTE (AÑO ACTUAL)
-- ============================================================

-- PASO 1: ELIMINAR TABLA SI EXISTE
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CANT_BONOS_PACIENTES_ANNIO';
    DBMS_OUTPUT.PUT_LINE('Tabla eliminada');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Creando tabla nueva...');
END;
/


-- Crear tabla con SISTEMA_SALUD de tamaño 50
CREATE TABLE CANT_BONOS_PACIENTES_ANNIO (
    ANNO_CALCULO        NUMBER(4)      NOT NULL,
    PAC_RUN             NUMBER(10)     NOT NULL,
    DV_RUN              VARCHAR2(2)    NOT NULL,
    EDAD                NUMBER(3)      NOT NULL,
    CANTIDAD_BONOS      NUMBER(10)     NOT NULL,
    MONTO_TOTAL_BONOS   NUMBER(12,2)   NOT NULL,
    SISTEMA_SALUD       VARCHAR2(50)   NOT NULL   -- ? Cambiado a 50
);

-- PASO 3: INSERTAR DATOS (AÑO ACTUAL)
INSERT INTO CANT_BONOS_PACIENTES_ANNIO (
    ANNO_CALCULO,
    PAC_RUN,
    DV_RUN,
    EDAD,
    CANTIDAD_BONOS,
    MONTO_TOTAL_BONOS,
    SISTEMA_SALUD
)
SELECT 
    EXTRACT(YEAR FROM SYSDATE) AS ANNO_CALCULO,
    PACIENTE.pac_run AS PAC_RUN,
    PACIENTE.dv_run AS DV_RUN,
    FLOOR(MONTHS_BETWEEN(SYSDATE, PACIENTE.fecha_nacimiento) / 12) AS EDAD,
    COUNT(BONO_CONSULTA.id_bono) AS CANTIDAD_BONOS,
    NVL(SUM(BONO_CONSULTA.costo), 0) AS MONTO_TOTAL_BONOS,
    SALUD.descripcion AS SISTEMA_SALUD

FROM PACIENTE
INNER JOIN SALUD ON PACIENTE.sal_id = SALUD.sal_id
LEFT JOIN BONO_CONSULTA ON PACIENTE.pac_run = BONO_CONSULTA.pac_run
    AND EXTRACT(YEAR FROM BONO_CONSULTA.fecha_bono) = EXTRACT(YEAR FROM SYSDATE)

GROUP BY 
    PACIENTE.pac_run,
    PACIENTE.dv_run,
    PACIENTE.fecha_nacimiento,
    SALUD.descripcion

ORDER BY PACIENTE.pac_run;

COMMIT;
/

-- PASO 4: MOSTRAR RESULTADO (COMO FIGURA 5)
SELECT 
    ANNO_CALCULO AS "ANNO_CALCULO",
    PAC_RUN AS "PAC_RUN",
    DV_RUN AS "DV_RUN",
    EDAD AS "EDAD",
    CANTIDAD_BONOS AS "CANTIDAD_BONOS",
    TO_CHAR(MONTO_TOTAL_BONOS, '999G999G990') AS "MONTO_TOTAL_BONOS",
    SISTEMA_SALUD AS "SISTEMA_SALUD"
FROM CANT_BONOS_PACIENTES_ANNIO
ORDER BY PAC_RUN;
/