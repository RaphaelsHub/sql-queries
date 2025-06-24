-- Создаем роли пользователей, администратора и пользователя, и назначаем им разрешения  
CREATE ROLE created_administrator_role;  
CREATE ROLE created_user_role;

GRANT ALL PRIVILEGES ON DATABASE::Restaurant TO created_administrator_role;  
GRANT SELECT ON DATABASE::Restaurant TO created_user_role;

-- Cоздаем пользователей и назначаем им роль 
IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = 'created_admin_user')
    CREATE LOGIN created_admin_user WITH PASSWORD = 'adminpassword';  

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'created_admin_user')
CREATE USER created_admin_user FOR LOGIN created_admin_user;  

EXEC sp_addrolemember 'created_administrator_role', 'created_admin_user';

IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = 'created_regular_user')
CREATE LOGIN created_regular_user WITH PASSWORD = 'userpassword';  

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'created_regular_user')
CREATE USER created_regular_user FOR LOGIN created_regular_user;  

EXEC sp_addrolemember 'created_user_role', 'created_regular_user';

-- Создаем еще одного пользователя и для него определяем разрешение на добавление, удаление и просмотр информации в таблицах БД
-- Запретите пользователю удалять информацию из БД, используя оператор REVOKE, полностью запретите доступ к какой-либо таблице БД.
IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = 'created_auto_user_for_our_db')
CREATE LOGIN created_auto_user_for_our_db WITH PASSWORD = 'autouserpassword';

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'created_auto_user_for_our_db')
CREATE USER created_auto_user_for_our_db FOR LOGIN created_auto_user_for_our_db;

GRANT SELECT, INSERT, DELETE ON DATABASE::Restaurant TO created_auto_user_for_our_db;

REVOKE DELETE ON DATABASE::Restaurant FROM created_auto_user_for_our_db;
DENY ALL ON DATABASE::Restaurant TO created_auto_user_for_our_db;

--SHOW ALL USERS
SELECT * FROM sys.sql_logins;

--SHOW ALL USERS
SELECT * FROM sys.database_principals WHERE type_desc = 'SQL_USER';

--SHOW ALL ROLES
SELECT *
FROM sys.database_principals
WHERE type_desc = 'DATABASE_ROLE'
  AND name not LIKE 'db_%';


-- DROP LOGIN created_auto_user_for_our_db;
-- DROP USER  created_auto_user_for_our_db;
-- DROP ROLE created_auto_role_for_our_db;