SELECT 
		 SC.CreationDate 												  AS FechaCreacion, 
		 U.Login 													     AS UsuarioCreador, 
		 SC.LastUpdate 												  AS FechaAutorizacion,
		 U2.Login 														  AS UsuarioAutorizado, 
		 s.name 	 	  												 	  AS SUCURSAL, 
		 C.nAME 															  AS CLIENTE, 
		 SC.Folio 													     AS FOLIO, 
		 SC.Issued														  AS Monto, 
		 SC.Used 														  AS MontoUtilizado, 
		 CONCAT(SC.DocumentStatusID, ' <-> ',DS.DisplayName) AS EstadoVale
FROM StoreCredit SC
LEFT JOIN DocumentStatus DS ON DS.ID = SC.DocumentStatusID
LEFT JOIN Store S ON S.ID = SC.StoreID
LEFT JOIN [ USER] U ON U.ID = SC.CreationUserID
LEFT JOIN [ USER] U2 ON U2.ID = SC.LastUpdateUserID
LEFT JOIN Customer C ON C.ID = SC.CustomerID
WHERE sc.folio = 'NC249-25B'