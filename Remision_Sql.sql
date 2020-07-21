-- =====================================================================================================================
--  Fecha......: 2019-12-16
--  Autor......: L.I. Ricardo Carrillo Morales        
--  Motor......: MS SQL Server
--  Descripción: Buscar una orden
--  Notas......:
-- =====================================================================================================================

DECLARE
  @Folio VARCHAR(100),
  @idoUUID CHAR(36),
  @StoreNumber VARCHAR(20),
  @TargetStoreNumber VARCHAR(20),
  @FromDate DATETIME;


-- ---------------------------------------------------------------------------------------------------------------------
-- Criterios de búsqueda
-- ---------------------------------------------------------------------------------------------------------------------
 SET @Folio='18229';
-- SET @idoUUID='CDCED6E3-3C27-4FB0-96B7-029DBE72C19C';
-- SET @StoreNumber='935'; 
-- SET @TargetStoreNumber='992';
 SET @FromDate='2020-06-01';


-- =====================================================================================================================
-- Buscar los datos
-- =====================================================================================================================

-- Buscar la orden más reciente
SET @idoUUID=COALESCE(@idoUUID,
      (
        SELECT TOP 1
          ido.UUID
        FROM InventoryDocumentOrder ido WITH (NOLOCK)
          INNER JOIN Store s1 WITH (NOLOCK) ON s1.ID=ido.StoreID
          INNER JOIN Store s2 WITH (NOLOCK) ON s2.ID=ido.TargetStoreID
        WHERE 1=1
          AND (COALESCE(@Folio, '')='' OR ido.Folio=@Folio)
          AND (@FromDate IS NULL OR ido.CreationDate>=@FromDate)
          AND (COALESCE(@idoUUID, '')='' OR ido.UUID=@idoUUID)
          AND (COALESCE(@StoreNumber, '')='' OR s1.Number=@StoreNumber)
          AND (COALESCE(@TargetStoreNumber, '')='' OR s2.Number=@TargetStoreNumber)
        ORDER BY ido.CreationDate DESC
      )
    );


-- ---------------------------------------------------------------------------------------------------------------------
-- 1. Mostrar la orden
-- ---------------------------------------------------------------------------------------------------------------------
SELECT
  CONCAT(
    CASE WHEN (
      SELECT COUNT(*) FROM InventoryDocumentOrderDetail q WITH (NOLOCK)
      WHERE q.InventoryDocumentOrderUUID=ido.UUID
        AND q.InventoryDocumentOrderUUID IS NULL
      )>0 THEN 'IDOD con InventoryDocumentOrderUUID=NULL' ELSE ''
    END,
    CASE WHEN (
      SELECT SUM(Quantity) FROM InventoryDocumentOrderDetail q WITH (NOLOCK)
      WHERE q.InventoryDocumentOrderUUID=ido.UUID
      )<>ido.Quantity THEN 'La suma de paquetes no coincide con cabecera' ELSE ''
    END
  ) AS Issues,
  CASE WHEN id.Folio IS NULL OR id.ErpSendStatusID=4
    THEN 'No recibido'
    ELSE 'Recibido'
  END AS IDOState,
  id.CreationDate AS StockDate,
  ido.CreationDate,
  ido.LastUpdate,
  ido.Quantity,
  CONCAT(ido.DocumentStatusID, ' ', ds.Name) AS DocumentStatus,
  CONCAT(ido.DocumentTypeID, ' ', dt.Name) AS DocumentType,
  ido.StoreID,
  CONCAT(ido.StoreID, ' ', s1.Name) AS Store,
  ido.WarehouseID,
  ido.TargetStoreID,
  CONCAT(ido.TargetStoreID, ' ', s2.Name) AS TargetStore,
  ido.TargetWarehouseID,
  ido.Folio,
  ido.Comment,
  ido.ErpSendStatusID,
  ido.ErpSendDate,
  ido.ErpDocumentID
