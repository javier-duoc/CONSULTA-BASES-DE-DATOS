-- 1. SINÓNIMO PÚBLICO (para tabla de uso masivo)
CREATE PUBLIC SYNONYM syn_bono_consulta FOR PRY2205_USER1.BONO_CONSULTA;
CREATE PUBLIC SYNONYM syn_paciente FOR PRY2205_USER1.PACIENTE;

-- 2. SINÓNIMO PRIVADO (para un usuario específico, ejemplo: USR2_MEDICO)
-- Conectado como USR2_MEDICO:
CREATE SYNONYM mis_bonos FOR PRY2205_USER1.BONO_CONSULTA;
CREATE SYNONYM mis_pacientes FOR PRY2205_USER1.PACIENTE;

CREATE OR REPLACE VIEW VISTA_REAJUSTE_CONSULTAS AS
SELECT 
    id_bono,
    fecha_bono,
    hr_consulta,
    costo AS costo_original,
    pac_run,
    pnombre || ' ' || p.apaterno AS nombre_paciente,
    descripcion AS sistema_salud,
    -- Cálculo del nuevo costo con reajuste (REDONDEADO A ENTERO)
    ROUND(
        CASE 
            WHEN costo BETWEEN 15000 AND 25000 THEN costo * 1.15
            WHEN costo > 25000 THEN costo * 1.20
            ELSE costo
        END
    ) AS costo_reajustado,
    -- Porcentaje aplicado
    CASE 
        WHEN costo BETWEEN 15000 AND 25000 THEN 15
        WHEN costo > 25000 THEN 20
        ELSE 0
    END AS porcentaje_reajuste
FROM BONO_CONSULTA 
JOIN PACIENTE  ON pac_run =pac_run
JOIN SALUD  ON sal_id = sal_id
JOIN SISTEMA_SALUD  ON tipo_sal_id = tipo_sal_id
WHERE 
    -- Horario: después de las 17:15
    TO_NUMBER(SUBSTR(hr_consulta, 1, 2)) * 60 + TO_NUMBER(SUBSTR(hr_consulta, 4, 2)) > 17*60 + 15
    -- Año anterior al año actual (paramétrico, sin fechas fijas)
    AND EXTRACT(YEAR FROM fecha_bono) = EXTRACT(YEAR FROM SYSDATE) - 1
    -- Solo ISAPRE o FONASA
    AND UPPER(descripcion) IN ('ISAPRE', 'FONASA');
    
--Consulta de prueba para la vista.
-- Ver resultados de la vista
SELECT * FROM VISTA_REAJUSTE_CONSULTAS ORDER BY fecha_bono DESC;

-- Resumen del reajuste aplicado
SELECT 
    sistema_salud,
    COUNT(*) AS total_consultas,
    SUM(costo_original) AS suma_original,
    SUM(costo_reajustado) AS suma_reajustada,
    ROUND(AVG(porcentaje_reajuste)) AS promedio_reajuste
FROM VISTA_REAJUSTE_CONSULTAS
GROUP BY sistema_salud;

-- Solo ciertos usuarios pueden ver la vista con reajustes
GRANT SELECT ON PRY2205_USER1.VISTA_REAJUSTE_CONSULTAS TO rol_gerente;
GRANT SELECT ON PRY2205_USER1.VISTA_REAJUSTE_CONSULTAS TO rol_analista;

-- Los médicos NO deben ver esta vista (no es su función)
-- Los recepcionistas NO deben ver esta vista