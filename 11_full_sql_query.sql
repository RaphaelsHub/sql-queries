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

------------------------------------------------------1 lab--------------------------------------------------
-- 1.2 Создаем роли пользователей, администратора и пользователя, и назначаем им разрешения  
CREATE ROLE created_administrator_role;  
CREATE ROLE created_user_role;

GRANT ALL PRIVILEGES ON DATABASE::Restaurant TO created_administrator_role;  
GRANT SELECT ON DATABASE::Restaurant TO created_user_role;

-- 1.3.1 Cоздаем пользователей и назначаем им роль 
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

-- 1.3.2 Создаем еще одного пользователя и для него определяем разрешение на добавление, удаление и просмотр информации в таблицах БД
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
-------------------------------------------------end 1 lab--------------------------------------------------


-- Create tables for the Restaurant database
IF OBJECT_ID('MENU', 'U') IS NOT NULL
    DROP TABLE MENU;
    
CREATE TABLE MENU
(
    MenuID      INT PRIMARY KEY IDENTITY (1, 1),
    Name        NVARCHAR(50)   NOT NULL,
    Description NVARCHAR(255)  NOT NULL,
    Price       DECIMAL(10, 2) NOT NULL CHECK (Price >= 0) -- Price cannot be negative and must be a decimal number with 2 decimal places (e.g., 10.00)
)

IF OBJECT_ID('INGREDIENTS', 'U') IS NOT NULL
    DROP TABLE INGREDIENTS;
    
CREATE TABLE INGREDIENTS
(
    IngredientID INT PRIMARY KEY IDENTITY (1, 1),
    Name         NVARCHAR(50)   NOT NULL,
    Cost         DECIMAL(10, 2) NOT NULL CHECK (Cost >= 0),
    Supplier     NVARCHAR(50)   NOT NULL  
)

IF OBJECT_ID('MENU_INGREDIENTS', 'U') IS NOT NULL
    DROP TABLE MENU_INGREDIENTS;
    
CREATE TABLE MENU_INGREDIENTS
(
    MenuID       INT REFERENCES MENU(MenuID) ON DELETE CASCADE ON UPDATE CASCADE,
    IngredientID INT REFERENCES INGREDIENTS(IngredientID) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (MenuID, IngredientID),
);

IF OBJECT_ID('ALL_STAFF', 'U') IS NOT NULL
    DROP TABLE ALL_STAFF;
    
CREATE TABLE ALL_STAFF
(
    StaffID     INT PRIMARY KEY IDENTITY (1, 1),
    FullName    NVARCHAR(100)  NOT NULL,
    PhoneNumber NVARCHAR(15)   NOT NULL,
    Position    NVARCHAR(50)   NOT NULL,
    Salary      DECIMAL(10, 2) NOT NULL
);

IF OBJECT_ID('SERVING_STAFF', 'U') IS NOT NULL
    DROP TABLE SERVING_STAFF;
    
CREATE TABLE SERVING_STAFF
(
    ServingStaffID INT PRIMARY KEY IDENTITY (1, 1),
    StaffID        INT REFERENCES ALL_STAFF (StaffID) ON DELETE CASCADE ON UPDATE CASCADE
);

IF OBJECT_ID('TABLES', 'U') IS NOT NULL
    DROP TABLE TABLES;
    
CREATE TABLE TABLES
(
    TableID INT PRIMARY KEY IDENTITY (1, 1),
    Capacity INT NOT NULL
);

IF OBJECT_ID('ORDERS', 'U') IS NOT NULL
    DROP TABLE ORDERS;
    
CREATE TABLE ORDERS
(
    OrderID            INT PRIMARY KEY IDENTITY (1, 1),
    TableID            INT            NOT NULL REFERENCES TABLES (TableID) ON DELETE CASCADE ON UPDATE CASCADE,
    ServingStaffID     INT            NOT NULL REFERENCES SERVING_STAFF (ServingStaffID) ON DELETE CASCADE ON UPDATE CASCADE,
    TotalAmount        DECIMAL(10, 2) NOT NULL CHECK (TotalAmount > 0),
    TotalAmountWithTax AS (TotalAmount * 1.09) PERSISTED,
    OrderDate          DATETIME       NOT NULL DEFAULT GETDATE(),
    IsClosed           BIT            NULL
);

IF OBJECT_ID('ORDERS_MENU', 'U') IS NOT NULL
    DROP TABLE ORDERS_MENU;
    
CREATE TABLE ORDERS_MENU
(
    OrderID  INT NOT NULL REFERENCES ORDERS (OrderID) ON DELETE CASCADE ON UPDATE CASCADE,
    MenuID   INT NOT NULL REFERENCES MENU (MenuID) ON DELETE CASCADE ON UPDATE CASCADE,
    Quantity INT NOT NULL,
    PRIMARY KEY (MenuID, OrderID)
);

-- Insert initial data into the tables
USE Restaurant;

INSERT INTO MENU (Name, Description, Price)
VALUES ('Burger', 'Grilled beef patty with lettuce, tomato, and cheese on a bun', 5.99),
       ('Pizza', 'Classic margherita pizza with tomato sauce and mozzarella', 7.49),
       ('Pasta', 'Creamy Alfredo pasta with grilled chicken', 6.79),
       ('Salad', 'Fresh green salad with vinaigrette dressing', 4.50),
       ('Sushi', 'Assorted sushi platter with wasabi and soy sauce', 12.99);

INSERT INTO INGREDIENTS (Name, Cost, Supplier)
VALUES ('Beef Patty', 2.50, 'Local Farm'),
       ('Lettuce', 0.30, 'GreenGrow'),
       ('Tomato', 0.40, 'GreenGrow'),
       ('Cheese', 0.80, 'Dairy Co'),
       ('Bun', 0.50, 'Bakery Fresh'),
       ('Dough', 1.00, 'Bakery Fresh'),
       ('Tomato Sauce', 0.70, 'Sauce Inc.'),
       ('Mozzarella', 1.20, 'Dairy Co'),
       ('Pasta', 0.90, 'Italian Goods'),
       ('Chicken Breast', 2.00, 'Poultry Farm'),
       ('Cream', 0.80, 'Dairy Co'),
       ('Mixed Greens', 0.70, 'GreenGrow'),
       ('Vinaigrette', 0.60, 'Sauce Inc.'),
       ('Rice', 0.90, 'Asian Supplier'),
       ('Fish', 3.50, 'Seafood World');

INSERT INTO MENU_INGREDIENTS (MenuID, IngredientID)
VALUES
-- Burger
(1, 1),  -- Beef Patty
(1, 2),  -- Lettuce
(1, 3),  -- Tomato
(1, 4),  -- Cheese
(1, 5),  -- Bun

