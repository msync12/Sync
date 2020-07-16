SELECT  
	convert(date,RCO.CreationDate) AS Date,
	R.ID AS Register,
	RCO.ID AS RegisterCloseOut,
	RCO.ErpSendStatusID AS ErpSendStatus,
	cf.id AS CFDiDocument,
	EEL2.ErrorDescription AS ErrorDescription,
	EEL.ErrorDescription AS  ErrorMessage,
	CQ.ErrorMessage AS CFDiError,
	CD.XML AS XML,
	CONCAT(S.ID,'  -  ',S.Number,'  -  ',S.Name) AS StoreInfo,
	SC.IPAddress AS IPAddress
	FROM RegisterCloseOut RCO
	LEFT JOIN Register R ON R.ID = RCO.RegisterID
	LEFT JOIN ErpErrorLog EEL ON EEL.TableID = rco.ID
	LEFT JOIN CFDiDocument CF ON cf.RegisterID = RCO.RegisterID and cf.erpsendstatusid in (1,4)
	LEFT JOIN CFDiQueue CQ ON CQ.ID = CF.CFDiQueueID
	LEFT JOIN CFDiFile CD ON CD.ID = cf.CFDiFileID
	LEFT JOIN Store S ON S.ID =R.StoreID
	LEFT JOIN StoreConnection SC ON SC.StoreID = S.ID
	LEFT JOIN ErpErrorLog EEL2 on EEL2.tableid = CF.ID
	WHERE 1=1
	and RCO.ID IN (Select tableid from ErpErrorLog where TableName='RegisterCloseOut' )

