#!/bin/bash

# Script de sauvegarde pour SQL Server
# Utilisation: ./backup.sh [nom_base_de_données]

# Date et heure pour le nom du fichier
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CONTAINER_NAME="sqlserver_db"
HOST_BACKUP_DIR="./backup"
CONTAINER_BACKUP_DIR="/backups"

# Charger les variables d'environnement si .env existe
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Créer le répertoire de sauvegarde s'il n'existe pas
mkdir -p $HOST_BACKUP_DIR

# Vérifier si le conteneur est en cours d'exécution
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "Erreur: Le conteneur SQL Server n'est pas en cours d'exécution"
    exit 1
fi

# Vérifier si une base de données spécifique a été fournie
if [ "$1" ]; then
    DB_NAME=$1
    BACKUP_FILE="${DB_NAME}_${TIMESTAMP}.bak"
    CONTAINER_BACKUP_PATH="${CONTAINER_BACKUP_DIR}/${BACKUP_FILE}"
    
    echo "Sauvegarde de la base de données $DB_NAME..."
    docker exec $CONTAINER_NAME /opt/mssql-tools/bin/sqlcmd -S localhost \
        -U sa -P "$MSSQL_SA_PASSWORD" \
        -Q "BACKUP DATABASE [$DB_NAME] TO DISK = N'$CONTAINER_BACKUP_PATH' WITH NOFORMAT, NOINIT, NAME = N'$DB_NAME-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10"
    
    if [ $? -eq 0 ]; then
        echo "Sauvegarde réussie: $HOST_BACKUP_DIR/$BACKUP_FILE"
    else
        echo "Erreur lors de la sauvegarde de $DB_NAME"
        exit 1
    fi
else
    # Obtenir la liste des bases de données (excepté les bases système)
    echo "Obtention de la liste des bases de données..."
    DB_LIST=$(docker exec $CONTAINER_NAME /opt/mssql-tools/bin/sqlcmd -S localhost \
        -U sa -P "$MSSQL_SA_PASSWORD" -h -1 \
        -Q "SET NOCOUNT ON; SELECT name FROM sys.databases WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')" | tr -d ' ')
    
    for DB in $DB_LIST; do
        BACKUP_FILE="${DB}_${TIMESTAMP}.bak"
        CONTAINER_BACKUP_PATH="${CONTAINER_BACKUP_DIR}/${BACKUP_FILE}"
        
        echo "Sauvegarde de la base de données $DB..."
        docker exec $CONTAINER_NAME /opt/mssql-tools/bin/sqlcmd -S localhost \
            -U sa -P "$MSSQL_SA_PASSWORD" \
            -Q "BACKUP DATABASE [$DB] TO DISK = N'$CONTAINER_BACKUP_PATH' WITH NOFORMAT, NOINIT, NAME = N'$DB-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10"
        
        if [ $? -eq 0 ]; then
            echo "Sauvegarde réussie: $HOST_BACKUP_DIR/$BACKUP_FILE"
        else
            echo "Erreur lors de la sauvegarde de $DB"
        fi
    done
fi

# Nettoyage des sauvegardes anciennes (plus de 30 jours)
echo "Suppression des sauvegardes de plus de 30 jours..."
docker exec $CONTAINER_NAME find $CONTAINER_BACKUP_DIR -name "*.bak" -type f -mtime +30 -delete

echo "Informations sur les sauvegardes:"
docker exec $CONTAINER_NAME ls -lh $CONTAINER_BACKUP_DIR/*.bak 2>/dev/null || echo "Aucune sauvegarde trouvée."

exit 0