#!/bin/bash

# Script de test pour vérifier le déploiement IG2I
# Ce script teste les trois services clés

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║   Tests du déploiement IG2I - Web + Database               ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"

# Récupérer les IPs du inventaire
# (première machine de chaque groupe)
ip_of() { awk -v g="[$1]" '$0==g{f=1;next} /^\[/{f=0} f&&/ansible_host=/{for(i=1;i<=NF;i++) if($i~/^ansible_host=/){split($i,a,"=");print a[2];exit}}' inventory; }
WEBSERVER_IP=$(ip_of webservers)
DBSERVER_IP=$(ip_of databases)

# Mot de passe du vault : fichier .vault_pass s'il existe, sinon demandé au clavier
if [ -f .vault_pass ]; then
    VAULT_OPTS=(--vault-password-file .vault_pass)
else
    VAULT_OPTS=(--ask-vault-pass)
fi

echo ""
echo "Configuration détectée :"
echo "  Web Server  : $WEBSERVER_IP"
echo "  DB Server   : $DBSERVER_IP"
echo ""

# Test 1 : Vérifier la présence de la clé SSH
echo -e "${YELLOW}Test 1: Clé SSH${NC}"
if [ -f ~/.ssh/vockey.pem ]; then
    echo -e "${GREEN}✓ Clé SSH trouvée${NC}"
else
    echo -e "${RED}✗ Clé SSH non trouvée${NC}"
    exit 1
fi

# Test 2 : Ping Ansible vers les serveurs
echo ""
echo -e "${YELLOW}Test 2: Connectivité Ansible${NC}"
echo "  Web Server..."
ansible webservers -i inventory -m ping > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Web Server accessible${NC}"
else
    echo -e "  ${RED}✗ Web Server non accessible${NC}"
fi

echo "  Database Server..."
ansible databases -i inventory -m ping > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Database Server accessible${NC}"
else
    echo -e "  ${RED}✗ Database Server non accessible${NC}"
fi

# Test 3 : Vérifier l'état des services sur le web server
echo ""
echo -e "${YELLOW}Test 3: Services Web Server${NC}"
echo "  Apache2..."
ansible webservers -i inventory -m shell -b -a "systemctl is-active apache2" 2>/dev/null | grep -qx "active"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Apache2 est actif${NC}"
else
    echo -e "  ${RED}✗ Apache2 n'est pas actif${NC}"
fi

echo "  PHP..."
ansible webservers -i inventory -m shell -a "php --version" 2>/dev/null | grep -q "PHP"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ PHP est installé${NC}"
else
    echo -e "  ${RED}✗ PHP n'est pas installé${NC}"
fi

# Test 4 : Vérifier l'état des services sur le database server
echo ""
echo -e "${YELLOW}Test 4: Services Database Server${NC}"
echo "  MariaDB..."
ansible databases -i inventory -b -m shell -a "docker ps --filter name=mariadb" 2>/dev/null | grep -q "mariadb"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Conteneur MariaDB actif${NC}"
else
    echo -e "  ${RED}✗ MariaDB n'est pas actif${NC}"
fi

echo "  Docker..."
ansible databases -i inventory -m shell -b -a "systemctl is-active docker" 2>/dev/null | grep -qx "active"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Docker est actif${NC}"
else
    echo -e "  ${RED}✗ Docker n'est pas actif${NC}"
fi

echo "  phpMyAdmin..."
ansible databases -i inventory -m shell -b -a "docker ps | grep myadmin" 2>/dev/null | grep -q "myadmin"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ phpMyAdmin container est actif${NC}"
else
    echo -e "  ${RED}✗ phpMyAdmin container n'est pas actif${NC}"
fi

# Test 5 : Vérifier les fichiers PHP
echo ""
echo -e "${YELLOW}Test 5: Fichiers Web Server${NC}"
for file in index.html info.php dump.table.php; do
    ansible webservers -i inventory -m shell -a "test -f /var/www/html/$file && echo OK" 2>/dev/null | grep -q "OK"
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ $file existe${NC}"
    else
        echo -e "  ${RED}✗ $file manquant${NC}"
    fi
done

# Test 6 : Vérifier la base de données
echo ""
echo -e "${YELLOW}Test 6: Base de données Test1${NC}"
ansible databases -i inventory -b "${VAULT_OPTS[@]}" -m shell -a "docker exec mariadb mariadb -u{{ mariadb_admin_user }} -p{{ mariadb_admin_password }} -e 'USE {{ mariadb_database }}; SHOW TABLES;'" 2>/dev/null | grep -q "Users"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Base de données Test1 existe avec table Users${NC}"
else
    echo -e "  ${RED}✗ Base de données Test1 ou table Users non trouvée${NC}"
fi

# Test 7 : Vérifier les données
echo ""
echo -e "${YELLOW}Test 7: Données dans Test1.Users${NC}"
USER_COUNT=$(ansible databases -i inventory -b "${VAULT_OPTS[@]}" -m shell -a "docker exec mariadb mariadb -N -u{{ mariadb_admin_user }} -p{{ mariadb_admin_password }} -e 'SELECT COUNT(*) FROM {{ mariadb_database }}.Users;'" 2>/dev/null | grep -E "^[0-9]+$" | head -1 | tr -d ' ')
if [ ! -z "$USER_COUNT" ] && [ "$USER_COUNT" -gt 0 ]; then
    echo -e "  ${GREEN}✓ Table Users contient $USER_COUNT enregistrements${NC}"
else
    echo -e "  ${RED}✗ Table Users vide ou non trouvée${NC}"
fi

echo ""
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Tests terminés!                               ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Prochaines étapes :"
echo "  1. Accédez au Web Server : http://<WEBSERVER_PUBLIC_IP>/"
echo "  2. Testez dump.table.php : http://<WEBSERVER_PUBLIC_IP>/dump.table.php"
echo "  3. Accédez à phpMyAdmin : http://<BASTION_PUBLIC_IP>/pma/"
echo "     Deux identifiants : ceux du bastion (vault_pma_basic_auth_*), puis ceux de la base"
echo "     (voir : ansible-vault view group_vars/all/vault.yml)"