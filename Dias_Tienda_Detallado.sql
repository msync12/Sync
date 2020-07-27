SELECT
F204.Name AS [00_REGION],
F205.Name AS [01_PLAZA], 
(CAST(S.Number AS nchar(4))+'-'+ S.Name) AS [02_TIENDA],
I.Code AS [03_CODIGO],
I.[Description] AS [04_PRODUCTO],
IOD.Serial AS [05_Serie],
SUM(Quantity) AS [06_KILOS],
IOD.FirstReceivedDate AS [07_RECIBIDO],
DATEDIFF(DAY,IOD.FabricationDate,GETDATE()) AS [08_FF],
DATEDIFF(DAY,IOD.FirstReceivedDate,GETDATE()) AS [09_FR]
FROM InventoryOnHand IOH
left JOIN InventoryOnHandDetail IOD ON IOD.InventoryOnHandUUID=IOH.UUID
INNER JOIN Store S ON S.ID=IOH.StoreID
INNER JOIN Item I ON I.ID=IOH.ItemID
LEFT JOIN FixedCategory F204 ON F204.ID=S.FixedCategory204ID
LEFT JOIN FixedCategory F205 ON F205.ID=S.FixedCategory205ID
WHERE 
(S.Number=796) AND
(IOD.Quantity <> 0)
GROUP BY 
IOD.Serial,
IOD.FirstReceivedDate,
S.Name,
I.Code,
S.Number,
F204.Name,
F205.Name,
I.Description,
IOD.FabricationDate
ORDER BY I.Code