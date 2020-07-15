-- =====================================================================================================================
--  Fecha......: 2020-07-12
--  Autor......: L.I. Ricardo Carrillo Morales        
--  Motor......: MS SQL Server
--  Descripción: Buscar la definición de desglose para un artículo por tienda
--  Notas......:
-- =====================================================================================================================

DECLARE
  @StoreNumber    VARCHAR(50),
  @ItemCode       VARCHAR(50),
  @ItemID         INT,
  @ItemUnitID     INT,
  @RecordStatusID INT,
  @ID1            INT,
  @ID2            INT,
  @ID3            INT,
  @StoreID        INT,
  @StockUnitID    INT,
  @Issues         VARCHAR(MAX);

-- ---------------------------------------------------------------------------------------------------------------------
-- Criterios de búsqueda
-- ---------------------------------------------------------------------------------------------------------------------
SET @ItemCode='52975';
SET @StoreNumber='397';


-- =====================================================================================================================
-- Buscar los datos
-- =====================================================================================================================

-- Buscar el inventario de la primer serie del artículo
SELECT
  @ItemID        =i.ID,
  @ItemUnitID    =i.UnitID,
  @RecordStatusID=iohd.RecordStatusID,
  @StockUnitID   =CASE WHEN iohud.UnitID IS NULL THEN i.SaleUnitID ELSE iohud.UnitID END,
  @StoreID       =s.ID
FROM Item i WITH (NOLOCK)
  LEFT JOIN InventoryOnHand             ioh WITH (NOLOCK) ON ioh.ItemID=i.ID
  LEFT JOIN InventoryOnHandUnitDetail iohud WITH (NOLOCK) ON iohud.InventoryOnHandUUID=ioh.UUID AND iohud.QuantityItemUnit>0
  LEFT JOIN InventoryOnHandDetail      iohd WITH (NOLOCK) ON iohd.UUID=iohud.InventoryOnHandDetailUUID
  LEFT JOIN Store                         s WITH (NOLOCK) ON s.ID=ioh.StoreID AND s.Number=@StoreNumber
WHERE i.Code=@ItemCode;

-- Registro 1. Buscar el producto con la unidad de la serie y que permita desglose
-- Registro 2. El padre del Registro 1
SELECT
  @ID1=iuc.ID,
  @ID2=iuc.TargetUnitConversionParentID
FROM ItemUnitConversion iuc WITH (NOLOCK)
WHERE iuc.ItemID=@ItemID
  AND iuc.UnitID=@StockUnitID
  AND AllowsConversion=1;

-- Registro 3. Padre del Registro 2
SELECT
  @ID3=iuc.TargetUnitConversionParentID
FROM ItemUnitConversion iuc WITH (NOLOCK)
WHERE ID=@ID2;

-- Mostrar los registros del desglose
SELECT
  sq.RowID,
  CASE
    WHEN sq.RowID=1 AND sq.ID IS NULL THEN
      'No se encontró una conversión de unidad para el artículo que desea desglosar'
    WHEN sq.RowID=2 AND sq.ID IS NULL THEN
      'La conversión de unidades no tiene configurado el artículo destino'
    WHEN sq.RowID IN (1, 2) AND i.ToSale<>1 THEN
      'El artículo no está a la venta'
    WHEN sq.RowID=1 AND COALESCE(sq.TargetUnitConversionParentID, 0)=0 THEN
      'La conversión de unidades no tiene configurado el artículo destino'
    WHEN sq.RowID=2 AND i.UnitID<>@ItemUnitID THEN
      'La unidad base de los productos origen y destino no son iguales'
    WHEN sq.RowID=2 AND @RecordStatusID NOT IN (0, 1) THEN
      'El código de producto ya no está activo'
    WHEN s.UseStoreItem=1 AND si.ItemID IS NULL THEN
      'No está en portafolio'
    WHEN s.UseStoreItem=1 AND si.RecordStatusID=2 THEN
      'Eliminado de portafolio'
    ELSE ''
  END AS Issues,
  sq.ID,
  CONCAT(i.Code, ' ', i.Description) AS Item,
  CONCAT(COALESCE(ti.Code, ''), ' ', COALESCE(ti.Description, '')) AS TargetItem,
  CONCAT(u.Name, CASE WHEN tu.Name IS NOT NULL THEN CONCAT(' -> ', tu.Name) ELSE '' END) AS TargetUnit,
  sq.IsVariableFactor,
  sq.MinVariableFactor,
  sq.Factor,
  sq.AllowsConversion
FROM
  (
    SELECT * FROM (SELECT 1 AS RowID) sq LEFT JOIN ItemUnitConversion iuc WITH (NOLOCK) ON iuc.ID=@ID1
      UNION ALL
    SELECT * FROM (SELECT 2 AS RowID) sq LEFT JOIN ItemUnitConversion iuc WITH (NOLOCK) ON iuc.ID=@ID2
      UNION ALL
    SELECT * FROM (SELECT 3 AS RowID) sq LEFT JOIN ItemUnitConversion iuc WITH (NOLOCK) ON iuc.ID=@ID3
  ) sq
  LEFT JOIN Item       i WITH (NOLOCK) ON i.ID=sq.ItemID
  LEFT JOIN Item      ti WITH (NOLOCK) ON ti.ID=sq.TargetItemID
  LEFT JOIN Unit       u WITH (NOLOCK) ON u.ID=sq.UnitID
  LEFT JOIN Unit      tu WITH (NOLOCK) ON tu.ID=sq.TargetUnitID
  LEFT JOIN Store      s WITH (NOLOCK) ON s.ID=@StoreID
  LEFT JOIN StoreItem si WITH (NOLOCK) ON si.StoreID=s.ID AND si.ItemID=sq.ItemID;