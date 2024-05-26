/*
Exploración de Datos de Covid 19

Habilidades utilizadas: Joins, CTE's, Tablas Temporales, Funciones de Ventana, Funciones de Agregación, Creación de Vistas, Conversión de Tipos de Datos
*/

-- Exploración inicial de los datos
SELECT *
FROM ProyectoPortafolio..MuertesCovid
WHERE continente IS NOT NULL 
ORDER BY 3, 4;

-- Seleccionando los datos con los que vamos a empezar
SELECT ubicacion, fecha, total_casos, nuevos_casos, total_muertes, poblacion
FROM ProyectoPortafolio..MuertesCovid
WHERE continente IS NOT NULL
ORDER BY 1, 2;

-- Mirando el total de casos frente a total de muertes
-- Muestra la probabilidad de morir si contraes covid en mi país
SELECT ubicacion, fecha, total_casos, total_muertes, ROUND((total_muertes / total_casos) * 100, 2) AS PorcentajeMuerte
FROM ProyectoPortafolio..MuertesCovid
WHERE ubicacion = 'Peru'
ORDER BY 1, 2;

-- Total de casos frente a población
-- Muestra qué porcentaje de la población contrajo Covid
SELECT ubicacion, fecha, total_casos, poblacion, ROUND((total_casos / poblacion) * 100, 5) AS CasosPorPoblacion
FROM ProyectoPortafolio..MuertesCovid
-- WHERE ubicacion = 'Peru'
ORDER BY 1, 2;

-- Países con la tasa de infección más alta en comparación con la población
SELECT ubicacion, poblacion, MAX(total_casos) AS ConteoMaximoInfeccion, ROUND(MAX((total_casos / poblacion)) * 100, 2) AS PorcentajePoblacionInfectada
FROM ProyectoPortafolio..MuertesCovid
GROUP BY ubicacion, poblacion
ORDER BY PorcentajePoblacionInfectada DESC;

-- Países con el mayor conteo de muertes por población
SELECT ubicacion, MAX(CAST(total_muertes AS int)) AS ConteoTotalMuertes
FROM ProyectoPortafolio..MuertesCovid
WHERE continente IS NOT NULL
GROUP BY ubicacion
ORDER BY ConteoTotalMuertes DESC;

-- Desglosando por continente

-- Continentes con el mayor conteo de muertes por población
SELECT continente, MAX(CAST(total_muertes AS int)) AS ConteoTotalMuertes
FROM ProyectoPortafolio..MuertesCovid
WHERE continente IS NOT NULL
GROUP BY continente
ORDER BY ConteoTotalMuertes DESC;

-- Números globales por fecha
SELECT fecha, SUM(nuevos_casos) AS CasosTotales, SUM(CAST(nuevas_muertes AS int)) AS MuertesTotales, ROUND((SUM(CAST(nuevas_muertes AS int)) / SUM(nuevos_casos)) * 100, 2) AS PorcentajeMuerte
FROM ProyectoPortafolio..MuertesCovid
WHERE continente IS NOT NULL
GROUP BY fecha
ORDER BY 1, 2;

-- Números globales en general
SELECT SUM(nuevos_casos) AS CasosTotales, SUM(CAST(nuevas_muertes AS int)) AS MuertesTotales, ROUND((SUM(CAST(nuevas_muertes AS int)) / SUM(nuevos_casos)) * 100, 2) AS PorcentajeMuerte
FROM ProyectoPortafolio..MuertesCovid
WHERE continente IS NOT NULL
ORDER BY 1, 2;

-- Población total vs vacunaciones
-- Porcentaje de la población que ha recibido al menos una vacuna Covid
SELECT 
    muertes.continente, 
    muertes.ubicacion, 
    muertes.fecha, 
    muertes.poblacion, 
    vacunas.nuevas_vacunaciones, 
    SUM(CONVERT(int, vacunas.nuevas_vacunaciones)) OVER (
        PARTITION BY muertes.ubicacion 
        ORDER BY muertes.ubicacion, muertes.fecha
    ) AS PersonasVacunadasAcumuladas