-- Pizza
(2, 6),  -- Dough
(2, 7),  -- Tomato Sauce
(2, 8),  -- Mozzarella

-- Pasta
(3, 9),  -- Pasta
(3, 10), -- Chicken Breast
(3, 11), -- Cream

-- Salad
(4, 2),  -- Lettuce
(4, 12), -- Mixed Greens
(4, 13), -- Vinaigrette

-- Sushi
(5, 14), -- Rice
(5, 15); -- Fish

INSERT INTO ALL_STAFF (FullName, PhoneNumber, Position, Salary)
VALUES ('Emily Johnson', '1112223333', 'Waiter', 2500.00),
       ('Michael Brown', '4445556666', 'Waiter', 2500.00),
       ('Sophia Anderson', '3213213210', 'Waiter', 2500.00),
       ('Liam Taylor', '7897897890', 'Cleaner', 2000.00),
       ('Emma Moore', '4564564567', 'Chef', 4000.00),
       ('John Doe', '1234567890', 'Manager', 5000.00),
       ('Ava Harris', '1472583690', 'Chef', 4000.00),
       ('James Clark', '2583691470', 'Cleaner', 2000.00),
       ('Isabella Lewis', '3692581470', 'Waiter', 2500.00),
       ('Noah Lee', '9879879876', 'Waiter', 2500.00);

-- Here are just waiters
INSERT INTO SERVING_STAFF (StaffID)
VALUES (1),
       (2),
       (3),
       (9),
       (10);

INSERT INTO TABLES (Capacity)
VALUES
    (2),
    (4),
    (6),
    (2);

INSERT INTO ORDERS (TableID, ServingStaffID, TotalAmount, IsClosed)
VALUES
    (1, 1, 24.50, 0),
    (2, 2, 35.00, 0),
    (3, 3, 18.75, 0),
    (4, 4, 42.30, 0),
    (1, 5, 28.10, 0);

INSERT INTO ORDERS_MENU (OrderID, MenuID, Quantity)
VALUES
    (1, 1, 2), -- Order 1: 2x MenuID 1
    (1, 2, 1),
    (2, 3, 2),
    (2, 4, 1),
    (3, 2, 1),
    (3, 5, 1),
    (4, 4, 3),
    (5, 1, 1),
    (5, 5, 2);

-- Union, intersect, except
--AND, OR, NOR, IN, BETWEEN, LIKE, IS NULL, TOP WITH TIES, ORDER BY, NOR, IS NULL

-- UNION
SELECT FullName, PhoneNumber, Position, Salary
FROM ALL_STAFF
WHERE Position = 'Waiter'
UNION
SELECT FullName, PhoneNumber, Position, Salary
FROM ALL_STAFF
WHERE Position = 'Chef';

-- Intersect
SELECT FullName, PhoneNumber, Position, Salary
FROM ALL_STAFF
WHERE Position = 'Waiter'
INTERSECT
SELECT FullName, PhoneNumber, Position, Salary
FROM ALL_STAFF a
WHERE a.StaffID IN (SELECT StaffID
                    FROM SERVING_STAFF);

-- Except
SELECT FullName, PhoneNumber, Position, Salary
FROM ALL_STAFF
EXCEPT
SELECT FullName, PhoneNumber, Position, Salary
FROM ALL_STAFF
WHERE Position = 'Chef'
   OR Position = 'Waiter';

-- CROSS JOIN - декартово произведение
SELECT a.Name, b.Price
FROM MENU a
CROSS JOIN MENU b
WHERE b.Price IS NOT NULL; -- НЕ ИМЕЕТ ЗНАЧЕНИЯ ТАК КАК У НАС price не поддерживает NULL

SELECT  a.Name, b.Price
FROM MENU a, MENU b;

-- Inner Join - join two tables based on the common column
SELECT  ss.ServingStaffID, FullName, PhoneNumber, Position, Salary
FROM ALL_STAFF
         JOIN SERVING_STAFF ss ON ALL_STAFF.StaffID = ss.StaffID
WHERE Position = 'Waiter';

SELECT O.OrderID,
       O.OrderDate,
       O.TotalAmountWithTax,
       T.TableID,
       T.Capacity,
       SS.ServingStaffID,
       AaS.FullName,
       AaS.PhoneNumber,
       AaS.Position
FROM ORDERS O
         JOIN TABLES T ON O.TableID = T.TableID
         JOIN SERVING_STAFF SS ON O.ServingStaffID = SS.ServingStaffID
         JOIN ALL_STAFF AaS ON SS.StaffID = AaS.StaffID
WHERE O.TotalAmountWithTax < 50
  AND 40 < O.TotalAmountWithTax;
   
-- NATURAL JOIN - we are using where we have same column names in both tables, it will take the common column and join the tables(mssql does not support)
SELECT a.StaffID,ss.ServingStaffID, FullName, PhoneNumber, Position, Salary
FROM ALL_STAFF a
         JOIN SERVING_STAFF ss ON a.StaffID = ss.StaffID
WHERE Position = 'Waiter';

-- SEMI JOIN
SELECT *
FROM MENU a
WHERE a.MenuId IN (SELECT MenuId FROM ORDERS_MENU WHERE OrderId = 1);

-- Theta Join
SELECT a.Name AS IngredientA, a.Cost AS CostA, b.Name AS IngredientB, b.Cost AS CostB
FROM INGREDIENTS a
         JOIN INGREDIENTS b ON a.Cost > b.Cost;
    
-- LEFT JOIN
SELECT *
FROM ALL_STAFF a
         LEFT JOIN SERVING_STAFF z ON a.StaffId = z.StaffId;
    
-- RIGHT JOIN
SELECT *
FROM SERVING_STAFF a
         RIGHT JOIN ALL_STAFF z ON a.StaffId = z.StaffId;

-- FULL JOIN
SELECT *
FROM ORDERS a
         FULL OUTER JOIN ORDERS_MENU p ON a.OrderId = p.OrderId
         FULL OUTER JOIN SERVING_STAFF z ON z.ServingStaffId = a.ServingStaffId;

-- Active Complement
SELECT Name
FROM MENU
WHERE MenuId NOT IN (
    SELECT MenuId
    FROM ORDERS_MENU
    WHERE OrderId = 1);

-- Selection + Projection
SELECT DISTINCT TOP 3 WITH TIES Name, Description, Price
FROM MENU
WHERE Price BETWEEN 5 AND 50 AND Name LIKE 'P%' AND Description IS NOT NULL
ORDER BY Price DESC;

