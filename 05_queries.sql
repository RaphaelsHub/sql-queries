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

-- Update the new column with default value 'false' (0 in SQL Server)
UPDATE ORDERS
SET IsClosed = CASE
    WHEN OrderId > 6 THEN 0
    ELSE 1
END;

-- Удаляем топ N ингредиентов, стоимость которых выше средней стоимости всех ингредиентов, и выводим удаленные строки
DELETE TOP (3) FROM INGREDIENTS
OUTPUT deleted.*
WHERE Cost > (SELECT AVG(Cost) FROM INGREDIENTS);

-- Условное удаление с подзапросом однотабличное (с агрегацией или группировкой)
-- Удаляем ингредиенты, стоимость которых выше средней стоимости всех ингредиентов и выводим удаленные строки
DELETE FROM INGREDIENTS
OUTPUT deleted.*
WHERE Cost > (SELECT AVG(Cost) FROM INGREDIENTS);

-- Обновление кортежей одной таблицы с использованием TOP
-- Обновляем зарплату топ-3 сотрудников, увеличивая ее на 10%, и выводим обновленные строки
UPDATE TOP (3) ALL_STAFF
SET Salary = Salary * 1.10
OUTPUT inserted.*;

-- Обновление с подзапросом многотабличное
-- Закрываем заказы, которые были сделаны более 30 дней назад, и выводим обновленные строки
UPDATE ORDERS
SET IsClosed = 1
OUTPUT inserted.*
WHERE OrderDate < (
    SELECT DATEADD(DAY, -30, GETDATE())
);


--4.2.1 Вставка в существующее отношение результата запроса (INSERT INTO с SELECT)
-- Создадим таблицу MANAGERS

CREATE TABLE MANAGERS (
    ManagerId INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(100) NOT NULL,
    PhoneNumber NVARCHAR(15) NOT NULL,
    Salary DECIMAL(10,2) NOT NULL
);

-- Вставляем данные в таблицу MANAGERS из таблицы ALL_STAFF и выводим вставленные данные с помощью OUTPUT
INSERT INTO MANAGERS (FullName, PhoneNumber, Salary)
OUTPUT inserted.* 
--inserted.FullName, inserted.PhoneNumber, inserted.Salary
SELECT FullName, PhoneNumber, Salary
FROM ALL_STAFF
WHERE Position = 'Manager';


--4.2.2 Вставка результата запроса SELECT из одного отношения (отношение-источник) в новое отношение NEW_Table, созданное мгновенно (SELECT INTO)

-- Создадим таблицу WAITERS и вставим данные из таблицы ALL_STAFF
SELECT FullName, PhoneNumber, Salary
INTO WAITERS 
FROM ALL_STAFF 
WHERE Position = 'Waiter';

