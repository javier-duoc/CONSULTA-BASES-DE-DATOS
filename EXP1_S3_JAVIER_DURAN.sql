SELECT NRO_PROPIEDAD, DIRECCION_PROPIEDAD, NRO_DORMITORIOS, VALOR_ARRIENDO, ID_COMUNA,
VALOR_GASTO_COMUN AS GASTO_COMUN_ACTUAL, VALOR_GASTO_COMUN * 1.10 AS GASTO_COMUN_AJUSTADO,
(VALOR_GASTO_COMUN * 0.10) AS INCREMENTO,
VALOR_ARRIENDO + (VALOR_GASTO_COMUN + 1.10) AS TOTAL_A_PAGAR_AJUSTADO
FROM PROPIEDAD
WHERE VALOR_ARRIENDO < &IngreseValor
    And nro_dormitorios IS NOT NULL
ORDER BY VALOR_ARRIENDO ASC;


SELECT NRO_PROPIEDAD, FECINI_ARRIENDO AS FECHA_INICIO_ARRRIENDO, FECTER_ARRIENDO
AS FECHA_TERMINO_ARRIENDO

    CASE    
        WHEN fecini_arriendo IS NULL THEN 'Propiedad actualmente arrendada'
        ELSE TO CHAR (fecini_arriendo, 'DD/MM/YYYY')
    END AS ESTADO_TERMINO,
    --CALCULAR DIAS ARRENDADOS(HASTA FECHA ACTUAL)
    CASE
        WHEN fecter_arriendo IS NULL THEN TRUNC (SYSDATE - FECINI_ARRIENDO)
        ELSE TRUNC(FECTER_ARRIENDO - FECINI_ARRIENDO)
        END AS DIAS_ARRENDADOS,
        
    --CALCULAR AÑOS ARRENDADOS
    CASE 
        WHEN FECTER_ARRIENDO IS NULL THEN ROUND ((SYSDATE - FECINI_ARRIENDO) / 365.0)
        ELSE ROUND ((FECTER_ARRIENDO - FECINI_ARRIENDO) (365.0)
    END AS ANIOS_ARRENDADOS
        
--CLASIFICACION SEGUN AÑOS DE ARRIENDO

    CASE 
        WHEN (CASE WHEN FECTER_ARRIENDO IS NULL THEN (SYSDATE - FECINI_ARRIENDO) / 365
                    ELSE (FECTER_ARRIENDO - FECINI_ARRIENDO) /365 END) >= 10
        THEN 'COMPROMISO DE VENTA'
        WHEN (CASE WHEN (FECTER_ARRIENDO IS NULL THEN (SYSDATE- FECINI_ARRIENDO) 365
                    ELSE (FECTER_ARRIENDO - FECINI_ARRIENDO) / 365 END) BETWEEN 5 AND 9.99
        THEN 'CLIENTE ANTIGUO'
        ELSE 'CLIENTE NUEVO'
    END AS CLASIFICACION_CLIENTE
FROM ARRIENDO_PRIPIEDADES



    -- Clasificación según años de arriendo
    CASE 
        WHEN (CASE WHEN fecha_fin IS NULL THEN (SYSDATE - fecha_inicio) / 365
                   ELSE (fecha_fin - fecha_inicio) / 365 END) >= 10 
        THEN 'COMPROMISO DE VENTA'
        WHEN (CASE WHEN fecha_fin IS NULL THEN (SYSDATE - fecha_inicio) / 365
                   ELSE (fecha_fin - fecha_inicio) / 365 END) BETWEEN 5 AND 9.99 
        THEN 'CLIENTE ANTIGUO'
        ELSE 'CLIENTE NUEVO'
    END AS CLASIFICACION_CLIENTE
FROM ARRIENDO_PROPIEDADES 
INNER JOIN PROPIEDAD  ON nro_propiedad = nro_propiedad
INNER JOIN CLIENTE  ON celular_cli = celular_cli
INNER JOIN TIPO_PROPIEDAD ON id_tipo_propiedad = id_tipo_propiedad
WHERE fecha_inicio BETWEEN TO_DATE('&FECHA_INICIO', 'DD/MM/YYYY') 
                         AND TO_DATE('&FECHA_TERMINO', 'DD/MM/YYYY')
    AND (CASE WHEN fecter_arriendo IS NULL THEN TRUNC(SYSDATE - fecini_arriendo)
              ELSE TRUNC(fecter_arriendo - fecini_arriendo) END) >= &DIAS_MINIMOS
ORDER BY fecha_inicio ASC;

-- Definir variable para filtro por valor mínimo de arriendo promedio

SELECT 
    desc_tipo_propiedad AS TIPO_PROPIEDAD,
    -- Cantidad de propiedades
    COUNT(nro_propiedad) AS CANTIDAD_PROPIEDADES,
    -- Promedio valor arriendo (redondeado sin decimales)
    ROUND(AVG(valor_arriendo), 0) AS PROMEDIO_VALOR_ARRIENDO,
    -- Promedio valor gasto común (redondeado sin decimales)
    ROUND(AVG(valor_gasto_comun), 0) AS PROMEDIO_GASTO_COMUN,
    -- Formato especifico solicitado por el cliente (con separador de miles y formato moneda)
    TO_CHAR(ROUND(AVG(valor_arriendo), 0), 'FM$999,999,999') AS ARRIENDO_PROMEDIO_FORMATO,
    TO_CHAR(ROUND(AVG(valor_gasto_comun), 0), 'FM$999,999,999') AS GASTO_COMUN_PROMEDIO_FORMATO
FROM PROPIEDAD 
INNER JOIN TIPO_PROPIEDAD tp ON id_tipo_propiedad = tid_tipo_propiedad
WHERE valor_arriendo IS NOT NULL
GROUP BY desc_tipo_propiedad, id_tipo_propiedad
HAVING ROUND(AVG(valor_arriendo), 0) >= &PROMEDIO_MINIMO
ORDER BY desc_tipo_propiedad ASC;