-- (Division)
SELECT MenuId
FROM MENU_INGREDIENTS
WHERE IngredientId IN (SELECT IngredientId FROM INGREDIENTS WHERE Name IN ('Beef', 'Cheese', 'Tomato'))
GROUP BY MenuId
HAVING COUNT(DISTINCT IngredientId) = (SELECT COUNT(*) FROM INGREDIENTS WHERE Name IN ('Beef', 'Cheese', 'Tomato'));


--MIN, MAX, AVG, SUM, COUNT
SELECT MIN(Price) AS MinPrice FROM MENU;

SELECT MAX(Salary) AS MaxSalary FROM ALL_STAFF;

SELECT Supplier, AVG(Cost) AS AvgCost
FROM INGREDIENTS
GROUP BY Supplier;

SELECT ss.ServingStaffID, a.FullName, SUM(o.TotalAmount) AS TotalServed
FROM ORDERS o
JOIN SERVING_STAFF ss ON o.ServingStaffID = ss.ServingStaffID
JOIN ALL_STAFF a ON ss.StaffID = a.StaffID
GROUP BY ss.ServingStaffID, a.FullName;

SELECT COUNT(*) AS WaitersCount
FROM SERVING_STAFF;

-- Queries with GROUP BY and HAVING
SELECT 
    Position,
    AVG(Salary) AS AverageSalary
FROM 
    ALL_STAFF
GROUP BY 
    Position
HAVING 
    AVG(Salary) > 3000;


USE Restaurant;
SELECT 
    t.TableID,
    t.Capacity,
    a.FullName AS StaffName,
    SUM(o.TotalAmount) AS TotalOrdersAmount
FROM 
    ORDERS o
JOIN 
    TABLES t ON o.TableID = t.TableID
JOIN 
    SERVING_STAFF s ON o.ServingStaffID = s.ServingStaffID
JOIN 
    ALL_STAFF a ON s.StaffID = a.StaffID
WHERE 
    o.IsClosed = 0 -- только открытые заказы
GROUP BY 
    t.TableID, t.Capacity, a.FullName
HAVING 
    SUM(o.TotalAmount) > 5
ORDER BY 
    TotalOrdersAmount DESC;

-- <, in, all, any, exists, not exists,
SELECT FullName, Position, Salary
FROM ALL_STAFF
WHERE Salary > 3000;

-- in
SELECT Name, Description, Price
FROM MENU
WHERE MenuId IN (1, 2, 3);

-- all - это значит что все значения должны быть меньше чем все остальные
SELECT Name, Description, Price
FROM MENU
WHERE Price < ALL (SELECT Price FROM MENU WHERE MenuId IN (2,4));

-- any - это значит что хотя бы одно значение должно быть меньше чем все остальные
SELECT FullName, Position, Salary
FROM ALL_STAFF
WHERE Salary > ANY (SELECT Salary FROM ALL_STAFF WHERE Position = 'Waiter');

-- exists - это значит что хотя бы одно значение должно существовать в подзапросе
SELECT FullName, PhoneNumber, Position
FROM ALL_STAFF s
WHERE EXISTS (SELECT 1 FROM SERVING_STAFF ss WHERE s.StaffId = ss.StaffId);

-- коррелированный подзапрос - это значит что подзапрос ссылается на внешний запрос
SELECT Name, Supplier, Cost
FROM INGREDIENTS i
WHERE Cost < (SELECT AVG(Cost) FROM INGREDIENTS i2 WHERE i.Supplier = i2.Supplier);

-- Напишите команду с подзапросом в части FROM
SELECT MenuId, TotalQuantity
FROM (
    SELECT MenuId, SUM(Quantity) AS TotalQuantity
    FROM ORDERS_MENU
    GROUP BY MenuId
) AS SubQuery
WHERE TotalQuantity > 2;

-- Напишите команду с подзапросом в части SELECT
SELECT FullName, Position, Salary, 
    (SELECT AVG(Salary) FROM ALL_STAFF) AS AvgSalary
FROM ALL_STAFF;


-- inseart, update, delete tables

-- -- Update the new column with default value 'false' (0 in SQL Server)
-- UPDATE ORDERS
-- SET IsClosed = CASE
--     WHEN OrderId > 6 THEN 0
--     ELSE 1
-- END;



-- -- Удаляем топ N ингредиентов, стоимость которых выше средней стоимости всех ингредиентов, и выводим удаленные строки
-- DELETE TOP (3) FROM INGREDIENTS
-- OUTPUT deleted.*
-- WHERE Cost > (SELECT AVG(Cost) FROM INGREDIENTS);





-- --4.1.2 Условное удаление с подзапросом однотабличное (с агрегацией или группировкой)
-- -- Удаляем ингредиенты, стоимость которых выше средней стоимости всех ингредиентов и выводим удаленные строки
-- DELETE FROM INGREDIENTS
-- OUTPUT deleted.*
-- WHERE Cost > (SELECT AVG(Cost) FROM INGREDIENTS);

-- --4.1.3 Обновление кортежей одной таблицы с использованием TOP
-- -- Обновляем зарплату топ-3 сотрудников, увеличивая ее на 10%, и выводим обновленные строки
-- UPDATE TOP (3) ALL_STAFF
-- SET Salary = Salary * 1.10
-- OUTPUT inserted.*;

-- --4.1.4 Обновление с подзапросом многотабличное
-- -- Закрываем заказы, которые были сделаны более 30 дней назад, и выводим обновленные строки
-- UPDATE ORDERS
-- SET IsClosed = 1
-- OUTPUT inserted.*
-- WHERE OrderDate < (
--     SELECT DATEADD(DAY, -30, GETDATE())
-- );


-- --4.2.1 Вставка в существующее отношение результата запроса (INSERT INTO с SELECT)
-- -- Создадим таблицу MANAGERS

-- CREATE TABLE MANAGERS (
--     ManagerId INT PRIMARY KEY IDENTITY(1,1),
--     FullName NVARCHAR(100) NOT NULL,
--     PhoneNumber NVARCHAR(15) NOT NULL,
--     Salary DECIMAL(10,2) NOT NULL
-- );

-- -- Вставляем данные в таблицу MANAGERS из таблицы ALL_STAFF и выводим вставленные данные с помощью OUTPUT
-- INSERT INTO MANAGERS (FullName, PhoneNumber, Salary)
-- OUTPUT inserted.* 
-- --inserted.FullName, inserted.PhoneNumber, inserted.Salary
-- SELECT FullName, PhoneNumber, Salary
-- FROM ALL_STAFF
-- WHERE Position = 'Manager';


