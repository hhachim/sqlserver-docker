#!/bin/bash

# Script de restauration pour SQL Server
# Utilisation: ./restore.sh fichier_sauvegarde.bak [nom_base_de_données]

# Charger les variables d'environnement
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Configuration
CONTAINER_NAME="sqlserver_db"
BACKUP_DIR=${MSSQL_BACKUP_DIR:-./backup}
LOG_FILE="restore_$(date +%Y%m%d_%H%M%S).log"

# Rediriger les logs vers un fichier et la console
exec > >(tee -a "$LOG_FILE") 2>&1

echo "====== SCRIPT DE RESTAURATION SQL SERVER ======"
echo "Date: $(date)"

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    echo "Erreur: Docker n'est pas installé sur ce système"
    exit 1
fi

# Vérifier si le conteneur SQL Server est en cours d'exécution
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "Erreur: Le conteneur SQL Server '$CONTAINER_NAME' n'est pas en cours d'exécution"
    exit 1
fi

# Vérifier si un fichier de sauvegarde a été fourni
if [ -z "$1" ]; then
    echo "Erreur: Aucun fichier de sauvegarde spécifié"
    echo "Utilisation: $0 fichier_sauvegarde.bak [nom_base_de_données]"
    exit 1
fi

BACKUP_FILE="$1"

# Vérifier si le fichier existe
if [[ -f "$BACKUP_FILE" ]]; then
    echo "Fichier trouvé: $BACKUP_FILE"
elif [[ -f "${BACKUP_DIR}/${BACKUP_FILE}" ]]; then
    BACKUP_FILE="${BACKUP_DIR}/${BACKUP_FILE}"
    echo "Fichier trouvé dans le répertoire des sauvegardes: $BACKUP_FILE"
else
    echo "Erreur: Le fichier $BACKUP_FILE n'existe pas"
    exit 1
fi

# Extraire le nom de la base de données du fichier de sauvegarde
echo "Extraction des informations sur la sauvegarde..."
BACKUP_INFO=$(docker exec $CONTAINER_NAME /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -Q "RESTORE HEADERONLY FROM DISK = N'/backups/$(basename $BACKUP_FILE)'")
ORIGINAL_DB_NAME=$(echo "$BACKUP_INFO" | grep -i "DatabaseName" | awk '{print $2}')

# Si une base de données spécifique est fournie, utiliser celle-ci
if [ "$2" ]; then
    TARGET_DB_NAME=$2
    echo "Base de données cible spécifiée: $TARGET_DB_NAME"
else
    TARGET_DB_NAME=$ORIGINAL_DB_NAME
    echo "Restauration vers la base de données d'origine: $TARGET_DB_NAME"
fi

# Vérifier si la base de données existe déjà
DB_EXISTS=$(docker exec $CONTAINER_NAME /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -h -1 -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = '$TARGET_DB_NAME'")

if [ "$DB_EXISTS" -eq "1" ]; then
    echo "La base de données $TARGET_DB_NAME existe déjà"
    read -p "Voulez-vous remplacer la base de données existante? (o/n): " REPLACE_DB
    
    if [[ "$REPLACE_DB" == "o" || "$REPLACE_DB" == "O" ]]; then
        echo "Suppression de la base de données existante..."
        docker exec $CONTAINER_NAME /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -Q "ALTER DATABASE [$TARGET_DB_NAME] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$TARGET_DB_NAME];"
    else
        echo "Restauration annulée"
        exit 0
    fi
fi

# Extraire les fichiers logiques de la sauvegarde
echo "Extraction des informations sur les fichiers de la sauvegarde..."
FILE_LIST=$(docker exec $CONTAINER_NAME /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -Q "RESTORE FILELISTONLY FROM DISK = N'/backups/$(basename $BACKUP_FILE)'")

# Extraire les noms des fichiers de données et de journal
DATA_FILE=$(echo "$FILE_LIST" | grep -i "D " | awk '{print $1}')
LOG_FILE=$(echo "$FILE_LIST" | grep -i "L " | awk '{print $1}')

# Chemins des fichiers dans le conteneur
DATA_PATH="/var/opt/mssql/data/${TARGET_DB_NAME}.mdf"
LOG_PATH="/var/opt/mssql/data/${TARGET_DB_NAME}_log.ldf"

echo "Restauration de la base de données $TARGET_DB_NAME à partir de $BACKUP_FILE..."
echo "  - Fichier de données: $DATA_FILE -> $DATA_PATH"
echo "  - Fichier de journal: $LOG_FILE -> $LOG_PATH"

# Exécuter la restauration
docker exec $CONTAINER_NAME /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -Q "RESTORE DATABASE [$TARGET_DB_NAME] FROM DISK = N'/backups/$(basename $BACKUP_FILE)' WITH MOVE N'$DATA_FILE' TO N'$DATA_PATH', MOVE N'$LOG_FILE' TO N'$LOG_PATH', REPLACE, RECOVERY, STATS = 10;"
RESTORE_STATUS=$?

# Vérifier le résultat
if [ $RESTORE_STATUS -eq 0 ]; then
    echo "✅ Restauration terminée avec succès dans $TARGET_DB_NAME!"
    
    # Afficher les informations sur la base restaurée
    echo "Tables dans $TARGET_DB_NAME:"
    docker exec $CONTAINER_NAME /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -Q "SELECT TABLE_NAME FROM ${TARGET_DB_NAME}.INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME;"
    
    # Compter les tables
    TABLE_COUNT=$(docker exec $CONTAINER_NAME /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -h -1 -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM ${TARGET_DB_NAME}.INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';")
    echo "Nombre de tables: $TABLE_COUNT"
else
    echo "❌ Erreur lors de la restauration de $TARGET_DB_NAME (code: $RESTORE_STATUS)"
fi

echo "Log de restauration disponible dans $LOG_FILE"
exit $RESTORE_STATUS