FROM InventoryDocumentOrder IDO WITH (NOLOCK)
  INNER JOIN DocumentStatus    ds WITH (NOLOCK) ON ds.ID=ido.DocumentStatusID
  INNER JOIN DocumentType      dt WITH (NOLOCK) ON dt.ID=ido.DocumentTypeID
  INNER JOIN Store             s1 WITH (NOLOCK) ON s1.ID=ido.StoreID
  INNER JOIN Store             s2 WITH (NOLOCK) ON s2.ID=ido.TargetStoreID
  INNER JOIN Warehouse         w1 WITH (NOLOCK) ON w1.ID=ido.WarehouseID
  INNER JOIN Warehouse         w2 WITH (NOLOCK) ON w2.ID=ido.TargetWarehouseID
  LEFT JOIN  InventoryDocument id WITH (NOLOCK) ON id.OriginInventoryDocumentOrderUUID=ido.UUID
WHERE ido.UUID=@idoUUID
ORDER BY
  ido.CreationDate DESC;


-- ---------------------------------------------------------------------------------------------------------------------
-- 2. Mostrar detalle de la orden
-- ---------------------------------------------------------------------------------------------------------------------

-- Detallado como va
-- SELECT * FROM InventoryDocumentOrderDetail idod WHERE InventoryDocumentOrderUUID=@idoUUID;

-- Agrupado por fecha
/*
SELECT
  CreationDate,
  COUNT(CreationDate) AS Items
FROM InventoryDocumentOrderDetail WITH (NOLOCK)
WHERE
  InventoryDocumentOrderUUID=@idoUUID
GROUP BY CreationDate;
*/

-- Agrupado por fecha y artículo
/*
SELECT
  CreationDate,
  ItemCode,
  MAX(ItemDescription) AS ItemDescription,
  SUM(Quantity) AS Quantity,
  SUM(QuantityItemUnit) AS QuantityItemUnit
FROM InventoryDocumentOrderDetail WITH (NOLOCK)
WHERE InventoryDocumentOrderUUID=@idoUUID
GROUP BY
  CreationDate,
  ItemCode;
*/