-- --4.2.2 Вставка результата запроса SELECT из одного отношения (отношение-источник) в новое отношение NEW_Table, созданное мгновенно (SELECT INTO)

-- -- Создадим таблицу WAITERS и вставим данные из таблицы ALL_STAFF
-- SELECT FullName, PhoneNumber, Salary
-- INTO WAITERS 
-- FROM ALL_STAFF 
-- WHERE Position = 'Waiter';


------------------------------------------------ 1 lab --------------------------------------------------
-- 1.1 Создаем представление, которое показывает все заказы, сделанные на столике 5, с указанием названия блюда, его цены и количества
GO  
CREATE VIEW MENU_FOR_TABLES AS  
SELECT m.MenuId, m.Name, m.Price, om.Quantity, Total_price = m.Price * om.Quantity, a.FullName  
FROM MENU m  

    JOIN ORDERS_MENU om ON m.MenuId = om.MenuId  
    JOIN ORDERS o ON om.OrderId = o.OrderId  
    JOIN SERVING_STAFF ss ON o.ServingStaffId = ss.ServingStaffId  
    JOIN ALL_STAFF a ON ss.StaffId = a.StaffId  
WHERE o.TableId = 2;  
GO  

SELECT * FROM MENU_FOR_TABLES;

-- 1.2 Создаем представление, которое показывает все заказы, сделанные на столике 5, с указанием названия блюда, его цены и количества, а также даты заказа и имени официанта
GO
CREATE VIEW MENU_FOR_TABLES_With_Date AS
SELECT m.MenuId, m.Name, m.Price, om.Quantity, Total_price = m.Price * om.Quantity, o.OrderDate, a.FullName 
FROM MENU m
    JOIN ORDERS_MENU om ON m.MenuId = om.MenuId 
    JOIN ORDERS o ON om.OrderId = o.OrderId 
    JOIN SERVING_STAFF ss ON o.ServingStaffId = ss.ServingStaffId 
    JOIN ALL_STAFF a ON ss.StaffId = a.StaffId 
WHERE o.TableId = 2;
GO

SELECT * FROM MENU_FOR_TABLES_With_Date;

-- 1.3 Создаем представление, которое поможет добавлять информацию о новых блюдах.
GO
CREATE VIEW NewMenuItems AS
SELECT MenuId, Name, Description, Price
FROM MENU
WHERE Price > 0;
GO

INSERT INTO NewMenuItems (Name, Description, Price)
VALUES ('Pasta A', 'Description', 10.00),
		('Pasta B', 'Description', 15.00);

SELECT * FROM NewMenuItems;
--------------------------------------------------------end 1 lab --------------------------------------------------

-------------------------------------------------------1.2 lab--------------------------------------------------
-- 1.2.1.1 Создаем синоним для любого отношения из БД Restaurant. Покажите его применение.
CREATE SYNONYM MenuSynonym FOR Restaurant.dbo.MENU;
SELECT * FROM MenuSynonym;

-- 1.2.1.2 Создаем синоним для хранимой процедуры или функции, созданной в работе W10. Обратитесь к процедуре (функции) через синоним.
GO
CREATE FUNCTION dbo.GetAllServingStaff()
    RETURNS TABLE
    AS
    RETURN(SELECT ss.ServingStaffId,
    s.StaffId,
    s.FullName,
    s.PhoneNumber,
    s.Position,
    s.Salary
    FROM SERVING_STAFF ss
    JOIN ALL_STAFF s ON ss.StaffId = s.StaffId);
GO

SELECT * FROM dbo.GetAllServingStaff();

CREATE SYNONYM GetAllServingStaffSynonym FOR dbo.GetAllServingStaff;
SELECT * FROM GetAllServingStaffSynonym();


-- 1.2.2.1 Создаем кластеризованный и некластеризованный индексы. Поясните разницу между ними, на примере их работы.
-- Кластеризованный индекс - это индекс, который определяет порядок данных в таблице, а некластеризованный - нет
-- Создаем кластеризованный индекс для таблицы MENU, чтобы ускорить выборку по MenuId, вообще он уже есть, но для примера
--CREATE CLUSTERED INDEX IDX_MenuId ON Restaurant.dbo.MENU (MenuId);
CREATE NONCLUSTERED INDEX IDX_Name ON Restaurant.dbo.MENU (Name);
SELECT * FROM Restaurant.dbo.MENU WHERE MenuId = 1;
SELECT * FROM Restaurant.dbo.MENU WHERE Name = 'Pizza';


-- 1.2.2.2 Выполните выборку с сортировкой на основе столбца для которого не существует индекса.
-- Затем создайте для него некластеризованный индекс и повторите запрос. Сравните планы выполнения
SELECT * FROM Restaurant.dbo.MENU ORDER BY Price;
CREATE NONCLUSTERED INDEX IDX_Price ON Restaurant.dbo.MENU (Price);
SELECT * FROM Restaurant.dbo.MENU ORDER BY Price;

--------------------------------------------------------lab 2--------------------------------------------------
-- 2.2.1 Создайте хранимую процедуру, которая увеличивает цену всех блюд, проданных после даты, заданной в аргументе на 10%. Запустите её.
GO
CREATE PROCEDURE IncreaseDishPricesAfterDate @startDate DATETIME
AS
BEGIN
 -- Обновляем цену всех блюд на 10% после указанной даты
UPDATE m
SET m.Price = m.Price * 1.10
FROM Restaurant.dbo.MENU m
    JOIN Restaurant.dbo.ORDERS_MENU om ON m.MenuId = om.MenuId
    JOIN Restaurant.dbo.ORDERS o ON om.OrderId = o.OrderId
WHERE o.OrderDate > @startDate;

PRINT 'Prices updated successfully';
END;
GO

EXEC IncreaseDishPricesAfterDate '2023-01-01';

SELECT * FROM MENU;

--2.2.1 Измените процедуру так, чтобы она восстановила старые значения цен блюд, затронутых предыдущим вызовом процедуры. Запустите её.
GO
CREATE PROCEDURE DecreaseDishPricesAfterDate @startDate DATETIME
AS
BEGIN
 -- Обновляем цену всех блюд на 10% после указанной даты
UPDATE m
SET m.Price = m.Price * 100 / 110
FROM Restaurant.dbo.MENU m
    JOIN Restaurant.dbo.ORDERS_MENU om ON m.MenuId = om.MenuId
    JOIN Restaurant.dbo.ORDERS o ON om.OrderId = o.OrderId
WHERE o.OrderDate > @startDate;

PRINT 'Prices updated successfully';
END;
GO

