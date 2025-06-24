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