-- Création des bases de données
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'application_db')
BEGIN
    CREATE DATABASE application_db;
    PRINT 'Base de données application_db créée avec succès';
END
ELSE
BEGIN
    PRINT 'La base de données application_db existe déjà';
END

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'analytics_db')
BEGIN
    CREATE DATABASE analytics_db;
    PRINT 'Base de données analytics_db créée avec succès';
END
ELSE
BEGIN
    PRINT 'La base de données analytics_db existe déjà';
END

-- Attribution des utilisateurs et privilèges
USE [master];
GO

-- Créer l'utilisateur d'application si nécessaire
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'app_user')
BEGIN
    CREATE LOGIN [app_user] WITH PASSWORD = '$(MSSQL_PASSWORD)';
    PRINT 'Login app_user créé avec succès';
END
ELSE
BEGIN
    PRINT 'Le login app_user existe déjà';
END

-- Créer un utilisateur en lecture seule
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'readonly_user')
BEGIN
    CREATE LOGIN [readonly_user] WITH PASSWORD = '$(READONLY_USER_PASSWORD)';
    PRINT 'Login readonly_user créé avec succès';
END
ELSE
BEGIN
    PRINT 'Le login readonly_user existe déjà';
END

-- Configurer les droits sur application_db
USE [application_db];
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'app_user')
BEGIN
    CREATE USER [app_user] FOR LOGIN [app_user];
    ALTER ROLE db_owner ADD MEMBER [app_user];
    PRINT 'Utilisateur app_user ajouté comme propriétaire de application_db';
END
ELSE
BEGIN
    PRINT 'L''utilisateur app_user existe déjà dans application_db';
END

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'readonly_user')
BEGIN
    CREATE USER [readonly_user] FOR LOGIN [readonly_user];
    ALTER ROLE db_datareader ADD MEMBER [readonly_user];
    PRINT 'Utilisateur readonly_user ajouté comme lecteur de application_db';
END
ELSE
BEGIN
    PRINT 'L''utilisateur readonly_user existe déjà dans application_db';
END

-- Configurer les droits sur analytics_db
USE [analytics_db];
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'app_user')
BEGIN
    CREATE USER [app_user] FOR LOGIN [app_user];
    ALTER ROLE db_datareader ADD MEMBER [app_user];
    ALTER ROLE db_datawriter ADD MEMBER [app_user];
    PRINT 'Utilisateur app_user ajouté comme lecteur/écrivain de analytics_db';
END
ELSE
BEGIN
    PRINT 'L''utilisateur app_user existe déjà dans analytics_db';
END

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'readonly_user')
BEGIN
    CREATE USER [readonly_user] FOR LOGIN [readonly_user];
    ALTER ROLE db_datareader ADD MEMBER [readonly_user];
    PRINT 'Utilisateur readonly_user ajouté comme lecteur de analytics_db';
END
ELSE
BEGIN
    PRINT 'L''utilisateur readonly_user existe déjà dans analytics_db';
END