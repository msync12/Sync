UPDATE report r
LEFT JOIN (
    SELECT description, 
           reporttypeid, 
           storeid, 
           template, 
           workstation
    FROM report
    WHERE 1 = 1 
    AND storeid = 17 
    AND reporttypeid =2 
    AND workstation ='A') 
r2 ON r2.reporttypeid = r.reporttypeid 
    SET r.template = r2.template, 
        r.lastupdate = CURRENT_TIMESTAMP, 
        r.Description = r2.description
WHERE 
    r.reporttypeid = 2