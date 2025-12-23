-- PopulateTables.sql
-- Script per popolare le tabelle del database devShop con dati di esempio
-- Basato sul lab LAB501 Microsoft Ignite 2025

USE [l501devshopdb];
GO

PRINT '=== Popolamento Tabelle devShop Database ===';
PRINT 'Data: ' + CONVERT(VARCHAR, GETDATE(), 120);
GO

-- ==============================================
-- Inserimento Categories
-- ==============================================
PRINT 'Inserimento categorie...';
GO

SET IDENTITY_INSERT dbo.Categories ON;
GO

INSERT INTO dbo.Categories (CategoryID, CategoryName, Description, ImageUrl, IsActive)
VALUES
    (1, 'Electronics', 'Electronic devices and accessories', '/images/categories/electronics.jpg', 1),
    (2, 'Computers', 'Computers, laptops, and peripherals', '/images/categories/computers.jpg', 1),
    (3, 'Software', 'Software applications and licenses', '/images/categories/software.jpg', 1),
    (4, 'Gaming', 'Gaming consoles, games, and accessories', '/images/categories/gaming.jpg', 1),
    (5, 'Networking', 'Network equipment and accessories', '/images/categories/networking.jpg', 1),
    (6, 'Accessories', 'Various tech accessories', '/images/categories/accessories.jpg', 1);
GO

SET IDENTITY_INSERT dbo.Categories OFF;
GO

PRINT 'Categorie inserite: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

-- ==============================================
-- Inserimento Products
-- ==============================================
PRINT 'Inserimento prodotti...';
GO

SET IDENTITY_INSERT dbo.Products ON;
GO

INSERT INTO dbo.Products (ProductID, ProductName, CategoryID, UnitPrice, UnitsInStock, Description, ImageUrl, IsActive, IsFeatured)
VALUES
    -- Electronics
    (1, 'Wireless Mouse', 1, 29.99, 150, 'Ergonomic wireless mouse with USB receiver', '/images/products/mouse.jpg', 1, 1),
    (2, 'Mechanical Keyboard', 1, 89.99, 75, 'RGB mechanical gaming keyboard', '/images/products/keyboard.jpg', 1, 1),
    (3, 'USB-C Hub', 1, 49.99, 200, '7-in-1 USB-C hub with multiple ports', '/images/products/usbhub.jpg', 1, 0),
    (4, 'Webcam HD', 1, 79.99, 120, '1080p HD webcam with microphone', '/images/products/webcam.jpg', 1, 1),
    (5, 'Headset', 1, 59.99, 100, 'Noise-cancelling wireless headset', '/images/products/headset.jpg', 1, 0),
    
    -- Computers
    (6, 'Laptop i7 16GB', 2, 1299.99, 50, 'High-performance laptop with Intel i7, 16GB RAM, 512GB SSD', '/images/products/laptop.jpg', 1, 1),
    (7, 'Desktop PC', 2, 899.99, 30, 'Desktop computer with AMD Ryzen 5, 16GB RAM', '/images/products/desktop.jpg', 1, 0),
    (8, 'Monitor 27"', 2, 349.99, 80, '27-inch 4K UHD monitor', '/images/products/monitor.jpg', 1, 1),
    (9, 'External SSD 1TB', 2, 129.99, 150, 'Portable external SSD 1TB', '/images/products/ssd.jpg', 1, 0),
    (10, 'Docking Station', 2, 199.99, 60, 'Universal docking station for laptops', '/images/products/dock.jpg', 1, 0),
    
    -- Software
    (11, 'Office Suite License', 3, 149.99, 500, 'Productivity suite license (1 year)', '/images/products/office.jpg', 1, 1),
    (12, 'Antivirus Software', 3, 39.99, 1000, 'Antivirus protection (1 year, 3 devices)', '/images/products/antivirus.jpg', 1, 0),
    (13, 'Photo Editing Software', 3, 79.99, 300, 'Professional photo editing software', '/images/products/photoedit.jpg', 1, 0),
    (14, 'Video Editing Pro', 3, 299.99, 150, 'Professional video editing software', '/images/products/videoedit.jpg', 1, 1),
    
    -- Gaming
    (15, 'Gaming Console', 4, 499.99, 40, 'Latest generation gaming console', '/images/products/console.jpg', 1, 1),
    (16, 'Gaming Controller', 4, 69.99, 200, 'Wireless gaming controller', '/images/products/controller.jpg', 1, 1),
    (17, 'VR Headset', 4, 399.99, 25, 'Virtual reality headset', '/images/products/vrheadset.jpg', 1, 1),
    (18, 'Gaming Chair', 4, 249.99, 50, 'Ergonomic gaming chair', '/images/products/gamingchair.jpg', 1, 0),
    
    -- Networking
    (19, 'WiFi Router', 5, 129.99, 100, 'Dual-band WiFi 6 router', '/images/products/router.jpg', 1, 1),
    (20, 'Network Switch 8-port', 5, 49.99, 80, '8-port gigabit network switch', '/images/products/switch.jpg', 1, 0),
    (21, 'Ethernet Cable 10ft', 5, 9.99, 500, 'Cat 6 ethernet cable 10 feet', '/images/products/cable.jpg', 1, 0),
    
    -- Accessories
    (22, 'Laptop Bag', 6, 39.99, 150, 'Protective laptop bag 15-inch', '/images/products/bag.jpg', 1, 0),
    (23, 'Phone Stand', 6, 19.99, 300, 'Adjustable phone stand', '/images/products/phonestand.jpg', 1, 0),
    (24, 'Cable Organizer', 6, 14.99, 400, 'Cable management organizer', '/images/products/cableorg.jpg', 1, 0),
    (25, 'Screen Cleaner Kit', 6, 12.99, 250, 'Screen cleaning kit with microfiber cloth', '/images/products/cleaner.jpg', 1, 0);