EXEC DecreaseDishPricesAfterDate '2023-01-01';

SELECT * FROM MENU;

-- DML триггеры - Insert, Update, Delete - изменение данных в таблице, DDL триггеры - изменение структуры базы данных create, alter, drop, enable, disable
-- 2.3.1 Создайте DML триггер, который при добавлении нового кортежа в отношение «Menu» автоматически увеличивает цену на 20%.
-- Добавьте несколько кортежей в отношение.
-- В процессе демонстрации работы триггера используйте команды DISABLE/ENABLE TRIGGER, применяя их на уровне базы данных и на уровне отношения (в пределах команды ALTER TABLE).
-- Создание DML триггера для увеличения цены на 20% при добавлении нового блюда

GO 
CREATE TRIGGER TriggerIncreasePriceOnInsert
ON Restaurant.dbo.MENU
AFTER INSERT
AS
BEGIN
    -- Увеличиваем цену на 20% только для новых вставленных строк
    UPDATE m
    SET m.Price = m.Price * 1.20
    FROM Restaurant.dbo.MENU m -- Исправлено: было NEWU, должно быть MENU
    JOIN inserted i ON m.MenuId = i.MenuId;
END;
GO

INSERT INTO Restaurant.dbo.MENU (Name, Description, Price)
VALUES ('Burger', 'Delicious beef burger', 5.00),
    ('Pizza', 'Cheese and tomato pizza', 7.50),
    ('Pasta', 'Creamy Alfredo pasta', 6.00);

SELECT * FROM Restaurant.dbo.MENU;
GO

DISABLE TRIGGER TriggerIncreasePriceOnInsert ON Restaurant.dbo.MENU;
GO

INSERT INTO Restaurant.dbo.MENU (Name, Description, Price)
VALUES ('Salad', 'Fresh green salad', 4.00),
    ('Platter', 'Assorted platter', 12.00);

SELECT * FROM Restaurant.dbo.MENU;
GO

ENABLE TRIGGER TriggerIncreasePriceOnInsert ON Restaurant.dbo.MENU;
GO

-- 2.3.2 --Убедимся, что триггер ещё Создать триггер на ALL_STAFF, который автоматически добавит запись в SERVING_STAFF, 
-- если в ALL_STAFF вставляется сотрудник с должностью "Master".

IF OBJECT_ID('trg_InsertServiceStaff', 'TR') IS NOT NULL
    DROP TRIGGER trg_InsertServiceStaff;
GO

CREATE TRIGGER trg_InsertServiceStaff
ON ALL_STAFF
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Вставляем в SERVING_STAFF только тех, у кого Position = 'Master'
    INSERT INTO SERVING_STAFF (StaffId)
    SELECT I.StaffId
    FROM INSERTED I
    WHERE I.Position = 'Master';  -- Changed from "Master" to 'Master'
END;
GO

INSERT INTO ALL_STAFF (FullName, PhoneNumber, Position, Salary)
VALUES('John Doe', '1234567899', 'Manager', 5000.00),
    ('Jana Smith', '0807050321', 'Chef', 4000.00),
    ('Emily Johnson', '1111221311', 'Waiter', 2500.00),
    ('Michael Brown', '444555666', 'Master', 2500.00),
    ('Sarah Davis', '7778889999', 'Clerk', 2000.00);

SELECT * FROM SERVING_STAFF;


-- 2.3.3 Напишите DELETE триггер, который реализует комплексное многовариантное ограничение к базе данных и следит
-- за соблюдением данного ограничения для каждого введенного, измененного, или удаленного кортежа.

GO
CREATE TRIGGER trg_validateOrderCapacity
ON ORDERS_MENU
FOR INSERT, UPDATE
AS
BEGIN
-- Проверка: заказ не должен превышать вместимость стола
IF EXISTS (
    SELECT 1
    FROM inserted i
    JOIN ORDERS o ON o.OrderId = i.OrderId
    JOIN TABLES t ON t.TableId = o.TableId
    GROUP BY o.OrderId, t.Capacity
    HAVING SUM(i.Quantity) > MAX(t.Capacity)
)
BEGIN
    ROLLBACK;
    RAISERROR('Общее количество заказанных блюд превышает вместимость стола!', 16, 1);
END;
END;
GO

-- 2.3.4 Создать ddl тригер при попытке удалить отношение тест_menu вместо удаление заменяет все значения все полей name на удалено,
-- удалить тригег, создать хранимую процедуру которая удаляет отношение тест_меню, запустить потом удать 

-- Шаг 1: Создание копии таблицы MENU как Тест_Menu
SELECT * INTO Restaurant.dbo.Test_Menu FROM Restaurant.dbo.MENU;

-- Шаг 2: Создание DDL-триггера, который предотвращает удаление таблицы Test_Menu
-- и заменяет значение Name на 'Удалено из БД'
GO
CREATE TRIGGER trg_prevent_drop_test_menu
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    BEGIN TRY
        DECLARE @event XML = EVENTDATA();
        DECLARE @objectName NVARCHAR(128) = @event.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)');
        DECLARE @schemaName NVARCHAR(128) = @event.value('(/EVENT_INSTANCE/SchemaName)[1]', 'NVARCHAR(128)');

        IF @objectName = 'Test_Menu' AND @schemaName = 'dbo'
        BEGIN
            ROLLBACK;
            IF OBJECT_ID(N'Restaurant.dbo.Test_Menu', 'U') IS NOT NULL
            BEGIN
                UPDATE Restaurant.dbo.Test_Menu
                SET Name = 'Удалено из БД';
            END
            PRINT 'permision to delete Test_Menu denied. attribute Name updated.';
        END
    END TRY
    BEGIN CATCH
        PRINT 'error in trigger Test_Menu.';
    END CATCH
END;
GO

-- Шаг 3: Попытка удалить таблицу (триггер предотвратит)
DROP TABLE Restaurant.dbo.Test_Menu;

-- Шаг 4: Проверка — таблица существует, значения Name заменены
SELECT * FROM Restaurant.dbo.Test_Menu;

-- Шаг 5: Удаление триггера
DROP TRIGGER trg_prevent_drop_test_menu ON DATABASE;
GO

-- Шаг 6: Создание процедуры для удаления таблицы Test_Menu
CREATE PROCEDURE dbo.Delete_Test_Menu
AS
BEGIN
    DROP TABLE Restaurant.dbo.Test_Menu;
END;
GO

-- Шаг 7: Вызов процедуры
EXEC dbo.Delete_Test_Menu;

-- Шаг 8: Удаление процедуры
DROP PROCEDURE dbo.Delete_Test_Menu;


