-- ==============================================================================
-- FORMATIVA 4 CONSULTA DE BASE DE DATOS 
-- Caso de Estudio: Conciertos Chile S.A. 
-- ==============================================================================

-- ==============================================================================
-- CASO 1: Listado de Trabajadores
-- Sólo listar trabajadores cuyos sueldos estén entre $650.000 y $3.000.000
-- ==============================================================================

SELECT
    -- Nombre Completo Trabajador: 'NOMBRE APELLIDOPATERNO APELLIDOMATERNO' en formato en MAYÚSCULAS
    UPPER(T.nombre || ' ' || T.appaterno || ' ' || T.apmaterno) AS "Nombre Completo Trabajador",

    -- RUT Trabajador: CONCAT(NUMRUT, '-', DVRUT) con puntos para miles
   TRIM(TO_CHAR(T.numrut, 'FM99G999G999')) || '-' || T.dvrut AS "RUT Trabajador",

    -- Tipo Trabajador: Descripción en MAYÚSCULAS
    UPPER(TT.desc_categoria) AS "Tipo Trabajador",

    -- Ciudad Trabajador: Nombre de la ciudad en formato en MAYÚSCULAS
    UPPER(CC.nombre_ciudad) AS "Ciudad Trabajador",

    -- Sueldo Base: Formato Moneda (usando ROUND)
    TO_CHAR(
        ROUND(T.sueldo_base),
        '$9G999G999'
    ) AS "Sueldo Base"
FROM
    trabajador T
JOIN
    comuna_ciudad CC ON T.id_ciudad = CC.id_ciudad
JOIN
    tipo_trabajador TT ON T.id_categoria_t = TT.id_categoria
WHERE
    -- Restricción de datos: Sueldo Base entre $650.000 y $3.000.000
    T.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY
    -- Ordenamiento: Ciudad descendente, Sueldo Base ascendente
    "Ciudad Trabajador" DESC,
    T.sueldo_base ASC;


-- ==============================================================================
-- CASO 2: Listado de Cajeros
-- Sólo listar trabajadores con rol de CAJEROS, se requiere solo información de la suma de los montos de los tickets sea superior a $50.000
-- ==============================================================================
    
    SELECT
    -- RUT Trabajador: CONCAT(NUMRUT, '-', DVRUT) con puntos para miles
    TRIM(TO_CHAR(T.numrut, 'FM99G999G999')) || '-' || T.dvrut AS "RUT Trabajador",

    -- Nombre Trabajador: Nombre completo en formato Titulo INITCAP
    INITCAP(T.nombre) || ' ' || UPPER(T.appaterno) AS "Nombre Trabajador",

    -- Total Tickets: Cantidad de tickets vendidos (COUNT)
    COUNT(TC.nro_ticket) AS "Total Tickets",

    -- Total Vendido: Suma de montos de tickets (SUM) en formato Moneda
    TO_CHAR(
        ROUND(SUM(TC.monto_ticket)),
        '$9G999G999'
    ) AS "Total Vendido",

    -- Comisión Total: Suma de valores de comisión (SUM) en formato Moneda
    TO_CHAR(
        ROUND(SUM(CT.valor_comision)),
        '$9G999G999'
    ) AS "Comisión Total",

    -- Tipo Trabajador: Descripción en MAYÚSCULAS
    UPPER(TT.desc_categoria) AS "Tipo Trabajador",

    -- Ciudad Trabajador: Nombre de la ciudad en MAYÚSCULAS
    UPPER(CC.nombre_ciudad) AS "Ciudad Trabajador"
FROM
    trabajador T
JOIN
    tipo_trabajador TT ON T.id_categoria_t = TT.id_categoria
JOIN
    comuna_ciudad CC ON T.id_ciudad = CC.id_ciudad
JOIN
    tickets_concierto TC ON T.numrut = TC.numrut_t
JOIN
    comisiones_ticket CT ON TC.nro_ticket = CT.nro_ticket
WHERE
    -- Restricción de datos: Solo CAJERO
    UPPER(TT.desc_categoria) = 'CAJERO'
GROUP BY
    -- Agrupación de datos
    T.numrut, T.dvrut, T.nombre, T.appaterno, T.apmaterno, TT.desc_categoria, CC.nombre_ciudad