GO

SET IDENTITY_INSERT dbo.Products OFF;
GO

PRINT 'Prodotti inseriti: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

-- ==============================================
-- Inserimento Customers
-- ==============================================
PRINT 'Inserimento clienti...';
GO

SET IDENTITY_INSERT dbo.Customers ON;
GO

INSERT INTO dbo.Customers (CustomerID, FirstName, LastName, Email, Phone, Address, City, State, ZipCode, Country, IsActive)
VALUES
    (1, 'John', 'Doe', 'john.doe@email.com', '555-0101', '123 Main St', 'Seattle', 'WA', '98101', 'USA', 1),
    (2, 'Jane', 'Smith', 'jane.smith@email.com', '555-0102', '456 Oak Ave', 'Portland', 'OR', '97201', 'USA', 1),
    (3, 'Robert', 'Johnson', 'robert.j@email.com', '555-0103', '789 Pine Rd', 'San Francisco', 'CA', '94102', 'USA', 1),
    (4, 'Maria', 'Garcia', 'maria.garcia@email.com', '555-0104', '321 Elm St', 'Los Angeles', 'CA', '90001', 'USA', 1),
    (5, 'Michael', 'Brown', 'michael.brown@email.com', '555-0105', '654 Maple Dr', 'Denver', 'CO', '80201', 'USA', 1),
    (6, 'Emily', 'Davis', 'emily.davis@email.com', '555-0106', '987 Cedar Ln', 'Austin', 'TX', '73301', 'USA', 1),
    (7, 'David', 'Miller', 'david.miller@email.com', '555-0107', '147 Birch Ct', 'Boston', 'MA', '02101', 'USA', 1),
    (8, 'Sarah', 'Wilson', 'sarah.wilson@email.com', '555-0108', '258 Spruce Way', 'Chicago', 'IL', '60601', 'USA', 1),
    (9, 'James', 'Moore', 'james.moore@email.com', '555-0109', '369 Willow Blvd', 'Miami', 'FL', '33101', 'USA', 1),
    (10, 'Lisa', 'Taylor', 'lisa.taylor@email.com', '555-0110', '741 Ash Pkwy', 'New York', 'NY', '10001', 'USA', 1);
GO

SET IDENTITY_INSERT dbo.Customers OFF;
GO

PRINT 'Clienti inseriti: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

-- ==============================================
-- Inserimento Orders
-- ==============================================
PRINT 'Inserimento ordini...';
GO

SET IDENTITY_INSERT dbo.Orders ON;
GO

