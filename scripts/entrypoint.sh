#!/bin/bash
set -e

# Fonction pour attendre que SQL Server soit prêt
wait_for_sqlserver() {
    echo "Attente du démarrage de SQL Server..."
    for i in {1..60}; do
        if /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -Q "SELECT 1" &> /dev/null; then
            echo "SQL Server est prêt"
            return 0
        fi
        echo "Attente... ($i/60)"
        sleep 1
    done
    echo "Échec: SQL Server n'est pas démarré après 60 secondes"
    return 1
}

# Fonction pour exécuter les scripts d'initialisation
run_init_scripts() {
    local init_dir="/docker-entrypoint-initdb.d"
    
    if [ -d "$init_dir" ] && [ "$(ls -A $init_dir/*.sql 2>/dev/null)" ]; then
        echo "Exécution des scripts d'initialisation..."
        
        # Trier les fichiers par nom
        for script in $(ls -v $init_dir/*.sql); do
            echo "Exécution de $script"
            /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -i "$script"
            echo "Script $script exécuté avec succès"
        done
        
        echo "Tous les scripts d'initialisation ont été exécutés"
    else
        echo "Aucun script d'initialisation trouvé dans $init_dir"
    fi
}

# Fonction pour configurer une tâche de sauvegarde automatique
setup_backup_job() {
    if [ -f /usr/local/bin/sqlserver-scripts/backup.sh ]; then
        echo "Configuration de la tâche de sauvegarde automatique..."
        
        # Ajouter une tâche cron pour exécuter la sauvegarde tous les jours à 2h du matin
        echo "0 2 * * * /usr/local/bin/sqlserver-scripts/backup.sh >> /var/log/backup.log 2>&1" > /etc/cron.d/sqlserver-backup
        chmod 0644 /etc/cron.d/sqlserver-backup
        
        # Démarrer le service cron
        service cron start
        
        echo "Tâche de sauvegarde automatique configurée"
    else
        echo "Script de sauvegarde non trouvé"
    fi
}

# Démarrer SQL Server
echo "Démarrage de SQL Server..."
/opt/mssql/bin/sqlservr &
SQLSERVER_PID=$!

# Attendre que SQL Server soit prêt
wait_for_sqlserver

# Une fois SQL Server prêt, exécuter les scripts d'initialisation
run_init_scripts

# Configurer la tâche de sauvegarde automatique
setup_backup_job

# Attendre que SQL Server se termine
wait $SQLSERVER_PID