-- 2.3.5 Напишите DDL триггер, который запрещает изменение заданного поля, используемого для связи между таблицами.

GO
CREATE TRIGGER trg_PreventAlterStaffId
    ON DATABASE
    FOR ALTER_TABLE
    AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EventData XML = EVENTDATA();
    DECLARE @TableName NVARCHAR(100) = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(100)');
    DECLARE @TSQLCommand NVARCHAR(MAX) = @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)');

    -- Проверка: если таблица ALL_STAFF и есть попытка изменить поле StaffId
    IF @TableName = 'ALL_STAFF' AND @TSQLCommand LIKE '%ALTER COLUMN StaffId%'
    BEGIN
        RAISERROR('denied to change attribute StaffId , is used like reference.', 16, 1);
        ROLLBACK;
    END
END;
GO



-- 2.3.6 Напишите DDL триггер, который при изменении свойств определенного поля, сделал бы автоматически схожие изменения в остальных таблицах.
GO
CREATE TRIGGER trg_SyncPhoneNumberField
    ON DATABASE
    FOR ALTER_TABLE
    AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EventData XML = EVENTDATA();
    DECLARE @TableName NVARCHAR(128) = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)');
    DECLARE @TSQLCommand NVARCHAR(MAX) = @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)');

    -- Только если меняется поле PhoneNumber в таблице ALL_STAFF
    IF @TableName = 'ALL_STAFF' AND @TSQLCommand LIKE '%ALTER COLUMN PhoneNumber%'
    BEGIN
        -- Получаем новый тип данных из команды ALTER
        DECLARE @NewType NVARCHAR(50);
        SET @NewType = SUBSTRING(@TSQLCommand, 
                                CHARINDEX('PhoneNumber', @TSQLCommand) + 12, 
                                CHARINDEX(')', @TSQLCommand, CHARINDEX('PhoneNumber', @TSQLCommand)) - (CHARINDEX('PhoneNumber', @TSQLCommand) + 12));
        
        -- Применяем изменения к другим таблицам
        DECLARE @SQL NVARCHAR(MAX);
        
        -- Для таблицы SERVING_STAFF
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
                  WHERE TABLE_NAME = 'SERVING_STAFF' AND COLUMN_NAME = 'PhoneNumber')
        BEGIN
            SET @SQL = 'ALTER TABLE SERVING_STAFF ALTER COLUMN PhoneNumber ' + @NewType;
            EXEC(@SQL);
        END
        
        -- Для таблицы MANAGERS (пример дополнительной таблицы)
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
                  WHERE TABLE_NAME = 'MANAGERS' AND COLUMN_NAME = 'PhoneNumber')
        BEGIN
            SET @SQL = 'ALTER TABLE MANAGERS ALTER COLUMN PhoneNumber ' + @NewType;
            EXEC(@SQL);
        END
    END;
END;
GO


-- 2.3.7 Напишите триггер, который запрещает изменение схемы базы данных вне рабочего времени.
-- GO  
-- CREATE TRIGGER trg_restrict_schema_change  
--     ON DATABASE  
--     FOR ALTER_TABLE, CREATE_TABLE, DROP_TABLE  
--     AS  
-- BEGIN  
--     DECLARE @current_hour INT;  
--     SET @current_hour = DATEPART(HOUR, GETDATE());

--     -- Запрещаем изменения с 17:00 до 9:00 (после работы и ночью)
--     IF @current_hour >= 1 OR @current_hour < 2  
--     BEGIN  
--         RAISERROR('permision denied to change in this time (from 17:00 till 18:00).', 16, 1);  
--         ROLLBACK;  
--     END  
-- END;  
-- GO


-- 2.3.8 Напишите LOGIN триггер, который запрещает заданному пользователю вход в систему, 
-- если у него уже есть 3 активных подключения с данным логином к одному экземпляру SQL Server.
-- Триггер должен считать количество активных подключений для данного логина из системного представления sys.dm_exec_sessions.

-- Удаляем триггер если существует
IF EXISTS (SELECT 1 FROM sys.server_triggers WHERE name = 'trg_limit_connections')
    DROP TRIGGER trg_limit_connections ON ALL SERVER;
GO

--Создаем триггер
CREATE TRIGGER trg_limit_connections
ON ALL SERVER
FOR LOGON
AS
BEGIN
    DECLARE @login_name NVARCHAR(100);
    SET @login_name = ORIGINAL_LOGIN();

    -- Проверяем количество активных соединений для данного пользователя
    IF (
        SELECT COUNT(*)
        FROM sys.dm_exec_sessions
        WHERE login_name = @login_name 
          AND is_user_process = 1
          AND status = 'running'
    ) >= 3
    BEGIN
        ROLLBACK;
        RAISERROR('No more than 3 connections per database', 16, 1);
    END;
END;
GO

---------------------------------------------------------------end lab 2--------------------------------------------------

--------------------------------------------------------------- Лабораторная 3 --------------------------------------------------
-- 3.1.1 Транзакция для вывода блюд, где стоимость ингредиентов ниже средней
BEGIN TRANSACTION;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT m.Name, m.Price
FROM MENU m
JOIN MENU_INGREDIENTS mi ON m.MenuID = mi.MenuID
JOIN INGREDIENTS i ON mi.IngredientID = i.IngredientID
GROUP BY m.MenuID, m.Name, m.Price
HAVING AVG(i.Cost) < (SELECT AVG(Cost) FROM INGREDIENTS);

COMMIT TRANSACTION;

-- 3.1.2 Транзакция с ошибкой и откатом
BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Попытка вставить заказ с несуществующим MenuID (вызовет ошибку)
    INSERT INTO ORDERS_MENU (OrderID, MenuID, Quantity)
    VALUES (1, 999, 2);
    
    COMMIT TRANSACTION;
    PRINT 'transaction completed successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'transaction error: ' + ERROR_MESSAGE();
END CATCH;

-- 3.1.3 Транзакция с несколькими INSERT в таблицу ALL_STAFF
BEGIN TRY
    BEGIN TRANSACTION;
    
    INSERT INTO ALL_STAFF (FullName, PhoneNumber, Position, Salary)
    VALUES ('Ivan Petrov', '1234567890', 'Waiter', 2500.00);
    
    INSERT INTO ALL_STAFF (FullName, PhoneNumber, Position, Salary)
    VALUES ('Maria Sidorova', '0987654321', 'Chef', NULL); -- Ошибка: Salary не может быть NULL
    
    INSERT INTO ALL_STAFF (FullName, PhoneNumber, Position, Salary)
    VALUES ('Alexey Ivanov', '1122334455', 'Manager', 5000.00);
    
    COMMIT TRANSACTION;
    PRINT 'all workers added successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'error on adding workers: ' + ERROR_MESSAGE();
