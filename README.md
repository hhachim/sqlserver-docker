# Projet SQL Server Docker Professionnel

Un environnement Docker complet pour SQL Server, facile à déployer en local ou sur une VM Linux, avec création automatique de bases de données et chargement initial de données.

## Fonctionnalités

- ✅ Configuration SQL Server optimisée et sécurisée
- ✅ Création automatique de bases de données et tables
- ✅ Chargement automatique de données de test
- ✅ Interface d'administration via Adminer
- ✅ Scripts de sauvegarde et restauration
- ✅ Script de déploiement automatisé pour VMs Linux
- ✅ Volumes persistants pour les données
- ✅ Environnement de développement local prêt à l'emploi

## Prérequis

- Docker
- Docker Compose
- Au moins 4 Go de RAM disponible
- Au moins 10 Go d'espace disque libre

## Structure du projet

```
docker-sqlserver-project/
├── docker-compose.yml      # Configuration des services
├── Dockerfile              # Personnalisation de l'image SQL Server
├── .env                    # Variables d'environnement
├── init-scripts/           # Scripts d'initialisation
│   ├── 01-create-databases.sql
│   ├── 02-create-tables.sql
│   └── 03-insert-data.sql
├── scripts/
│   ├── entrypoint.sh       # Script d'entrée du conteneur
│   ├── backup.sh           # Script de sauvegarde
│   ├── restore.sh          # Script de restauration
│   └── deploy.sh           # Script de déploiement sur VM
├── data/                   # Stockage persistant des données
│   └── .gitkeep
└── backup/                 # Dossier des sauvegardes
    └── .gitkeep
```

## Installation locale

1. Clonez ce dépôt:
   ```bash
   git clone https://github.com/votre-username/docker-sqlserver-project.git
   cd docker-sqlserver-project
   ```

2. Personnalisez le fichier `.env` avec vos paramètres:
   ```bash
   cp .env.example .env
   nano .env
   ```

3. Démarrez les services:
   ```bash
   docker-compose up -d
   ```

4. Vérifiez que tout fonctionne:
   ```bash
   docker-compose ps
   ```

## Déploiement sur VM Linux

1. Copiez le projet sur votre VM:
   ```bash
   scp -r docker-sqlserver-project user@server-ip:~/
   ```

2. Connectez-vous à votre VM:
   ```bash
   ssh user@server-ip
   ```

3. Exécutez le script de déploiement:
   ```bash
   cd docker-sqlserver-project
   chmod +x scripts/deploy.sh
   sudo ./scripts/deploy.sh
   ```

## Administration

### Interface Web (Adminer)

Accédez à Adminer via http://localhost:8080 (ou http://ip-de-votre-vm:8080) et connectez-vous avec:

- Système: MS SQL
- Serveur: sqlserver (ou l'adresse IP du conteneur)
- Port: le port défini dans .env (1433 par défaut)
- Utilisateur: sa
- Mot de passe: (celui défini dans .env pour MSSQL_SA_PASSWORD)
- Base de données: (laissez vide pour voir toutes les bases)

### Ligne de commande

```bash
# Connexion au conteneur SQL Server
docker exec -it sqlserver_db bash

# Connexion à SQL Server depuis le conteneur
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD

# Exécution d'une requête SQL
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -Q "SELECT name FROM sys.databases"
```

## Sauvegarde et restauration

Les scripts utilisent SQL Server dans le conteneur Docker, aucune installation locale de SQL Server n'est nécessaire.

### Créer une sauvegarde

```bash
# S'assurer que les scripts sont exécutables
chmod +x scripts/backup.sh scripts/restore.sh

# Sauvegarde complète de toutes les bases de données
./scripts/backup.sh

# Sauvegarde d'une base spécifique
./scripts/backup.sh application_db
```

### Restaurer une sauvegarde

```bash
# Restauration d'une base
./scripts/restore.sh backup/application_db_20250301_120000.bak application_db
```

Les scripts vérifient automatiquement que le conteneur SQL Server est en cours d'exécution et utilisent la commande `docker exec` pour interagir avec SQL Server à l'intérieur du conteneur.

## Schéma de base de données

Le projet crée deux bases de données:

1. **application_db** - Base principale de l'application
   - Tables: users, user_profiles, categories, products, orders, order_items

2. **analytics_db** - Base pour l'analyse et les statistiques
   - Tables: activity_logs, daily_stats

## Différences avec MySQL

Voici les principales différences avec la version MySQL:

1. **Syntaxe SQL:** SQL Server utilise T-SQL qui a une syntaxe légèrement différente de MySQL
2. **Authentification:** SQL Server utilise l'authentification Windows et SQL, nous utilisons ici l'authentification SQL avec l'utilisateur 'sa'
3. **Format de sauvegarde:** SQL Server utilise le format .bak au lieu des dumps SQL
4. **Gestion des utilisateurs:** La gestion des logins et des utilisateurs de base de données est différente
5. **Configuration:** Les options de configuration sont spécifiques à SQL Server

## Personnalisation

### Modifier la version de SQL Server

SQL Server est disponible en plusieurs éditions. Par défaut, nous utilisons l'édition Express qui est gratuite. Vous pouvez changer l'édition en modifiant la variable `MSSQL_PID` dans le fichier `.env`:

- Express: version gratuite avec des limitations (10GB par base, 1.4GB RAM)
- Developer: version complète pour le développement (gratuite, non utilisable en production)
- Standard: version payante