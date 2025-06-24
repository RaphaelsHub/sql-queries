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