END CATCH;

-- 3.1.4 Транзакция для вывода информации о заказах с суммой ниже средней
BEGIN TRANSACTION;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT a.FullName AS StaffName, o.TotalAmount
FROM ORDERS o
JOIN SERVING_STAFF s ON o.ServingStaffID = s.ServingStaffID
JOIN ALL_STAFF a ON s.StaffID = a.StaffID
WHERE o.TotalAmount < (SELECT AVG(TotalAmount) FROM ORDERS);

COMMIT TRANSACTION;

-- 3.1.5 Транзакция для обновления цен блюд, добавленных более года назад
-- Добавляем столбец CreationDate в таблицу MENU, если его еще нет
-- Сначала добавляем столбец (в отдельном пакете)
ALTER TABLE Restaurant.dbo.MENU ADD CreationDate DATETIME DEFAULT GETDATE();

GO
BEGIN TRANSACTION;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRY
    -- Обновляем цены блюд, добавленных более года назад
    UPDATE Restaurant.dbo.MENU
    SET Price = Price * 1.10 -- Увеличиваем цену на 10%
    WHERE CreationDate < DATEADD(MINUTE, -1, GETDATE());
    
    -- Проверяем количество обновленных строк
    DECLARE @RowsAffected INT = @@ROWCOUNT;
    
    -- Выводим информацию об обновленных блюдах
    SELECT m.MenuID, m.Name, m.Price AS NewPrice, m.CreationDate
    FROM Restaurant.dbo.MENU m
    WHERE CreationDate < DATEADD(MINUTE, -1, GETDATE());
    
    COMMIT TRANSACTION;
    
    PRINT 'updated prices' + CAST(@RowsAffected AS VARCHAR) + 'for menu items.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'error on updating ' + ERROR_MESSAGE();
    PRINT 'rollback transaction.';
END CATCH;
GO

--3.2.1  Транзакции с высокой вероятностью взаимоблокировки
-- Транзакция 1 (доступ к таблицам в порядке: ORDERS -> MENU)
BEGIN TRANSACTION;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Обновляем заказ
UPDATE ORDERS 
SET TotalAmount = TotalAmount * 1.1 
WHERE OrderID = 1;

-- Искусственная задержка для создания условий для взаимоблокировки
WAITFOR DELAY '00:00:05';

-- Обновляем меню (второй доступ)
UPDATE MENU
SET Price = Price * 1.05
WHERE MenuID = 1;

COMMIT TRANSACTION;
GO

-- Транзакция 2 (доступ к таблицам в порядке: MENU -> ORDERS)
BEGIN TRANSACTION;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Обновляем меню (первый доступ)
UPDATE MENU
SET Price = Price * 1.05
WHERE MenuID = 1;

-- Искусственная задержка
WAITFOR DELAY '00:00:05';

-- Обновляем заказ (второй доступ)
UPDATE ORDERS 
SET TotalAmount = TotalAmount * 1.1 
WHERE OrderID = 1;

COMMIT TRANSACTION;
GO


--3.2.2 Оптимизированные транзакции с меньшей вероятностью взаимоблокировки
-- Транзакция 1 (оптимизированная)
BEGIN TRANSACTION;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET DEADLOCK_PRIORITY HIGH; -- Повышаем приоритет этой транзакции

-- Блокируем таблицы в одинаковом порядке
UPDATE ORDERS WITH (ROWLOCK) -- Используем более мелкие блокировки
SET TotalAmount = TotalAmount * 1.1 
WHERE OrderID = 1;

UPDATE MENU WITH (ROWLOCK)
SET Price = Price * 1.05
WHERE MenuID = 1;

COMMIT TRANSACTION;
GO

-- Транзакция 2 (оптимизированная)
BEGIN TRANSACTION;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET DEADLOCK_PRIORITY LOW; -- Понижаем приоритет

-- Тот же порядок блокировки таблиц
UPDATE ORDERS WITH (ROWLOCK)
SET TotalAmount = TotalAmount * 1.1 
WHERE OrderID = 1;

UPDATE MENU WITH (ROWLOCK)
SET Price = Price * 1.05
WHERE MenuID = 1;

COMMIT TRANSACTION;
GO


--3.2.3 Транзакция с явной блокировкой таблицы
-- Транзакция с явной блокировкой таблицы MENU
BEGIN TRANSACTION;

-- Блокируем всю таблицу MENU на время транзакции
-- TABLOCKX - эксклюзивная блокировка таблицы
-- HOLDLOCK - удерживаем блокировку до конца транзакции
SELECT * FROM MENU WITH (TABLOCKX, HOLDLOCK);

-- Выполняем операции с заблокированной таблицей
UPDATE MENU
SET Price = Price * 1.10
WHERE MenuID IN (1, 2, 3);

-- Другие операции
INSERT INTO ORDERS_MENU (OrderID, MenuID, Quantity)
VALUES (1, 1, 2), (1, 2, 1);

-- Проверяем изменения
SELECT * FROM MENU WHERE MenuID IN (1, 2, 3);

COMMIT TRANSACTION; -- Разблокировка таблицы
GO

---------------------------------------------------------end lab 3--------------------------------------------------

-----------------------------------------------------------lab 3.1--------------------------------------------------

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


----------------------------------------------------------lab 4--------------------------------------------------
-- 4.1.1 Запрос для суммы оценок по студентам и дисциплинам (аналог для Restaurant)
SELECT DISTINCT 
    o.ServingStaffID AS StaffID, 
    m.MenuID, 
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
JOIN MENU m ON om.MenuID = m.MenuID
WHERE o.IsClosed = 1
GROUP BY GROUPING SETS ((o.ServingStaffID), (m.MenuID));

-- 4.1.2 Переписанный запрос без GROUPING SETS
SELECT 
    o.ServingStaffID AS StaffID, 
    NULL AS MenuID, 
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
WHERE o.IsClosed = 1
GROUP BY o.ServingStaffID

UNION ALL

-- По блюдам
SELECT 
    NULL AS StaffID, 
    m.MenuID, 
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN MENU m ON om.MenuID = m.MenuID
JOIN ORDERS o ON om.OrderID = o.OrderID
WHERE o.IsClosed = 1
GROUP BY m.MenuID;





