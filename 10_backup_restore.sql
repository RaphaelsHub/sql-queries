-- 1. Check backup files first
RESTORE HEADERONLY FROM DISK = 'C:\Backup_lab13\exercise1.bak';
RESTORE HEADERONLY FROM DISK = 'C:\Backup_lab13\exercise2.bak';
RESTORE HEADERONLY FROM DISK = 'C:\Backup_lab13\Restaurant_Full.bak';
RESTORE HEADERONLY FROM DISK = 'C:\Backup_lab13\exercise3.trn';
GO

-- 2. Clean up existing database if needed
IF DB_ID('Restaurant_lab13') IS NOT NULL
BEGIN
    -- Ensure database is not in restoring state
    IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Restaurant_lab13' AND state = 1)
    BEGIN
        RESTORE DATABASE Restaurant_lab13 WITH RECOVERY;
    END
    
    ALTER DATABASE Restaurant_lab13 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Restaurant_lab13;
END
GO

-- 3. Choose ONE restore option - either chain 1 or chain 2

-- OPTION 1: Restore Full + Differential (recommended for this scenario)
RESTORE DATABASE Restaurant_lab13
FROM DISK = 'C:\Backup_lab13\exercise1.bak'
WITH 
    MOVE 'Restaurant' TO 'C:\BD_lab13\Restaurant_lab13.mdf',
    MOVE 'Restaurant_log' TO 'C:\BD_lab13\Restaurant_lab13.ldf',
    NORECOVERY,
    REPLACE,
    STATS = 10;
GO

RESTORE DATABASE Restaurant_lab13
FROM DISK = 'C:\Backup_lab13\exercise2.bak'
WITH 
    RECOVERY,
    STATS = 10;
GO

-- OR OPTION 2: Restore Full + Log (alternative)

RESTORE DATABASE Restaurant_lab13
FROM DISK = 'C:\Backup_lab13\Restaurant_Full.bak'
WITH 
    MOVE 'Restaurant' TO 'C:\BD_lab13\Restaurant_lab13.mdf',
    MOVE 'Restaurant_log' TO 'C:\BD_lab13\Restaurant_lab13.ldf',
    NORECOVERY,
    REPLACE,
    STATS = 10;
GO

RESTORE LOG Restaurant_lab13
FROM DISK = 'C:\Backup_lab13\exercise3.trn'
WITH 
    RECOVERY,
    STATS = 10;
GO


-- 4. Verify the restored database
SELECT name, state_desc, recovery_model_desc 
FROM sys.databases 
WHERE name = 'Restaurant_lab13';

