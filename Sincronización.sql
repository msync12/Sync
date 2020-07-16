SELECT  
    ProcessName, 
    LastMessage, 
    LastError, 
    CurrentIteration, 
    TotalIterations, 
    SincroID, LastCheck  
FROM SyncLinkService 
ORDER BY LASTCHECK DESC