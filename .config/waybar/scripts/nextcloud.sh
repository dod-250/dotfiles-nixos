#!/usr/bin/env bash

# Fonction pour obtenir le statut de Nextcloud Desktop
get_nextcloud_desktop_status() {
    # Vérifier si Nextcloud Desktop est en cours d'exécution
    # Méthode plus flexible pour NixOS
    if ! pgrep -f "nextcloud" > /dev/null 2>&1; then
        echo "{\"text\": \"[   ]\", \"tooltip\": \"Nextcloud Desktop: Non démarré\", \"class\": \"disconnected\"}"
        return
    fi
    
    # Vérifier s'il y a des fichiers modifiés récemment (synchronisation en cours)
    sync_dir="$HOME/Nextcloud"
    if [ -d "$sync_dir" ]; then
        # Fichiers modifiés dans les 30 dernières secondes = synchronisation en cours
        recent_files=$(find "$sync_dir" -type f -newermt "30 seconds ago" 2>/dev/null | wc -l)
        
        if [ "$recent_files" -gt 0 ]; then
            echo "{\"text\": \"[  󰓦 ]\", \"tooltip\": \"Nextcloud Desktop: Synchronisation ($recent_files fichiers)\", \"class\": \"syncing\"}"
            return
        fi
        
        # Fichiers modifiés dans les 24 dernières heures = connecté
        recent_files_24h=$(find "$sync_dir" -type f -mtime -1 2>/dev/null | wc -l)
        if [ "$recent_files_24h" -gt 0 ]; then
            echo "{\"text\": \"[   ]\", \"tooltip\": \"Nextcloud Desktop: $recent_files_24h fichiers récents\", \"class\": \"connected\"}"
            return
        else
            echo "{\"text\": \"[   ]\", \"tooltip\": \"Nextcloud Desktop: Connecté\", \"class\": \"connected\"}"
            return
        fi
    fi
    
    # Processus trouvé mais pas de dossier de sync
    echo "{\"text\": \"[  ? ]\", \"tooltip\": \"Nextcloud Desktop: Statut inconnu\", \"class\": \"unknown\"}"
}

# Gestion des arguments
case "$1" in
    --continuous)
        while true; do
            get_nextcloud_desktop_status
            sleep 10
        done
        ;;
    *)
        get_nextcloud_desktop_status
        ;;
esac