-- Utilisation de la base de données principale
USE [application_db];
GO

-- Table des utilisateurs
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'users')
BEGIN
    CREATE TABLE [users] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [username] NVARCHAR(50) NOT NULL UNIQUE,
        [email] NVARCHAR(100) NOT NULL UNIQUE,
        [password_hash] NVARCHAR(255) NOT NULL,
        [first_name] NVARCHAR(50),
        [last_name] NVARCHAR(50),
        [active] BIT DEFAULT 1,
        [created_at] DATETIME DEFAULT GETDATE(),
        [updated_at] DATETIME DEFAULT GETDATE()
    );
    
    CREATE INDEX [idx_email] ON [users] ([email]);
    CREATE INDEX [idx_username] ON [users] ([username]);
    
    PRINT 'Table users créée avec succès';
END
ELSE
BEGIN
    PRINT 'La table users existe déjà';
END

-- Table des profils utilisateurs
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'user_profiles')
BEGIN
    CREATE TABLE [user_profiles] (
        [user_id] INT PRIMARY KEY,
        [bio] NVARCHAR(MAX),
        [avatar_url] NVARCHAR(255),
        [birth_date] DATE,
        [location] NVARCHAR(100),
        [website] NVARCHAR(255),
        [updated_at] DATETIME DEFAULT GETDATE(),
        CONSTRAINT [FK_UserProfiles_Users] FOREIGN KEY ([user_id]) REFERENCES [users] ([id]) ON DELETE CASCADE
    );
    
    PRINT 'Table user_profiles créée avec succès';
END
ELSE
BEGIN
    PRINT 'La table user_profiles existe déjà';
END

-- Table des catégories de produits
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'categories')
BEGIN
    CREATE TABLE [categories] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [name] NVARCHAR(100) NOT NULL,
        [description] NVARCHAR(MAX),
        [parent_id] INT,
        [created_at] DATETIME DEFAULT GETDATE(),
        [updated_at] DATETIME DEFAULT GETDATE(),
        CONSTRAINT [FK_Categories_ParentCategory] FOREIGN KEY ([parent_id]) REFERENCES [categories] ([id])
    );
    
    PRINT 'Table categories créée avec succès';
END
ELSE
BEGIN
    PRINT 'La table categories existe déjà';
END

-- Table des produits
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'products')
BEGIN
    CREATE TABLE [products] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [category_id] INT,
        [name] NVARCHAR(100) NOT NULL,
        [description] NVARCHAR(MAX),
        [price] DECIMAL(10, 2) NOT NULL,
        [stock_quantity] INT DEFAULT 0,
        [sku] NVARCHAR(50) UNIQUE,
        [active] BIT DEFAULT 1,
        [created_at] DATETIME DEFAULT GETDATE(),
        [updated_at] DATETIME DEFAULT GETDATE(),
        CONSTRAINT [FK_Products_Categories] FOREIGN KEY ([category_id]) REFERENCES [categories] ([id])
    );
    
    CREATE INDEX [idx_category] ON [products] ([category_id]);
    CREATE INDEX [idx_sku] ON [products] ([sku]);
    
    PRINT 'Table products créée avec succès';
END
ELSE
BEGIN
    PRINT 'La table products existe déjà';
END

-- Table des commandes
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'orders')
BEGIN
    CREATE TABLE [orders] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [user_id] INT,
        [status] NVARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
        [total_amount] DECIMAL(10, 2) NOT NULL,
        [shipping_address] NVARCHAR(MAX) NOT NULL,
        [billing_address] NVARCHAR(MAX),
        [payment_method] NVARCHAR(50),
        [tracking_number] NVARCHAR(100),
        [created_at] DATETIME DEFAULT GETDATE(),
        [updated_at] DATETIME DEFAULT GETDATE(),
        CONSTRAINT [FK_Orders_Users] FOREIGN KEY ([user_id]) REFERENCES [users] ([id])
    );
    
    CREATE INDEX [idx_user] ON [orders] ([user_id]);
    CREATE INDEX [idx_status] ON [orders] ([status]);
    
    PRINT 'Table orders créée avec succès';
END
ELSE
BEGIN
    PRINT 'La table orders existe déjà';
END

-- Table des détails de commandes
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'order_items')
BEGIN
    CREATE TABLE [order_items] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [order_id] INT NOT NULL,
        [product_id] INT,
        [quantity] INT NOT NULL,
        [unit_price] DECIMAL(10, 2) NOT NULL,
        [total_price] DECIMAL(10, 2) NOT NULL,
        [created_at] DATETIME DEFAULT GETDATE(),
        CONSTRAINT [FK_OrderItems_Orders] FOREIGN KEY ([order_id]) REFERENCES [orders] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_OrderItems_Products] FOREIGN KEY ([product_id]) REFERENCES [products] ([id])
    );
    
    CREATE INDEX [idx_order] ON [order_items] ([order_id]);
    CREATE INDEX [idx_product] ON [order_items] ([product_id]);
    
    PRINT 'Table order_items créée avec succès';
END
ELSE
BEGIN
    PRINT 'La table order_items existe déjà';
END

-- Utilisation de la base de données d'analytique
USE [analytics_db];
GO

-- Table pour les logs d'activité
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'activity_logs')
BEGIN
    CREATE TABLE [activity_logs] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [user_id] INT,
        [action] NVARCHAR(100) NOT NULL,
        [entity] NVARCHAR(50),
        [entity_id] INT,
        [details] NVARCHAR(MAX),
        [ip_address] NVARCHAR(45),
        [user_agent] NVARCHAR(MAX),
        [created_at] DATETIME DEFAULT GETDATE()
    );
    
    CREATE INDEX [idx_user_action] ON [activity_logs] ([user_id], [action]);
    CREATE INDEX [idx_entity] ON [activity_logs] ([entity], [entity_id]);
    CREATE INDEX [idx_created_at] ON [activity_logs] ([created_at]);
    
    PRINT 'Table activity_logs créée avec succès';
END
ELSE
BEGIN
    PRINT 'La table activity_logs existe déjà';
END

-- Table pour les statistiques d'utilisation quotidiennes
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'daily_stats')
BEGIN
    CREATE TABLE [daily_stats] (
        [date] DATE PRIMARY KEY,
        [active_users] INT DEFAULT 0,
        [new_users] INT DEFAULT 0,
        [total_orders] INT DEFAULT 0,
        [total_revenue] DECIMAL(15, 2) DEFAULT 0,
        [avg_order_value] DECIMAL(10, 2) DEFAULT 0,
        [updated_at] DATETIME DEFAULT GETDATE()
    );
    
    CREATE INDEX [idx_date] ON [daily_stats] ([date]);
    
    PRINT 'Table daily_stats créée avec succès';
END
ELSE
BEGIN
    PRINT 'La table daily_stats existe déjà';
END