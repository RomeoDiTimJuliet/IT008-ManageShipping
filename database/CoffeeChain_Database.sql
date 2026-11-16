IF DB_ID(N'CoffeeChainDb') IS NULL
BEGIN
    CREATE DATABASE CoffeeChainDb;
END
GO

USE CoffeeChainDb;
GO


CREATE TABLE dbo.Branches
(
    Id INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Branches PRIMARY KEY,
    Name NVARCHAR(120) NOT NULL,
    Address NVARCHAR(255) NOT NULL,
    IsActive BIT NOT NULL
        CONSTRAINT DF_Branches_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Branches_CreatedAt DEFAULT (SYSDATETIME())
);
GO

CREATE TABLE dbo.Users
(
    Id INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Users PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    Role VARCHAR(10) NOT NULL,

    BranchId INT NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_Users_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT CK_Users_Role CHECK (Role IN ('ADMIN', 'STAFF')),
    CONSTRAINT CK_Users_Role_Branch CHECK
    (
        (Role = 'ADMIN' AND BranchId IS NULL)
        OR
        (Role = 'STAFF' AND BranchId IS NOT NULL)
    ),

    CONSTRAINT FK_Users_Branches
        FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id)
);
GO

CREATE INDEX IX_Users_BranchId ON dbo.Users(BranchId);
GO

CREATE TABLE dbo.Products
(
    Id INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Products PRIMARY KEY,

    Name NVARCHAR(120) NOT NULL,

    CurrentPrice DECIMAL(18,2) NOT NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_Products_IsActive DEFAULT (1),

    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Products_CreatedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT CK_Products_CurrentPrice
        CHECK (CurrentPrice >= 0)
);
GO

CREATE TABLE dbo.BranchProductSettings
(
    BranchId INT NOT NULL,
    ProductId INT NOT NULL,
    DefaultDailyQuantity INT NOT NULL,

    CONSTRAINT PK_BranchProductSettings
        PRIMARY KEY (BranchId, ProductId),
    CONSTRAINT CK_BranchProductSettings_DefaultDailyQuantity
        CHECK (DefaultDailyQuantity >= 0),
    CONSTRAINT FK_BranchProductSettings_Branches
        FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id),
    CONSTRAINT FK_BranchProductSettings_Products
        FOREIGN KEY (ProductId) REFERENCES dbo.Products(Id)
);
GO


CREATE TABLE dbo.BranchDailyStocks
(
    BranchId INT NOT NULL,
    ProductId INT NOT NULL,
    BusinessDate DATE NOT NULL,
    OpeningQuantity INT NOT NULL,
    RemainingQuantity INT NOT NULL,

    CONSTRAINT PK_BranchDailyStocks
        PRIMARY KEY (BranchId, ProductId, BusinessDate),
    CONSTRAINT CK_BranchDailyStocks_OpeningQuantity
        CHECK (OpeningQuantity >= 0),
    CONSTRAINT CK_BranchDailyStocks_RemainingQuantity
        CHECK (RemainingQuantity >= 0 AND RemainingQuantity <= OpeningQuantity),
    CONSTRAINT FK_BranchDailyStocks_Branches
        FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id),
    CONSTRAINT FK_BranchDailyStocks_Products
        FOREIGN KEY (ProductId) REFERENCES dbo.Products(Id)
);
GO

CREATE INDEX IX_BranchDailyStocks_Branch_BusinessDate
    ON dbo.BranchDailyStocks(BranchId, BusinessDate);
GO

CREATE TABLE dbo.Orders
(
    Id INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Orders PRIMARY KEY,
    BranchId INT NOT NULL,
    StaffId INT NOT NULL,
    Status VARCHAR(12) NOT NULL
        CONSTRAINT DF_Orders_Status DEFAULT ('PENDING'),
    TotalAmount DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_Orders_TotalAmount DEFAULT (0),
    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Orders_CreatedAt DEFAULT (SYSDATETIME()),
    PaidAt DATETIME2(0) NULL,
    ExpiresAt DATETIME2(0) NULL,

    CONSTRAINT CK_Orders_Status
        CHECK (Status IN ('PENDING', 'PAID', 'CANCELLED')),
    CONSTRAINT CK_Orders_TotalAmount CHECK (TotalAmount >= 0),
    CONSTRAINT FK_Orders_Branches
        FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id),
    CONSTRAINT FK_Orders_Users
        FOREIGN KEY (StaffId) REFERENCES dbo.Users(Id)
);
GO

CREATE INDEX IX_Orders_Branch_Status_PaidAt
    ON dbo.Orders(BranchId, Status, PaidAt);
GO
CREATE INDEX IX_Orders_StaffId ON dbo.Orders(StaffId);
GO

CREATE TABLE dbo.OrderItems
(
    Id INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_OrderItems PRIMARY KEY,
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,

    CONSTRAINT CK_OrderItems_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_OrderItems_UnitPrice CHECK (UnitPrice >= 0),
    CONSTRAINT FK_OrderItems_Orders
        FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id),
    CONSTRAINT FK_OrderItems_Products
        FOREIGN KEY (ProductId) REFERENCES dbo.Products(Id)
);
GO

CREATE INDEX IX_OrderItems_OrderId ON dbo.OrderItems(OrderId);
GO
CREATE INDEX IX_OrderItems_ProductId ON dbo.OrderItems(ProductId);
GO

CREATE TABLE dbo.Expenses
(
    Id INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Expenses PRIMARY KEY,
    BranchId INT NOT NULL,
    StaffId INT NOT NULL,
    Category VARCHAR(20) NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    ExpenseDate DATE NOT NULL,
    Note NVARCHAR(255) NULL,
    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Expenses_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NULL,

    CONSTRAINT CK_Expenses_Category
        CHECK (Category IN ('ELECTRICITY', 'WATER', 'RENT', 'STAFF')),
    CONSTRAINT CK_Expenses_Amount CHECK (Amount > 0),
    CONSTRAINT FK_Expenses_Branches
        FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id),
    CONSTRAINT FK_Expenses_Users
        FOREIGN KEY (StaffId) REFERENCES dbo.Users(Id)
);
GO

CREATE INDEX IX_Expenses_Branch_ExpenseDate
    ON dbo.Expenses(BranchId, ExpenseDate);
GO

CREATE INDEX IX_Expenses_StaffId ON dbo.Expenses(StaffId);
GO

