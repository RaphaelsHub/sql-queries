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