HAVING
    -- Restricción de grupos: Suma de montos de tickets superior a $50.000
    SUM(TC.monto_ticket) > 50000
ORDER BY
    -- Ordenamiento: Total Vendido descendente (usando la función de grupo)
    SUM(TC.monto_ticket) DESC;


-- ==============================================================================
-- CASO 3: Listado de Bonificaciones
-- Sólo considerar trabajadores que no tenga fecha de término el estado civil o que la fecha de término sea posterior a la fehca de ejecución del reporte
-- ==============================================================================


SELECT
    -- RUT Trabajador
    TRIM(TO_CHAR(T.numrut, 'FM99G999G999')) || '-' || T.dvrut AS "RUT Trabajador",

    -- Trabajador Nombre: Nombre completo en formato MAYUSCULAS
    INITCAP(T.nombre || ' ' || T.appaterno) AS "Trabajador Nombre",

    -- Año Ingreso: Usando función de fecha (TO_CHAR)
    TO_CHAR(T.fecing, 'YYYY') AS "Año Ingreso",

    -- Antigüedad: Diferencia de años (redondeado)
    ROUND(
        MONTHS_BETWEEN(SYSDATE, T.fecing) / 12
    ) AS "Antigüedad",

    -- Num. Cargas Familiares: Contar filas en ASIGNACION_FAMILIAR. Se usa COUNT(AF.numrut_carga) en un subquery/JOIN.
    NVL(AF.cantidad_cargas, 0) AS "Num. Cargas Familiares",

    -- Nombre Isapre: Nombre del sistema de salud en formato Título
    INITCAP(I.nombre_isapre) AS "Nombre Isapre",

    -- Sueldo Base: Formato de número sin símbolo de moneda
    TO_CHAR(
        ROUND(T.sueldo_base),
        'FM9G999G999'
    ) AS "Sueldo Base",

    -- Bono Isapre (1% si es FONASA, 0 si no)
    TO_CHAR(
        ROUND(
            CASE
                WHEN UPPER(I.nombre_isapre) = 'FONASA' THEN T.sueldo_base * 0.01
                ELSE 0
            END
        ),
        'FM9G999G999'
    ) AS "Bono Isapre",

    -- Bono Antigüedad (10% si <= 10 años, 15% si > 10 años)
    TO_CHAR(
        ROUND(
            CASE
                WHEN MONTHS_BETWEEN(SYSDATE, T.fecing) / 12 <= 10 THEN T.sueldo_base * 0.10
                ELSE T.sueldo_base * 0.15
            END
        ),
        'FM9G999G999'
    ) AS "Bono Antigüedad",

    -- Nombre AFP (columna según la Figura 4)
    INITCAP(A.nombre_afp) AS "Nombre AFP",
    
    -- Estado Civil: Descripción en MAYÚSCULAS
    UPPER(EC.desc_estcivil) AS "Estado Civil"

FROM
    trabajador T
JOIN
    isapre I ON T.cod_isapre = I.cod_isapre
JOIN
    afp A ON T.cod_afp = A.cod_afp
JOIN
    est_civil EST ON T.numrut = EST.numrut_t
JOIN
    estado_civil EC ON EST.id_estcivil_est = EC.id_estcivil
LEFT JOIN (
    -- Subconsulta para contar cargas familiares
    SELECT numrut_t, COUNT(numrut_carga) AS cantidad_cargas
    FROM asignacion_familiar
    GROUP BY numrut_t
) AF ON T.numrut = AF.numrut_t

WHERE
    -- Restricción: Estado Civil vigente (fecha de término NULA o posterior a la fecha actual)
    (
        EST.fecter_estcivil IS NULL
        OR EST.fecter_estcivil >= SYSDATE
    )
    -- Solo mostrar el estado civil MÁS RECIENTE, ya que la tabla est_civil puede tener múltiples filas por trabajador. 
    -- Se selecciona el estado civil con fecha de inicio MÁS RECIENTE que cumpla con la vigencia.
    AND EST.fecini_estcivil = (
        SELECT MAX(fecini_estcivil)
        FROM est_civil
        WHERE numrut_t = T.numrut
        AND (fecter_estcivil IS NULL OR fecter_estcivil >= SYSDATE)
    )

ORDER BY
    T.numrut ASC;


