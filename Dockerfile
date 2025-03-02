FROM mcr.microsoft.com/azure-sql-edge:latest

USER root

# Installation des utilitaires pour la maintenance
RUN apt-get update && apt-get install -y \
    nano \
    iputils-ping \
    procps \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Création d'un répertoire pour les scripts d'initialisation et de sauvegarde
RUN mkdir -p /usr/local/bin/sqlserver-scripts /docker-entrypoint-initdb.d

# Copie du script d'initialisation et de sauvegarde
COPY scripts/entrypoint.sh /usr/local/bin/
COPY scripts/backup.sh /usr/local/bin/sqlserver-scripts/
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/sqlserver-scripts/backup.sh

# Configuration du fuseau horaire
ENV TZ=Europe/Paris

# Exposition du port SQL Server
EXPOSE 1433

# Volumes pour les données et sauvegardes
VOLUME /var/opt/mssql
VOLUME /backups

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]