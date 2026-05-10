---USUARIO PRY2205_EFT
SHOW USER;

--CREACION Y POBLAMIENTO

--CASO 2 
WITH 
-- 1. Deudores que NO son Ingeniero (por su ocupación)
deudores_no_ingeniero AS (
    SELECT d.numrun, d.dvrun, d.pnombre, d.snombre, d.appaterno, d.apmaterno,
           d.fono_contacto, o.nombre_prof_ofic
    FROM deudor d
    JOIN ocupacion o ON d.cod_ocupacion = o.cod_ocupacion
    WHERE UPPER(o.nombre_prof_ofic) != 'INGENIERO COMERCIAL'
      AND UPPER(o.nombre_prof_ofic) NOT LIKE '%INGENIER%'
),

-- 2. Promedio de valor de cuotas por tarjeta (de todas las tarjetas)
promedio_por_tarjeta AS (
    SELECT ct.nro_tarjeta, AVG(ct.valor_cuota) AS promedio_tarjeta
    FROM cuota_tarjetas ct
    GROUP BY ct.nro_tarjeta
),

-- 3. Máximo de todos los promedios de cuotas
max_promedio_general AS (
    SELECT MAX(promedio_tarjeta) AS max_promedio
    FROM promedio_por_tarjeta
),

-- 4. Datos de cuotas por deudor y tarjeta (para el año anterior)
cuotas_ano_anterior AS (
    SELECT 
        td.nro_tarjeta,
        td.numrun,
        ct.nro_cuota,
        ct.valor_cuota,
        ct.fecha_venc_cuota
    FROM tarjeta_deudor td
    JOIN cuota_tarjetas ct ON td.nro_tarjeta = ct.nro_tarjeta
    WHERE EXTRACT(YEAR FROM ct.fecha_venc_cuota) = EXTRACT(YEAR FROM SYSDATE) - 1
),

-- 5. Agregación por deudor y tarjeta
resumen_deudor_tarjeta AS (
    SELECT 
        d.numrun,
        d.dvrun,
        d.pnombre,
        d.snombre,
        d.appaterno,
        d.apmaterno,
        d.fono_contacto,
        o.nombre_prof_ofic AS ocupacion,
        td.nro_tarjeta,
        COUNT(DISTINCT ct.nro_cuota) AS total_cuotas,
        ROUND(AVG(ct.valor_cuota)) AS promedio_valor_cuotas,
        MIN(ct.fecha_venc_cuota) AS fecha_mas_antigua,
        td.cupo_disp_compra
    FROM deudor d
    JOIN tarjeta_deudor td ON d.numrun = td.numrun
    JOIN cuota_tarjetas ct ON td.nro_tarjeta = ct.nro_tarjeta
    JOIN ocupacion o ON d.cod_ocupacion = o.cod_ocupacion
    WHERE d.numrun IN (SELECT numrun FROM deudores_no_ingeniero)
    GROUP BY d.numrun, d.dvrun, d.pnombre, d.snombre, d.appaterno, d.apmaterno,
             d.fono_contacto, o.nombre_prof_ofic, td.nro_tarjeta, td.cupo_disp_compra
)

-- 6. Consulta final con filtro de promedio < máximo general
SELECT 
    -- RUT completo con guion: numrun + dvrun
    TO_CHAR(rdt.numrun) || '-' || rdt.dvrun AS Rut_deudor,
    
    -- Nombre completo: primer nombre + apellido paterno + apellido materno (con inicial mayúscula)
    INITCAP(rdt.pnombre) || ' ' || 
    NVL(INITCAP(rdt.snombre) || ' ', '') || 
    INITCAP(rdt.appaterno) || ' ' || 
    INITCAP(rdt.apmaterno) AS Nombre_deudor,
    
    rdt.total_cuotas AS Total_cuotas,
    rdt.promedio_valor_cuotas AS Promedio_valor_cuotas,
    
    -- Fecha en formato dd/mm/yyyy
    TO_CHAR(rdt.fecha_mas_antigua, 'dd/mm/yyyy') AS Fecha_mas_antigua,
    
    -- Teléfono: si es NULL mostrar "Sin Información"
    NVL(TO_CHAR(rdt.fono_contacto), 'Sin Información') AS Telefono,
    
    -- Ocupación en mayúsculas
    UPPER(rdt.ocupacion) AS Ocupacion,
    
    -- Cupo disponible para compra
    rdt.cupo_disp_compra AS Cupo_disp_compra

