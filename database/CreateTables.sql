-- CreateTables.sql
-- Script per creare le tabelle del database devShop su SQL Server
-- Basato sul lab LAB501 Microsoft Ignite 2025
-- Adattato per SQL Server on-premise (invece di Azure SQL)

USE [l501devshopdb];
GO

PRINT '=== Creazione Tabelle devShop Database ===';
PRINT 'Data: ' + CONVERT(VARCHAR, GETDATE(), 120);
GO

-- Elimina tabelle esistenti (se presenti) in ordine corretto per rispettare le FK
IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL 
BEGIN
    DROP TABLE dbo.OrderDetails;
    PRINT 'Tabella OrderDetails eliminata';
END
GO

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL 
BEGIN
    DROP TABLE dbo.Orders;
    PRINT 'Tabella Orders eliminata';
END
GO

IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL 
BEGIN
    DROP TABLE dbo.Products;
    PRINT 'Tabella Products eliminata';
END
GO

IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL 
BEGIN
    DROP TABLE dbo.Categories;
    PRINT 'Tabella Categories eliminata';
END
GO

IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL 
BEGIN
    DROP TABLE dbo.Customers;
    PRINT 'Tabella Customers eliminata';
END
GO

-- ==============================================
-- Tabella Categories
-- ==============================================
CREATE TABLE dbo.Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    ImageUrl NVARCHAR(500),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);
GO

PRINT 'Tabella Categories creata';
GO

-- ==============================================
-- Tabella Products
-- ==============================================
CREATE TABLE dbo.Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(200) NOT NULL,
    CategoryID INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    UnitsInStock INT NOT NULL DEFAULT 0,
    Description NVARCHAR(MAX),
    ImageUrl NVARCHAR(500),
    IsActive BIT DEFAULT 1,
    IsFeatured BIT DEFAULT 0,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) 
        REFERENCES dbo.Categories(CategoryID) ON DELETE CASCADE,
    CONSTRAINT CK_Products_UnitPrice CHECK (UnitPrice >= 0),
    CONSTRAINT CK_Products_UnitsInStock CHECK (UnitsInStock >= 0)
);
GO

PRINT 'Tabella Products creata';
GO

-- ==============================================
-- Tabella Customers
-- ==============================================
CREATE TABLE dbo.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    Phone NVARCHAR(50),
    Address NVARCHAR(500),
    City NVARCHAR(100),
    State NVARCHAR(100),
    ZipCode NVARCHAR(20),
    Country NVARCHAR(100) DEFAULT 'USA',
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT UQ_Customers_Email UNIQUE (Email)
);
GO

PRINT 'Tabella Customers creata';
GO

-- ==============================================
-- Tabella Orders
-- ==============================================
CREATE TABLE dbo.Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 DEFAULT GETDATE(),
    TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    OrderStatus NVARCHAR(50) DEFAULT 'Pending',
    ShippingAddress NVARCHAR(500),
    ShippingCity NVARCHAR(100),
    ShippingState NVARCHAR(100),
    ShippingZipCode NVARCHAR(20),
    PaymentStatus NVARCHAR(50) DEFAULT 'Pending',
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID) 
        REFERENCES dbo.Customers(CustomerID) ON DELETE CASCADE,
    CONSTRAINT CK_Orders_TotalAmount CHECK (TotalAmount >= 0)
);
GO

PRINT 'Tabella Orders creata';
GO

-- ==============================================
-- Tabella OrderDetails
-- ==============================================
CREATE TABLE dbo.OrderDetails (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 1,
    UnitPrice DECIMAL(18,2) NOT NULL,
    Discount DECIMAL(5,2) DEFAULT 0.00,
    LineTotal AS (Quantity * UnitPrice * (1 - Discount)) PERSISTED,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID) 
        REFERENCES dbo.Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderDetails_Products FOREIGN KEY (ProductID) 
        REFERENCES dbo.Products(ProductID),
    CONSTRAINT CK_OrderDetails_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_OrderDetails_UnitPrice CHECK (UnitPrice >= 0),
    CONSTRAINT CK_OrderDetails_Discount CHECK (Discount >= 0 AND Discount <= 1)
);
GO

PRINT 'Tabella OrderDetails creata';
GO

-- ==============================================
-- Creazione indici per performance
-- ==============================================
PRINT 'Creazione indici...';
GO

CREATE INDEX IX_Products_CategoryID ON dbo.Products(CategoryID);
CREATE INDEX IX_Products_IsActive ON dbo.Products(IsActive);
CREATE INDEX IX_Products_IsFeatured ON dbo.Products(IsFeatured);

CREATE INDEX IX_Orders_CustomerID ON dbo.Orders(CustomerID);
CREATE INDEX IX_Orders_OrderDate ON dbo.Orders(OrderDate);
CREATE INDEX IX_Orders_OrderStatus ON dbo.Orders(OrderStatus);

CREATE INDEX IX_OrderDetails_OrderID ON dbo.OrderDetails(OrderID);
CREATE INDEX IX_OrderDetails_ProductID ON dbo.OrderDetails(ProductID);

CREATE INDEX IX_Customers_Email ON dbo.Customers(Email);
CREATE INDEX IX_Customers_IsActive ON dbo.Customers(IsActive);

CREATE INDEX IX_Categories_IsActive ON dbo.Categories(IsActive);
GO

PRINT 'Indici creati';
GO

-- ==============================================
-- Statistiche finali
-- ==============================================
PRINT '';
PRINT '=== Creazione Database Completata ===';
PRINT 'Tabelle create:';
PRINT '  - Categories';
PRINT '  - Products';
PRINT '  - Customers';
PRINT '  - Orders';
PRINT '  - OrderDetails';
PRINT '';
PRINT 'Prossimo passo: eseguire PopulateTables.sql per inserire dati di esempio';
GO
