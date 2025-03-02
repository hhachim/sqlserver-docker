-- Utilisation de la base de données principale
USE [application_db];
GO

-- Insertion des données utilisateurs (avec des mots de passe hashés)
IF NOT EXISTS (SELECT * FROM [users] WHERE [username] = 'admin')
BEGIN
    INSERT INTO [users] ([username], [email], [password_hash], [first_name], [last_name], [active])
    VALUES
        ('admin', 'admin@example.com', 'AQAAAAEAACcQAAAAEGCMBdSk5nIgz8LJpJGtkMgDPEqxV2rPUZ7btLOJsF9gePE+IXcQQ5+GWgdZLiLo0g==', 'Admin', 'User', 1),
        ('jdupont', 'jean.dupont@example.com', 'AQAAAAEAACcQAAAAEGCMBdSk5nIgz8LJpJGtkMgDPEqxV2rPUZ7btLOJsF9gePE+IXcQQ5+GWgdZLiLo0g==', 'Jean', 'Dupont', 1),
        ('amoreau', 'alice.moreau@example.com', 'AQAAAAEAACcQAAAAEGCMBdSk5nIgz8LJpJGtkMgDPEqxV2rPUZ7btLOJsF9gePE+IXcQQ5+GWgdZLiLo0g==', 'Alice', 'Moreau', 1),
        ('pmartin', 'pierre.martin@example.com', 'AQAAAAEAACcQAAAAEGCMBdSk5nIgz8LJpJGtkMgDPEqxV2rPUZ7btLOJsF9gePE+IXcQQ5+GWgdZLiLo0g==', 'Pierre', 'Martin', 1),
        ('sbernard', 'sophie.bernard@example.com', 'AQAAAAEAACcQAAAAEGCMBdSk5nIgz8LJpJGtkMgDPEqxV2rPUZ7btLOJsF9gePE+IXcQQ5+GWgdZLiLo0g==', 'Sophie', 'Bernard', 1);
        
    PRINT 'Données des utilisateurs insérées avec succès';
END
ELSE
BEGIN
    PRINT 'Les données des utilisateurs existent déjà';
END

-- Insertion des profils utilisateurs
IF NOT EXISTS (SELECT * FROM [user_profiles] WHERE [user_id] = 1)
BEGIN
    INSERT INTO [user_profiles] ([user_id], [bio], [location], [website])
    VALUES
        (1, 'Administrateur système', 'Paris, France', 'https://admin-portfolio.example.com'),
        (2, 'Développeur web passionné', 'Lyon, France', 'https://jean-dupont.example.com'),
        (3, 'Designer UX/UI', 'Bordeaux, France', 'https://alice-design.example.com'),
        (4, 'Ingénieur DevOps', 'Nantes, France', 'https://pierre-tech.example.com'),
        (5, 'Data scientist', 'Lille, France', 'https://sophie-data.example.com');
        
    PRINT 'Profils utilisateurs insérés avec succès';
END
ELSE
BEGIN
    PRINT 'Les profils utilisateurs existent déjà';
END

-- Insertion des catégories de produits
IF NOT EXISTS (SELECT * FROM [categories] WHERE [name] = 'Électronique')
BEGIN
    -- Insérer d'abord la catégorie parente Électronique
    INSERT INTO [categories] ([name], [description], [parent_id])
    VALUES ('Électronique', 'Produits électroniques et gadgets', NULL);
    
    DECLARE @electroniqueId INT = SCOPE_IDENTITY();
    
    -- Insérer les sous-catégories d'Électronique
    INSERT INTO [categories] ([name], [description], [parent_id])
    VALUES 
        ('Ordinateurs', 'Ordinateurs portables et de bureau', @electroniqueId),
        ('Smartphones', 'Téléphones mobiles et accessoires', @electroniqueId);
    
    -- Insérer la catégorie Vêtements
    INSERT INTO [categories] ([name], [description], [parent_id])
    VALUES ('Vêtements', 'Vêtements pour hommes et femmes', NULL);
    
    DECLARE @vetementsId INT = SCOPE_IDENTITY();
    
    -- Insérer les sous-catégories de Vêtements
    INSERT INTO [categories] ([name], [description], [parent_id])
    VALUES 
        ('Hommes', 'Vêtements pour hommes', @vetementsId),
        ('Femmes', 'Vêtements pour femmes', @vetementsId);
        
    PRINT 'Catégories de produits insérées avec succès';
END
ELSE
BEGIN
    PRINT 'Les catégories de produits existent déjà';
END