FROM resumen_deudor_tarjeta rdt
CROSS JOIN max_promedio_general mpg
WHERE rdt.promedio_valor_cuotas < mpg.max_promedio
ORDER BY rdt.numrun, rdt.nro_tarjeta;
-----------------------------------------------------------------------------

-- CREACION DE SINONIMO
CREATE PUBLIC SYNONYM SYN_VW_ANALISIS_DEUDORES_PERIODO FOR SUCURSAL

--OTORGAR PERMISOS
--GRANT SELECT ON SYN_VW_ANALISIS_DEUDORES_PERIODO TO PRY2205_ROL_D;
--REVOKE SELECT ON SYN_VW_ANALISIS_DEUDORES_PERIODO FROM PRY2205_ROL_D;
GRANT SELECT ON SYN_VW_ANALISIS_DEUDORES_PERIODO TO PRY2205_EFT_DES;

GRANT SELECT ON SYN_VW_ANALISIS_DEUDORES_PERIODO TO PRY2205_EFT_DES
    WITH GRANT OPTION;
    
    
---CASO 3.1


-- 1. Insertamos los registros calculados
INSERT INTO T_ANALISIS_TARJETAS (
    NUM_ANALISIS,
    NRO_TARJETA,
    TOTAL_CUOTAS,
    MONTO_TOTAL_TRANSA,
    FECHA_TRANSACCION,
    DIRECCION,
    MONTO_REAJUSTADO
)
SELECT 
    SEQ_T_ANALISIS.NEXTVAL AS NUM_ANALISIS,
    ttd.nro_tarjeta,
    ttd.total_cuotas_transaccion AS TOTAL_CUOTAS,
    ttd.monto_total_transaccion AS MONTO_TOTAL_TRANSA,
    -- Fecha en formato dd/mm/yyyy (Figura 3)
    TO_CHAR(ttd.fecha_transaccion, 'dd/mm/yyyy') AS FECHA_TRANSACCION,
    -- Dirección con iniciales en mayúscula
    INITCAP(s.direccion) AS DIRECCION,
    -- Monto reajustado según reglas de negocio
    ROUND(
        ttd.monto_total_transaccion * 
        (1 + 
            CASE 
                WHEN ttd.monto_total_transaccion BETWEEN 200000 AND 300000 THEN 0.05
                WHEN ttd.monto_total_transaccion BETWEEN 300001 AND 500000 THEN 0.07
                ELSE 0
            END
        )
    ) AS MONTO_REAJUSTADO
FROM 
    transaccion_tarjeta_deudor ttd
    JOIN sucursal s ON ttd.id_sucursal = s.id_sucursal
WHERE 
    -- Dirección de sucursal comienza con 'A' (case insensitive)
    UPPER(SUBSTR(s.direccion, 1, 1)) = 'A'
    -- Monto total transacción >= 200.000
    AND ttd.monto_total_transaccion >= 200000;
-- 3. Confirmar la inserción
COMMIT;

-- 4. Verificar el resultado
SELECT * FROM T_ANALISIS_TARJETAS ORDER BY NUM_ANALISIS;

---------------------------------
GRANT SELECT ON T_ANALISIS_TARJETAS TO PRY2205_EFT_CON
CREATE PUBLIC SYNONYM T_ANALISIS_TARJETAS  FOR SUCURSAL