-- ---------------------------------------------------------------------------------------------------------------------
-- 3. Validar el detalle de la orden
-- ---------------------------------------------------------------------------------------------------------------------
SELECT *
FROM (
  SELECT
    CASE
      WHEN COALESCE(idod.InventoryDocumentOrderID, 0)=0 then
        -- 'IDOD: Orden no asociada'
        CONCAT(
          'UPDATE InventoryDocumentOrderDetail SET', CHAR(13), CHAR(10),
          '  InventoryDocumentOrderID=', ido.ID, ',', CHAR(13), CHAR(10),
          '  LastUpdate=CURRENT_TIMESTAMP,', CHAR(13), CHAR(10),
          '  LastUpdateUserID=-1', CHAR(13), CHAR(10),
          'WHERE InventoryDocumentOrderUUID=''', ido.UUID, '''', CHAR(13), CHAR(10),
          '  AND COALESCE(InventoryDocumentOrderID, 0)=0'
        )
      WHEN ioh.UUID  IS NULL THEN
        -- 'IOH: Falta el destino'
        CONCAT(
          'UPDATE InventoryOnHand SET LastUpdate=LastUpdate ',
          'WHERE WarehouseID=', ido.TargetWarehouseID, ' AND ItemID=', idod.ItemID, ';'
        )
      WHEN iohd.UUID IS NULL THEN
        -- 'IOHD: Falta el destino'
        CONCAT(
          'UPDATE InventoryOnHandDetail SET LastUpdate=LastUpdate ',
          'WHERE InventoryOnHandUUID=''', ioh.UUID, ''' AND Serial=''', idod.Serial, ''';'
        )
      WHEN COALESCE(iohd.Batch, '')<>COALESCE(idod.Batch, '') THEN
        -- 'IOHD: Batch distinto en el destino'
        CONCAT(
          'UPDATE InventoryOnHandDetail SET', CHAR(13), CHAR(10),
          '  Batch=''', idod.Batch, '''', CHAR(13), CHAR(10),
          '  LastUpdate=CURRENT_TIMESTAMP,', CHAR(13), CHAR(10),
          '  LastUpdateUserID=-1,', CHAR(13), CHAR(10),
          'WHERE InventoryOnHandUUID=''', ioh.UUID, ''' AND Serial=''', idod.Serial, ''';'
        )
      WHEN COALESCE(iohd.CustomsInfo, '')<>COALESCE(idod.CustomsInfo, '') THEN
        -- 'IOHD: CustomsInfo distinto en el destino'
        CONCAT(
          'UPDATE InventoryOnHandDetail SET', CHAR(13), CHAR(10),
          '  CustomsInfo=''', idod.CustomsInfo, '''', CHAR(13), CHAR(10),
          '  LastUpdate=CURRENT_TIMESTAMP,', CHAR(13), CHAR(10),
          '  LastUpdateUserID=-1,', CHAR(13), CHAR(10),
          'WHERE InventoryOnHandUUID=''', ioh.UUID, ''' AND Serial=''', idod.Serial, ''';'
        )
      WHEN iohud.UUID IS NULL THEN
        -- 'IOHUD: Falta el destino'
        CONCAT(
          'UPDATE InventoryOnHandUnitDetail SET LastUpdate=LastUpdate',
          'WHERE InventoryOnHandUUID=''', ioh.UUID, ''' AND InventoryOnHandDetailUUID=''', iohd.UUID, ''';'
        )
      ELSE ''
    END AS Issue,
    
    ioh.ID           AS 'ioh.ID',
    ioh.UUID         AS 'ioh.UUID',
    ioh.CreationDate AS 'ioh.CreationDate',
    
    iohd.ID           AS 'iohd.ID',
    iohd.UUID         AS 'iohd.UUID',
    iohd.CreationDate AS 'iohd.CreationDate',
  
    iohud.ID           AS 'iohud.ID',
    iohud.UUID         AS 'iohud.UUID',
    iohud.CreationDate AS 'iohud.CreationDate',
  
    idod.ItemID,
    idod.ItemCode,
    idod.Serial,
    idod.Batch,
    idod.CustomsInfo
  
    -- Para crear IOHD del destino
--    CONCAT('    ''', idod.InventoryOnHandID, ''',') AS InventoryOnHandUUID
  
    -- Para crear IOHUD del destino
--    idod.Serial
  FROM InventoryDocumentOrderDetail IDOD WITH (NOLOCK)
    INNER JOIN InventoryDocumentOrder IDO WITH (NOLOCK) ON IDO.UUID=IDOD.InventoryDocumentOrderUUID
    LEFT JOIN InventoryOnHand IOH WITH (NOLOCK) ON IOH.WarehouseID=IDO.TargetWarehouseID
      AND IOH.ItemID=IDOD.ItemID
      AND COALESCE(IOH.ItemCombinationID,0)=COALESCE(IDOD.ItemCombinationID,0)
      AND IOH.StoreID>0
    LEFT JOIN InventoryOnHandDetail IOHD WITH (NOLOCK) ON IOHD.InventoryOnHandUUID=IOH.UUID
      AND COALESCE(IOHD.Serial,'')=COALESCE(IDOD.Serial,'')
--      AND COALESCE(IOHD.Batch,'')=COALESCE(IDOD.Batch,'')
--      AND COALESCE(IOHD.CustomsInfo,'')=COALESCE(IDOD.CustomsInfo,'')
    LEFT JOIN InventoryOnHandUnitDetail IOHUD WITH (NOLOCK) ON IOHUD.InventoryOnHandDetailUUID=IOHD.UUID
  WHERE
    IDOD.InventoryDocumentOrderUUID=@idoUUID
--    AND (IDOD.Serial <> '' OR IDOD.Batch <> '' OR IDOD.CustomsInfo <> '')
--    AND (IOHD.ID IS NULL OR IOHUD.ID IS NULL)
  ) sq
WHERE sq.Issue<>'';