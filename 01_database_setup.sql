USE master;

IF EXISTS (SELECT name
           FROM sys.databases
           WHERE name = 'Restaurant')
    BEGIN
        ALTER DATABASE Restaurant SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE Restaurant;
    END

CREATE DATABASE Restaurant;

USE Restaurant;