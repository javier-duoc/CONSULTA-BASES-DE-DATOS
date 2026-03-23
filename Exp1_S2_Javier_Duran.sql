SELECT 
    NUMFACTURA AS "N° Factura",
    TO_CHAR (FECHA, 'dd "de" MONTH "" yyyy') AS "fecha Emision",
    LPAD (RUTCLIENTE,10,'0') AS "Rut Cliente",
    
    TO_CHAR(NETO, '$999,999') AS "Monto Neto",
    TO_CHAR (IVA, '$999,999') AS "Monto IVA",
    TO_CHAR (TOTAL, '$999,999') AS "Total FACTURA",
    
    --Categoria Monto
    (CASE
        WHEN TOTAL < 50000 THEN 'bajo'
        WHEN TOTAL BETWEEN 5001 AND 10000 THEN 'Medio'
        ELSE 'Alto'
    END) AS "Categoria Monto",
    
    
    --Forma de pago
    
    (CASE CODPAGO
        WHEN 1 THEN 'EFECTIVO'
        WHEN 2 THEN 'TARJETA DEBITO'
        WHEN 3 THEN 'TARJETA CREDITO'
        ELSE 'CHEQUE'
    END) AS "Forma de pago"
    
    FROM
        FACTURA
    WHERE 
        --fecha solo anterior al año actual
        EXTRACT (YEAR FROM FECHA) = EXTRACT (YEAR FROM SYSDATE) - 1
    ORDER BY
        FECHA DESC, NETO DESC;
        
        
--CASO 2: Clasificacion de Clientes

SELECT 
    LPAD (RUTCLIENTE,12,'*') AS "RUT",
    NOMBRE AS "Cliente",
    NVL (TO_CHAR(TELEFONO), 'Sin telefono') AS "Telefono",
    NVL(TO_CHAR(CODCOMUNA), 'Sin comuna') AS "Comuna",
    ESTADO AS "Estado",
    
    --Estado Credito
    (CASE 
        WHEN SALDO/CREDITO <0.5 THEN 'Bueno' || '(' || TO_CHAR ( CREDITO - SALDO, '$9,999,999') || ')'
        WHEN SALDO/CREDITO BETWEEN 0.5 AND 0.8 THEN 'Regular' || '(' || TO_CHAR ( SALDO, '$9,999,999') || ')'
        ELSE 'Critico'
    END) AS "Estado Credito",
    
    NVL( SUBSTR(MAIL,INSTR(MAIL,'@')+1), 'Correo no registrado') AS "Dominio Correo"
    
    FROM 
        CLIENTE
    WHERE
        ESTADO = 'A' AND CREDITO > 0
    ORDER BY
        NOMBRE;
        
        --Caso 3 Stock de productos.
    
    SELECT 
        CODPRODUCTOS AS "ID",
        DESCRIPCION AS "Descripcion del Producto",
    -- No se ve opcion "Sin registro"
        NVL (TO_CHAR(VALORCOMPRADOLAR) || ' USD', 'Sin Registro') AS "Compra en USD",
        NVL( TO_CHAR( TRUNC( VALORCOMPRADOLAR*&&TIPOCAMBIO_DOLAR ), '$999,999') || ' PESOS' , 'Sin Registro') AS "USD Convertido",
 TOTALSTOCK AS "Stock",

 --Alerta Stock
 (CASE
 WHEN TOTALSTOCK IS NULL THEN 'Sin datos'
 WHEN TOTALSTOCK < &&UMBRAL_BAJO THEN '¡ALERTA stock muy bajo!'
 WHEN TOTALSTOCK BETWEEN &UMBRAL_BAJO AND &&UMBRAL_ALTO THEN '¡Reabastecer pronto!'
 ELSE 'OK'
 END) AS "Alerta Stock",

 --Precio Oferta
 --no pude obtener los resultados que aparecian en la tabla de ejemplo, lo deje asi:
 (CASE
 WHEN TOTALSTOCK > 80 THEN TO_CHAR( TRUNC( VALORCOMPRADOLAR*&TIPOCAMBIO_DOLAR ) * 0.1 , '$999,999')
 ELSE 'N/A'
 END) AS "Precio Oferta"
FROM
 PRODUCTO
WHERE
 DESCRIPCION LIKE '%ZAPATO%' AND PROCEDENCIA = 'I'
ORDER BY
 CODPRODUCTO DESC, DESCRIPCION DESC;
        
        
    
    
    
        
        
        
        
    
    
    