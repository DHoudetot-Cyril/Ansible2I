#!/bin/bash

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║   Déploiement IG2I - Bastion + Web Server + DB Server     ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"

# Vérification de la présence de la clé SSH
if [ ! -f ~/.ssh/vockey.pem ]; then
    echo -e "${RED}✗ Erreur: Clé SSH ~/.ssh/vockey.pem non trouvée${NC}"
    echo "  Veuillez placer votre clé SSH AWS Academy (vockey.pem) dans ~/.ssh/vockey.pem"
    exit 1
fi

echo -e "${GREEN}✓ Clé SSH trouvée${NC}"
chmod 600 ~/.ssh/vockey.pem

# Vérification de la présence des adresses dans l'inventaire
if ! grep -q "ansible_host" inventory; then
    echo -e "${RED}✗ Erreur: Les IPs ne sont pas configurées dans l'inventaire${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Inventaire configuré${NC}"

# Installation des dépendances Ansible si nécessaire
if ! command -v ansible &> /dev/null; then
    echo -e "${YELLOW}⚙ Installation d'Ansible...${NC}"
    sudo apt update
    sudo apt install -y ansible
fi

# Test de connexion au webserver
echo -e "${YELLOW}⚙ Test de connexion au webserver...${NC}"
ansible webservers -i inventory -m ping
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Erreur: Impossible de se connecter au webserver${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Webserver accessible${NC}"

# Test de connexion au database server
echo -e "${YELLOW}⚙ Test de connexion au database server...${NC}"
ansible databases -i inventory -m ping
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Erreur: Impossible de se connecter au database server${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Database server accessible${NC}"

# Test de connexion au bastion
echo -e "${YELLOW}⚙ Test de connexion au bastion...${NC}"
ansible bastion -i inventory -m ping
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Erreur: Impossible de se connecter au bastion${NC}"
else
    echo -e "${GREEN}✓ Bastion accessible${NC}"
fi

# Créer le répertoire group_vars
mkdir -p group_vars/all

# Lancement du playbook
echo -e "${YELLOW}⚙ Déploiement de l'infrastructure...${NC}"
ansible-playbook -i inventory deploy-site.yml

# Vérification finale
if [ $? -eq 0 ]; then
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          ✓ Déploiement terminé avec succès!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│              ACCÈS VIA LE BASTION (34.229.62.149)         │${NC}"
echo -e "${YELLOW}└────────────────────────────────────────────────────────────┘${NC}"
echo -e "  Web Server (/)              : http://34.229.62.149/"
echo -e "  Web Server (info.php)       : http://34.229.62.149/info.php"
echo -e "  Web Server (dump.table.php) : http://34.229.62.149/dump.table.php"
echo -e "  phpMyAdmin                  : http://34.229.62.149/phpmyadmin/"
echo -e "  phpMyAdmin (short URL)      : http://34.229.62.149/pma/"
echo ""
echo -e "${YELLOW}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│       SSH DIRECT VERS LES SERVEURS (VPC INTERNE)          │${NC}"
echo -e "${YELLOW}└────────────────────────────────────────────────────────────┘${NC}"
echo -e "  Web Server  : ssh -i ~/.ssh/vockey.pem admin@172.31.70.218"
echo -e "  DB Server   : ssh -i ~/.ssh/vockey.pem admin@172.31.76.10"
echo -e "  Bastion     : ssh -i ~/.ssh/vockey.pem admin@172.31.66.199"
else
    echo -e "${RED}✗ Erreur lors du déploiement${NC}"
    exit 1
fi
