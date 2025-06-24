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
