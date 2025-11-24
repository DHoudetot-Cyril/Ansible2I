#!/bin/bash

# Script pour nettoyer et redéployer le projet
# Utile si vous devez recommencer

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║   Nettoyage et Redéploiement du Projet IG2I               ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"

# Confirmation
echo -e "${RED}Attention: Cette action va réinitialiser complètement les serveurs!${NC}"
read -p "Êtes-vous sûr? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Opération annulée."
    exit 1
fi

# Nettoyer localement
echo -e "${YELLOW}Nettoyage des fichiers locaux...${NC}"
rm -rf group_vars
rm -f .vault_pass
echo -e "${GREEN}✓ Fichiers locaux nettoyés${NC}"

# Réinitialiser les serveurs (optionnel)
echo ""
echo -e "${YELLOW}Réinitialisation des serveurs (optionnel)...${NC}"
read -p "Voulez-vous réinitialiser les serveurs? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚙ Nettoyage du Web Server...${NC}"
    ansible webservers -i inventory -b -m shell -a "systemctl stop apache2; rm -rf /var/www/html/*" 2>/dev/null
    
    echo -e "${YELLOW}⚙ Nettoyage du Database Server (Docker)...${NC}"
    ansible databases -i inventory -b -m shell -a "docker stop mariadb phpmyadmin; docker rm mariadb phpmyadmin; docker volume rm mariadb_data; docker network rm db_network" 2>/dev/null
    
    echo -e "${YELLOW}⚙ Nettoyage du Bastion (Nginx)...${NC}"
    ansible bastion -i inventory -b -m shell -a "systemctl stop nginx; rm -f /etc/nginx/nginx.conf" 2>/dev/null
    
    echo -e "${GREEN}✓ Serveurs réinitialisés${NC}"
fi

# Redéployer
echo ""
echo -e "${YELLOW}⚙ Lancement du déploiement...${NC}"
./deploy.sh

echo -e "${GREEN}✓ Redéploiement terminé!${NC}"