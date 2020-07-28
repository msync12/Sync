SELECT 
	'Factura' AS Movement,
	convert(date,CD.CreationDate) AS Date,
	R.ID AS Register,
	NULL,
	CD.ErpSendStatusID  AS ErpSendStatus,
	CD.ID AS CFDiDocument,
	CQ.ErrorMessage AS ErrorMessage,
	EEL2.ErrorDescription AS ErrorDescription,
	CONCAT(S.ID,'  -  ',S.Number,'  -  ',S.Name) AS StoreInfo,
	SC.IPAddress AS IPAddress
	FROM CFDiDocument CD
	LEFT JOIN Register R ON R.ID = CD.RegisterID
	LEFT JOIN Store S ON S.ID =R.StoreID
	LEFT JOIN StoreConnection SC ON SC.StoreID = S.ID
	LEFT JOIN CFDiQueue CQ ON CQ.ID = CD.CFDiQueueID
	LEFT JOIN ErpErrorLog EEL2 on EEL2.tableid = CD.ID
	WHERE 1=1
	AND CD.ErpSendStatusID =1
	AND CD.RecordStatusID != 2
	AND CD.DocumentStatusID != 2
	AND CD.CreationDate >= '2020-01-01 00:00'