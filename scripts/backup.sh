#!/bin/bash

# Script de sauvegarde pour SQL Server
# Utilisation: ./backup.sh [nom_base_de_données]

# Date et heure pour le nom du fichier
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/backups"

# Créer le répertoire de sauvegarde s'il n'existe pas
mkdir -p $BACKUP_DIR

# Vérifier si une base de données spécifique a été fournie
if [ "$1" ]; then
    DB_NAME=$1
    BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.bak"
    
    echo "Sauvegarde de la base de données $DB_NAME..."
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -Q "BACKUP DATABASE [$DB_NAME] TO DISK = N'$BACKUP_FILE' WITH NOFORMAT, NOINIT, NAME = N'$DB_NAME-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10"
    
    if [ $? -eq 0 ]; then
        echo "Sauvegarde réussie: $BACKUP_FILE"
    else
        echo "Erreur lors de la sauvegarde de $DB_NAME"
        exit 1
    fi
else
    # Obtenir la liste des bases de données (excepté les bases système)
    echo "Obtention de la liste des bases de données..."
    DB_LIST=$(/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -h -1 -Q "SET NOCOUNT ON; SELECT name FROM sys.databases WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')" | tr -d ' ')
    
    for DB in $DB_LIST; do
        BACKUP_FILE="${BACKUP_DIR}/${DB}_${TIMESTAMP}.bak"
        
        echo "Sauvegarde de la base de données $DB..."
        /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -Q "BACKUP DATABASE [$DB] TO DISK = N'$BACKUP_FILE' WITH NOFORMAT, NOINIT, NAME = N'$DB-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10"
        
        if [ $? -eq 0 ]; then
            echo "Sauvegarde réussie: $BACKUP_FILE"
        else
            echo "Erreur lors de la sauvegarde de $DB"
        fi
    done
fi

# Nettoyage des sauvegardes anciennes (plus de 30 jours)
echo "Suppression des sauvegardes de plus de 30 jours..."
find $BACKUP_DIR -name "*.bak" -type f -mtime +30 -delete

echo "Informations sur les sauvegardes:"
ls -lh $BACKUP_DIR/*.bak 2>/dev/null || echo "Aucune sauvegarde trouvée."

exit 0