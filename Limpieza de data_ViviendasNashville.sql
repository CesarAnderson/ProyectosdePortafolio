-- Limpieza de Datos en Consultas SQL
-----------------------------------------------------------------------

SELECT *
FROM PortafolioSQL.dbo.ViviendasNashville

-----------------------------------------------------------------------
-- Estandarizar Formato de Fecha

ALTER TABLE PortafolioSQL.dbo.ViviendasNashville
ADD FechaVentaActualizada Date;

UPDATE PortafolioSQL.dbo.ViviendasNashville
SET FechaVentaActualizada = CONVERT(Date,FechaVenta)

SELECT FechaVentaActualizada, FechaVenta
FROM PortafolioSQL.dbo.ViviendasNashville

-----------------------------------------------------------------------
-- Poblar Datos de Dirección de Propiedad

SELECT *
FROM PortafolioSQL.dbo.ViviendasNashville
ORDER BY IDParcela

SELECT a.IDParcela, a.DireccionPropiedad, b.IDParcela, b.DireccionPropiedad, ISNULL(a.DireccionPropiedad,b.DireccionPropiedad)
FROM PortafolioSQL.dbo.ViviendasNashville a
JOIN PortafolioSQL.dbo.ViviendasNashville b
	ON a.IDParcela = b.IDParcela
	AND a.[IDUnico ] <> b.[IDUnico ]
WHERE a.DireccionPropiedad IS NULL

UPDATE a
SET DireccionPropiedad = ISNULL(a.DireccionPropiedad,b.DireccionPropiedad)
FROM PortafolioSQL.dbo.ViviendasNashville a
JOIN PortafolioSQL.dbo.ViviendasNashville b
	ON a.IDParcela = b.IDParcela
	AND a.[IDUnico ] <> b.[IDUnico ]
WHERE a.DireccionPropiedad IS NULL

SELECT DireccionPropiedad
FROM PortafolioSQL.dbo.ViviendasNashville
WHERE DireccionPropiedad IS NULL

-------------------------------------------------------------------------
-- Dividir la Dirección Completa en Columnas Individuales (Dirección, Ciudad, Estado)

--Dirección de la Propiedad

SELECT DireccionPropiedad
FROM PortafolioSQL.dbo.ViviendasNashville

ALTER TABLE PortafolioSQL.dbo.ViviendasNashville
ADD CalleDireccionPropiedad NVARCHAR(255);

UPDATE PortafolioSQL.dbo.ViviendasNashville
SET CalleDireccionPropiedad = SUBSTRING(DireccionPropiedad, 1, CHARINDEX(',', DireccionPropiedad)-1) 


ALTER TABLE PortafolioSQL.dbo.ViviendasNashville
ADD CiudadDireccionPropiedad NVARCHAR(255);

UPDATE PortafolioSQL.dbo.ViviendasNashville
SET CiudadDireccionPropiedad = SUBSTRING(DireccionPropiedad, CHARINDEX(',', DireccionPropiedad) +1 , LEN(DireccionPropiedad)) 

SELECT CalleDireccionPropiedad, CiudadDireccionPropiedad
FROM PortafolioSQL.dbo.ViviendasNashville

-- Dirección del Propietario

SELECT DireccionPropietario
FROM PortafolioSQL.dbo.ViviendasNashville

ALTER TABLE PortafolioSQL.dbo.ViviendasNashville
ADD CalleDireccionPropietario NVARCHAR(255);

UPDATE PortafolioSQL.dbo.ViviendasNashville
SET CalleDireccionPropietario = PARSENAME(REPLACE(DireccionPropietario, ',', '.') , 3)

ALTER TABLE PortafolioSQL.dbo.ViviendasNashville
ADD CiudadDireccionPropietario NVARCHAR(255);

UPDATE PortafolioSQL.dbo.ViviendasNashville
SET CiudadDireccionPropietario = PARSENAME(REPLACE(DireccionPropietario, ',', '.') , 2)

ALTER TABLE PortafolioSQL.dbo.ViviendasNashville
ADD EstadoDireccionPropietario NVARCHAR(255);

UPDATE PortafolioSQL.dbo.ViviendasNashville
SET EstadoDireccionPropietario = PARSENAME(REPLACE(DireccionPropietario, ',', '.') , 1)

------------------------------------------------------------------------------
-- Cambiar "Y" por "Sí" y "N" por "No" en el campo "Vendido como Vacante"

SELECT DISTINCT VendidoComoVacante
FROM PortafolioSQL.dbo.ViviendasNashville

UPDATE PortafolioSQL.dbo.ViviendasNashville
SET VendidoComoVacante = CASE WHEN VendidoComoVacante = 'Y' THEN 'Sí'
	WHEN VendidoComoVacante = 'N' THEN 'No'
	ELSE VendidoComoVacante
	END

-------------------------------------------------------------------------------
-- Eliminar Duplicados

WITH CTERowNum AS(
SELECT *,
   ROW_NUMBER() OVER (
   PARTITION BY IDParcela,
                DireccionPropiedad,
				PrecioVenta,
				FechaVenta,
				ReferenciaLegal
				ORDER BY
				   IDUnico
				   ) num_fila

FROM PortafolioSQL.dbo.ViviendasNashville
)
--SELECT *
DELETE
FROM CTERowNum
WHERE num_fila > 1
--ORDER BY DireccionPropiedad

---------------------------------------------------------------
-- Eliminar Columnas No Utilizadas

SELECT *
FROM PortafolioSQL.dbo.ViviendasNashville

ALTER TABLE PortafolioSQL.dbo.ViviendasNashville
DROP COLUMN FechaVenta, DireccionPropietario, DistritoFiscal, DireccionPropiedad