FROM 
    ProyectoPortafolio..MuertesCovid muertes
JOIN 
    ProyectoPortafolio..VacunacionesCovid vacunas
    ON muertes.ubicacion = vacunas.ubicacion
    AND muertes.fecha = vacunas.fecha
WHERE 
    muertes.continente IS NOT NULL
ORDER BY 
    2, 3;


-- Usando CTE para realizar cálculo en partition by de la consulta anterior
WITH PoblacionVsVacunaciones AS (
    SELECT 
        muertes.continente, 
        muertes.ubicacion, 
        muertes.fecha, 
        muertes.poblacion, 
        vacunas.nuevas_vacunaciones, 
        SUM(CONVERT(int, vacunas.nuevas_vacunaciones)) OVER (
            PARTITION BY muertes.ubicacion 
            ORDER BY muertes.ubicacion, muertes.fecha
        ) AS PersonasVacunadasAcumuladas
    FROM 
        ProyectoPortafolio..MuertesCovid muertes
    JOIN 
        ProyectoPortafolio..VacunacionesCovid vacunas
        ON muertes.ubicacion = vacunas.ubicacion
        AND muertes.fecha = vacunas.fecha
    WHERE 
        muertes.continente IS NOT NULL
)
SELECT 
    *, 
    ROUND((PersonasVacunadasAcumuladas / Poblacion) * 100, 2) AS PorcentajeAcumulado
FROM 
    PoblacionVsVacunaciones;


-- Usando tabla temporal para realizar cálculo en partition by de la consulta anterior

DROP TABLE IF EXISTS #PorcentajePoblacionVacunada;

CREATE TABLE #PorcentajePoblacionVacunada (
    Continente NVARCHAR(255),
    Ubicacion NVARCHAR(255), 
    Fecha DATETIME, 
    Poblacion NUMERIC, 
    Nuevas_Vacunaciones NUMERIC, 
    PersonasVacunadasAcumuladas NUMERIC
);
INSERT INTO #PorcentajePoblacionVacunada
SELECT 
    muertes.continente, 
    muertes.ubicacion, 
    muertes.fecha, 
    muertes.poblacion, 
    vacunas.nuevas_vacunaciones, 
    SUM(CONVERT(int, vacunas.nuevas_vacunaciones)) OVER (
        PARTITION BY muertes.ubicacion 
        ORDER BY muertes.ubicacion, muertes.fecha
    ) AS PersonasVacunadasAcumuladas
FROM 
    ProyectoPortafolio..MuertesCovid muertes
JOIN 
    ProyectoPortafolio..VacunacionesCovid vacunas
    ON muertes.ubicacion = vacunas.ubicacion
    AND muertes.fecha = vacunas.fecha
WHERE 
    muertes.continente IS NOT NULL;

SELECT 
    *, 
    ROUND((PersonasVacunadasAcumuladas / Poblacion) * 100, 2) AS PorcentajeAcumulado
FROM 
    #PorcentajePoblacionVacunada;

-- Creando vista para almacenar datos para visualizaciones posteriores

CREATE VIEW PorcentajePoblacionVacunada AS
SELECT 
    muertes.continente, 
    muertes.ubicacion, 
    muertes.fecha, 
    muertes.poblacion, 
    vacunas.nuevas_vacunaciones, 
    SUM(CONVERT(int, vacunas.nuevas_vacunaciones)) OVER (
        PARTITION BY muertes.ubicacion 
        ORDER BY muertes.ubicacion, muertes.fecha
    ) AS PersonasVacunadasAcumuladas
FROM 
    ProyectoPortafolio..MuertesCovid muertes
JOIN 
    ProyectoPortafolio..VacunacionesCovid vacunas
    ON muertes.ubicacion = vacunas.ubicacion
    AND muertes.fecha = vacunas.fecha
WHERE 
    muertes.continente IS NOT NULL;
