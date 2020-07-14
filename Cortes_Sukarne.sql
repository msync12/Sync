/* CONSULTA DE CORTES Y FACTURAS QUE NO HAN VIAJADO A SAP
-- 2020-04-23 Manuel Leonor

***DESCRIPCI�N DE CAMPOS**

1. Movement = Tipo de movimiento  [Corte = Corte de caja que no ha viajado a SAP] [Factura = Factura que no ha viajado a SAP]
2. Date = Fecha de movimiento
3. Register = ID DE LA APERTURA DE CAJA
4. RegisterCloseOut = ID DEL CORTE DE CAJA

5. ErpSendStatus = Status de envio 
	1	- Por enviar			- Pendiente de enviar al ERP
	2	- Enviado				- Enviado al ERP pero sin confirmar su aplicaci�n
	3	- Aplicado			- Enviado y aplicado en el ERP
	4	- Error				- Hubo error en el envio consultar ERPerrorLog
	5	- En espera			- para movimientos como art�culos de despacho que les falta informaci�n
	6	- Por enviar paso 2	- Movimientos que tienen dos pasos como las notas de cr�dito (emitir y luego vender)
	7	- CanceladoERP - 
	8	- No Enviar - 

7. CFDIDOCUMENT = ID de la factura

8. ErrorMessage = Este campo contiene dos informaciones
					1. FACTURA - CFDIQUE	= contiene el mensaje por el cual no puede viajar la factura a SAP
 					2. CORTE - ErpErrorLog  = contiene el mensaje por cual no puede viajar el corte a SAP

9. ErrorDescription = Este campo contiene el erperrorlog que emite la factura esto puede suceder para los dos casos, cortes o facturas (Leer casos de cortes)

10. StoreInfo = Este campo contiene ID, NUMBER Y NAME de cada tienda

11. IpAddress = Este campo contiene la Direccion IP de cada Servidor local de su respectiva tienda
*/
SELECT *
FROM (
	SELECT  
	'Corte' AS Movement,
	convert(date,RCO.CreationDate) AS Date,
	R.ID AS Register,
	RCO.ID AS RegisterCloseOut,
	RCO.ErpSendStatusID AS ErpSendStatus,
	cf.id AS CFDiDocument,
	EEL.ErrorDescription AS  ErrorMessage,
	EEL2.ErrorDescription AS ErrorDescription,
	CONCAT(S.ID,'  -  ',S.Number,'  -  ',S.Name) AS StoreInfo,
	SC.IPAddress AS IPAddress
	FROM RegisterCloseOut RCO
	LEFT JOIN Register R ON R.ID = RCO.RegisterID
	LEFT JOIN ErpErrorLog EEL ON EEL.TableID = rco.ID
	LEFT JOIN CFDiDocument CF ON cf.RegisterID = RCO.RegisterID and cf.erpsendstatusid in (1,4)
	LEFT JOIN Store S ON S.ID =R.StoreID
	LEFT JOIN StoreConnection SC ON SC.StoreID = S.ID
	LEFT JOIN ErpErrorLog EEL2 on EEL2.tableid = CF.ID
	WHERE 1=1
	and RCO.ID IN (Select tableid from ErpErrorLog where TableName='RegisterCloseOut' )

UNION ALL

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
)T  


