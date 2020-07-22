Select
	Concat('Ref3: C', ID.ID) Ref3,
	id.Folio FolioMov,
	dt.Name Mov,
	concat(id.documentstatusid,' - ',ds.DisplayName) Estatus,
	id.ErpSendStatusID,
	id.ErpSendDate,
	id.ErpDocumentID
	FROM InventoryDocument ID 
	LEFT JOIN DocumentType DT ON DT.ID = ID.DocumentTypeID
	LEFT JOIN DocumentStatus DS ON DS.ID = ID.DocumentStatusID
	where id.id in (6547577,
6577391,
6577502,
6542403,
6512214,
6606402,
6606849,
6606595,
6337005)
