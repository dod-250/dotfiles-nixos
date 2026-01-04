#!/usr/bin/env bash

get_nextcloud_desktop_status() {
    if ! pgrep -f "nextcloud" > /dev/null 2>&1; then
        echo "{\"text\": \"[   ]\", \"tooltip\": \"Nextcloud Desktop: Non démarré\", \"class\": \"disconnected\"}"
        return
    fi
    
    sync_dir="$HOME/Nextcloud"
    if [ -d "$sync_dir" ]; then
        recent_files=$(find "$sync_dir" -type f -newermt "30 seconds ago" 2>/dev/null | wc -l)
        
        if [ "$recent_files" -gt 0 ]; then
            echo "{\"text\": \"[  󰓦 ]\", \"tooltip\": \"Nextcloud Desktop: Synchronisation ($recent_files fichiers)\", \"class\": \"syncing\"}"
            return
        fi
        
        recent_files_24h=$(find "$sync_dir" -type f -mtime -1 2>/dev/null | wc -l)
        if [ "$recent_files_24h" -gt 0 ]; then
            echo "{\"text\": \"[   ]\", \"tooltip\": \"Nextcloud Desktop: $recent_files_24h fichiers récents\", \"class\": \"connected\"}"
            return
        else
            echo "{\"text\": \"[   ]\", \"tooltip\": \"Nextcloud Desktop: Connecté\", \"class\": \"connected\"}"
            return
        fi
    fi
    
    echo "{\"text\": \"[  ? ]\", \"tooltip\": \"Nextcloud Desktop: Statut inconnu\", \"class\": \"unknown\"}"
}

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