-- 4.1.2 Аналог ROLLUP для Restaurant (персона и блюдо с итогами)
SELECT DISTINCT 
    o.ServingStaffID AS StaffID, 
    m.MenuID, 
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
JOIN MENU m ON om.MenuID = m.MenuID
WHERE o.IsClosed = 1
GROUP BY ROLLUP (o.ServingStaffID, m.MenuID);



-- 4.1.2.1 Детализация по персонам и блюдам
SELECT 
    o.ServingStaffID AS StaffID, 
    m.MenuID, 
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
JOIN MENU m ON om.MenuID = m.MenuID
WHERE o.IsClosed = 1
GROUP BY o.ServingStaffID, m.MenuID

UNION ALL

-- Итоги по персонам
SELECT 
    o.ServingStaffID AS StaffID, 
    NULL AS MenuID, 
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
WHERE o.IsClosed = 1
GROUP BY o.ServingStaffID

UNION ALL

-- Общий итог
SELECT 
    NULL AS StaffID, 
    NULL AS MenuID, 
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
WHERE o.IsClosed = 1;



--4.1.3 Аналог CUBE для Restaurant (персона, блюдо, стол с итогами)
SELECT DISTINCT 
    o.ServingStaffID AS StaffID,
    m.MenuID,
    t.TableID,
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
JOIN MENU m ON om.MenuID = m.MenuID
JOIN TABLES t ON o.TableID = t.TableID
WHERE o.IsClosed = 1
GROUP BY CUBE (o.ServingStaffID, m.MenuID, t.TableID);


--4.1.3.1 Все возможные комбинации группировок
-- Полная детализация
SELECT 
    o.ServingStaffID AS StaffID,
    m.MenuID,
    t.TableID,
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
JOIN MENU m ON om.MenuID = m.MenuID
JOIN TABLES t ON o.TableID = t.TableID
WHERE o.IsClosed = 1
GROUP BY o.ServingStaffID, m.MenuID, t.TableID

UNION ALL

-- Группировка по StaffID и MenuID
SELECT 
    o.ServingStaffID AS StaffID,
    m.MenuID,
    NULL AS TableID,
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
JOIN MENU m ON om.MenuID = m.MenuID
WHERE o.IsClosed = 1
GROUP BY o.ServingStaffID, m.MenuID

UNION ALL

-- Группировка по StaffID и TableID
SELECT 
    o.ServingStaffID AS StaffID,
    NULL AS MenuID,
    t.TableID,
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
JOIN TABLES t ON o.TableID = t.TableID
WHERE o.IsClosed = 1
GROUP BY o.ServingStaffID, t.TableID

UNION ALL

-- Группировка по MenuID и TableID
SELECT 
    NULL AS StaffID,
    m.MenuID,
    t.TableID,
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
JOIN MENU m ON om.MenuID = m.MenuID
JOIN TABLES t ON o.TableID = t.TableID
WHERE o.IsClosed = 1
GROUP BY m.MenuID, t.TableID

UNION ALL

-- Группировка только по StaffID
SELECT 
    o.ServingStaffID AS StaffID,
    NULL AS MenuID,
    NULL AS TableID,
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
WHERE o.IsClosed = 1
GROUP BY o.ServingStaffID

UNION ALL

-- Группировка только по MenuID
SELECT 
    NULL AS StaffID,
    m.MenuID,
    NULL AS TableID,
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN MENU m ON om.MenuID = m.MenuID
JOIN ORDERS o ON om.OrderID = o.OrderID
WHERE o.IsClosed = 1
GROUP BY m.MenuID

UNION ALL

-- Группировка только по TableID
SELECT 
    NULL AS StaffID,
    NULL AS MenuID,
    t.TableID,
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
JOIN TABLES t ON o.TableID = t.TableID
WHERE o.IsClosed = 1
GROUP BY t.TableID

UNION ALL

-- Общий итог
SELECT 
    NULL AS StaffID,
    NULL AS MenuID,
    NULL AS TableID,
    SUM(om.Quantity) AS TotalQuantity
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
WHERE o.IsClosed = 1;



--4.2 Для Restaurant: группировка по блюду и столу с общим количеством заказов
SELECT 
    m.MenuID AS DishID,
    o.TableID,
    COUNT(*) AS OrderCount,
    SUM(om.Quantity) AS TotalQuantity,
    SUM(SUM(om.Quantity)) OVER () AS GrandTotal
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
JOIN MENU m ON om.MenuID = m.MenuID
GROUP BY m.MenuID, o.TableID;



--4.3 Для Restaurant: группировка по блюду и официанту
SELECT 
    m.MenuID AS DishID,
    o.ServingStaffID AS StaffID,
    COUNT(*) AS OrderCount,
    SUM(om.Quantity) AS TotalQuantity,
    SUM(SUM(om.Quantity)) OVER () AS GrandTotal
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
JOIN MENU m ON om.MenuID = m.MenuID
GROUP BY m.MenuID, o.ServingStaffID;



--4.4 Для Restaurant: группировка по блюду, официанту и столу
SELECT 
    m.MenuID AS DishID,
    o.ServingStaffID AS StaffID,
    o.TableID,
    COUNT(*) AS OrderCount,
    SUM(om.Quantity) AS TotalQuantity,
    SUM(SUM(om.Quantity)) OVER () AS GrandTotal
FROM ORDERS_MENU om
JOIN ORDERS o ON om.OrderID = o.OrderID
JOIN MENU m ON om.MenuID = m.MenuID
GROUP BY m.MenuID, o.ServingStaffID, o.TableID;

--4.5.1
-- Исходный вложенный запрос
SELECT Name, Price
FROM MENU
WHERE Price > (SELECT AVG(Price) FROM MENU);

-- С CTE
WITH AvgPrice AS (
    SELECT AVG(Price) AS AveragePrice
    FROM MENU
)
SELECT Name, Price
FROM MENU, AvgPrice
WHERE Price > AvgPrice.AveragePrice;

--4.5.2
-- Исходный вложенный запрос
SELECT FullName, Position
FROM ALL_STAFF
WHERE StaffID IN (
    SELECT StaffID 
    FROM SERVING_STAFF
    WHERE ServingStaffID IN (
        SELECT ServingStaffID 
        FROM ORDERS 
        WHERE TotalAmount > 30
    )
);

-- С CTE - общее табличное выражение
WITH HighOrders AS (
    SELECT ServingStaffID
    FROM ORDERS
    WHERE TotalAmount > 30
),
ServingStaff AS (
    SELECT StaffID
    FROM SERVING_STAFF
    WHERE ServingStaffID IN (SELECT ServingStaffID FROM HighOrders)
)
SELECT FullName, Position
FROM ALL_STAFF
WHERE StaffID IN (SELECT StaffID FROM ServingStaff);

