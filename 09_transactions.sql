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