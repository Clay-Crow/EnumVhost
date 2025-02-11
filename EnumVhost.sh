#!/bin/bash

# Activer l'auto-complétion des fichiers
shopt -s progcomp

# Demander à l'utilisateur d'entrer le domaine
read -p "Entrez le domaine cible : " DOMAIN

# Vérifier si l'utilisateur a entré un domaine
if [[ -z "$DOMAIN" ]]; then
    echo "[ERREUR] Vous devez entrer un domaine valide !"
    exit 1
fi

# Demander à l'utilisateur d'entrer le chemin de la wordlist avec auto-complétion
echo -n "Entrez le chemin de la wordlist : "
read -e WORDLIST  # `-e` permet d'utiliser la tabulation pour compléter le chemin

# Vérifier si la wordlist existe
if [[ ! -f "$WORDLIST" ]]; then
    echo "[ERREUR] La wordlist spécifiée n'existe pas !"
    exit 1
fi

# Fichier de sortie
OUTPUT_FILE="vhosts.txt"

# Assurer que le fichier de sortie existe
touch "$OUTPUT_FILE"

# Fonction pour nettoyer proprement à l'arrêt (Ctrl+C)
cleanup() {
    echo -e "\n[INFO] Arrêt détecté. Résultats sauvegardés dans $OUTPUT_FILE"
    exit 0
}

# Capturer SIGINT (Ctrl+C) proprement
trap cleanup SIGINT

# Lancer ffuf avec les paramètres utilisateur
ffuf -u "http://$DOMAIN" -w "$WORDLIST" \
     -H "Host: FUZZ.$DOMAIN" -mc 200 -c | while read -r line; do
    
    # Extraire le sous-domaine détecté
    if echo "$line" | grep -q "\[Status: 200,"; then
        subdomain=$(echo "$line" | awk '{print $1}')
        full_url="http://$subdomain.$DOMAIN"
        
        # Vérifier et éviter les doublons
        if ! grep -Fxq "$full_url" "$OUTPUT_FILE"; then
            echo "$full_url" | tee -a "$OUTPUT_FILE"
        fi
    fi
done