-- Insertion des produits
IF NOT EXISTS (SELECT * FROM [products] WHERE [sku] = 'LP001')
BEGIN
    -- Récupérer les IDs des catégories
    DECLARE @ordinateursId INT = (SELECT [id] FROM [categories] WHERE [name] = 'Ordinateurs');
    DECLARE @smartphonesId INT = (SELECT [id] FROM [categories] WHERE [name] = 'Smartphones');
    DECLARE @hommesId INT = (SELECT [id] FROM [categories] WHERE [name] = 'Hommes');
    DECLARE @femmesId INT = (SELECT [id] FROM [categories] WHERE [name] = 'Femmes');
    
    INSERT INTO [products] ([category_id], [name], [description], [price], [stock_quantity], [sku], [active])
    VALUES
        (@ordinateursId, 'Ordinateur portable XPS', 'Ordinateur portable haute performance', 1299.99, 50, 'LP001', 1),
        (@ordinateursId, 'MacBook Pro', 'MacBook Pro avec puce M1', 1499.99, 30, 'LP002', 1),
        (@smartphonesId, 'iPhone 14', 'Smartphone haut de gamme', 999.99, 100, 'SP001', 1),
        (@smartphonesId, 'Samsung Galaxy S22', 'Smartphone Android premium', 899.99, 75, 'SP002', 1),
        (@hommesId, 'T-shirt Coton Bio', 'T-shirt en coton bio pour homme', 29.99, 200, 'TS001', 1),
        (@hommesId, 'Jean Slim Fit', 'Jean slim pour homme', 59.99, 120, 'JN001', 1),
        (@femmesId, 'Robe d''été', 'Robe légère pour l''été', 49.99, 80, 'DR001', 1),
        (@femmesId, 'Blouse en Soie', 'Blouse élégante en soie', 79.99, 60, 'BL001', 1);
        
    PRINT 'Produits insérés avec succès';
END
ELSE
BEGIN
    PRINT 'Les produits existent déjà';
END

-- Insertion des commandes
IF NOT EXISTS (SELECT * FROM [orders] WHERE [user_id] = 2 AND [total_amount] = 1299.99)
BEGIN
    INSERT INTO [orders] ([user_id], [status], [total_amount], [shipping_address], [billing_address], [payment_method])
    VALUES
        (2, 'delivered', 1299.99, '123 Rue de Paris, 75001 Paris, France', '123 Rue de Paris, 75001 Paris, France', 'credit_card'),
        (3, 'shipped', 1079.98, '456 Avenue de Lyon, 69002 Lyon, France', '456 Avenue de Lyon, 69002 Lyon, France', 'paypal'),
        (4, 'processing', 129.97, '789 Boulevard de Bordeaux, 33000 Bordeaux, France', '789 Boulevard de Bordeaux, 33000 Bordeaux, France', 'credit_card'),
        (5, 'pending', 899.99, '101 Rue de Lille, 59000 Lille, France', '101 Rue de Lille, 59000 Lille, France', 'bank_transfer');
        
    PRINT 'Commandes insérées avec succès';
END
ELSE
BEGIN
    PRINT 'Les commandes existent déjà';
END

-- Insertion des détails de commandes
IF NOT EXISTS (SELECT * FROM [order_items] WHERE [order_id] = 1 AND [product_id] = 1)
BEGIN
    INSERT INTO [order_items] ([order_id], [product_id], [quantity], [unit_price], [total_price])
    VALUES
        (1, 1, 1, 1299.99, 1299.99),
        (2, 3, 1, 999.99, 999.99),
        (2, 5, 2, 29.99, 59.98),
        (3, 5, 3, 29.99, 89.97),
        (3, 6, 1, 59.99, 59.99),
        (4, 4, 1, 899.99, 899.99);
        
    PRINT 'Détails des commandes insérés avec succès';
END
ELSE
BEGIN
    PRINT 'Les détails des commandes existent déjà';
END

-- Utilisation de la base de données d'analytique
USE [analytics_db];
GO

-- Insertion des statistiques quotidiennes
IF NOT EXISTS (SELECT * FROM [daily_stats] WHERE [date] = DATEADD(DAY, -7, CAST(GETDATE() AS DATE)))
BEGIN
    INSERT INTO [daily_stats] ([date], [active_users], [new_users], [total_orders], [total_revenue], [avg_order_value])
    VALUES
        (DATEADD(DAY, -7, CAST(GETDATE() AS DATE)), 120, 15, 35, 12500.50, 357.16),
        (DATEADD(DAY, -6, CAST(GETDATE() AS DATE)), 135, 12, 42, 15200.75, 361.92),
        (DATEADD(DAY, -5, CAST(GETDATE() AS DATE)), 142, 18, 38, 13800.25, 363.16),
        (DATEADD(DAY, -4, CAST(GETDATE() AS DATE)), 130, 10, 31, 11200.50, 361.31),
        (DATEADD(DAY, -3, CAST(GETDATE() AS DATE)), 145, 22, 45, 16500.00, 366.67),
        (DATEADD(DAY, -2, CAST(GETDATE() AS DATE)), 150, 17, 50, 18200.25, 364.01),
        (DATEADD(DAY, -1, CAST(GETDATE() AS DATE)), 155, 20, 48, 17500.75, 364.60),
        (CAST(GETDATE() AS DATE), 160, 15, 25, 9800.50, 392.02);
        
    PRINT 'Statistiques quotidiennes insérées avec succès';
END
ELSE
BEGIN
    PRINT 'Les statistiques quotidiennes existent déjà';
END