INSERT INTO dbo.Orders (OrderID, CustomerID, OrderDate, TotalAmount, OrderStatus, ShippingAddress, ShippingCity, ShippingState, ShippingZipCode, PaymentStatus)
VALUES
    (1, 1, DATEADD(DAY, -10, GETDATE()), 429.97, 'Completed', '123 Main St', 'Seattle', 'WA', '98101', 'Paid'),
    (2, 2, DATEADD(DAY, -9, GETDATE()), 1299.99, 'Shipped', '456 Oak Ave', 'Portland', 'OR', '97201', 'Paid'),
    (3, 3, DATEADD(DAY, -8, GETDATE()), 89.99, 'Completed', '789 Pine Rd', 'San Francisco', 'CA', '94102', 'Paid'),
    (4, 4, DATEADD(DAY, -7, GETDATE()), 569.98, 'Processing', '321 Elm St', 'Los Angeles', 'CA', '90001', 'Paid'),
    (5, 5, DATEADD(DAY, -6, GETDATE()), 149.99, 'Completed', '654 Maple Dr', 'Denver', 'CO', '80201', 'Paid'),
    (6, 6, DATEADD(DAY, -5, GETDATE()), 899.98, 'Shipped', '987 Cedar Ln', 'Austin', 'TX', '73301', 'Paid'),
    (7, 7, DATEADD(DAY, -4, GETDATE()), 299.99, 'Processing', '147 Birch Ct', 'Boston', 'MA', '02101', 'Paid'),
    (8, 8, DATEADD(DAY, -3, GETDATE()), 179.97, 'Pending', '258 Spruce Way', 'Chicago', 'IL', '60601', 'Pending'),
    (9, 9, DATEADD(DAY, -2, GETDATE()), 499.99, 'Completed', '369 Willow Blvd', 'Miami', 'FL', '33101', 'Paid'),
    (10, 10, DATEADD(DAY, -1, GETDATE()), 1649.97, 'Processing', '741 Ash Pkwy', 'New York', 'NY', '10001', 'Paid');
GO

SET IDENTITY_INSERT dbo.Orders OFF;
GO

PRINT 'Ordini inseriti: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

-- ==============================================
-- Inserimento OrderDetails
-- ==============================================
PRINT 'Inserimento dettagli ordini...';
GO

SET IDENTITY_INSERT dbo.OrderDetails ON;
GO

INSERT INTO dbo.OrderDetails (OrderDetailID, OrderID, ProductID, Quantity, UnitPrice, Discount)
VALUES
    -- Order 1 (Customer 1)
    (1, 1, 8, 1, 349.99, 0.00),
    (2, 1, 3, 1, 49.99, 0.00),
    (3, 1, 1, 1, 29.99, 0.00),
    
    -- Order 2 (Customer 2)
    (4, 2, 6, 1, 1299.99, 0.00),
    
    -- Order 3 (Customer 3)
    (5, 3, 2, 1, 89.99, 0.00),
    
    -- Order 4 (Customer 4)
    (6, 4, 15, 1, 499.99, 0.00),
    (7, 4, 16, 1, 69.99, 0.00),
    
    -- Order 5 (Customer 5)
    (8, 5, 11, 1, 149.99, 0.00),
    
    -- Order 6 (Customer 6)
    (9, 6, 7, 1, 899.99, 0.00),
    
    -- Order 7 (Customer 7)
    (10, 7, 14, 1, 299.99, 0.00),
    
    -- Order 8 (Customer 8)
    (11, 8, 19, 1, 129.99, 0.00),
    (12, 8, 20, 1, 49.99, 0.00),
    
    -- Order 9 (Customer 9)
    (13, 9, 15, 1, 499.99, 0.00),
    
    -- Order 10 (Customer 10)
    (14, 10, 6, 1, 1299.99, 0.00),
    (15, 10, 8, 1, 349.99, 0.00);
GO

SET IDENTITY_INSERT dbo.OrderDetails OFF;
GO

PRINT 'Dettagli ordini inseriti: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

-- ==============================================
-- Verifica dati inseriti
-- ==============================================
PRINT '';
PRINT '=== Riepilogo Dati Inseriti ===';
PRINT 'Categories: ' + CAST((SELECT COUNT(*) FROM dbo.Categories) AS VARCHAR);
PRINT 'Products: ' + CAST((SELECT COUNT(*) FROM dbo.Products) AS VARCHAR);
PRINT 'Customers: ' + CAST((SELECT COUNT(*) FROM dbo.Customers) AS VARCHAR);
PRINT 'Orders: ' + CAST((SELECT COUNT(*) FROM dbo.Orders) AS VARCHAR);
PRINT 'OrderDetails: ' + CAST((SELECT COUNT(*) FROM dbo.OrderDetails) AS VARCHAR);
PRINT '';
PRINT 'Popolamento Database Completato!';
GO
