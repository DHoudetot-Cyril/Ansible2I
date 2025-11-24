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
WEBSERVER_IP=$(grep "webserver ansible_host" inventory | awk '{print $3}' | cut -d= -f2)
DBSERVER_IP=$(grep "dbserver ansible_host" inventory | awk '{print $3}' | cut -d= -f2)

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
ansible webserver -i inventory -m ping > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Web Server accessible${NC}"
else
    echo -e "  ${RED}✗ Web Server non accessible${NC}"
fi

echo "  Database Server..."
ansible database -i inventory -m ping > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Database Server accessible${NC}"
else
    echo -e "  ${RED}✗ Database Server non accessible${NC}"
fi

# Test 3 : Vérifier l'état des services sur le web server
echo ""
echo -e "${YELLOW}Test 3: Services Web Server${NC}"
echo "  Apache2..."
ansible webserver -i inventory -m shell -a "sudo systemctl is-active apache2" 2>/dev/null | grep -q "active"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Apache2 est actif${NC}"
else
    echo -e "  ${RED}✗ Apache2 n'est pas actif${NC}"
fi

echo "  PHP..."
ansible webserver -i inventory -m shell -a "php --version" 2>/dev/null | grep -q "PHP"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ PHP est installé${NC}"
else
    echo -e "  ${RED}✗ PHP n'est pas installé${NC}"
fi

# Test 4 : Vérifier l'état des services sur le database server
echo ""
echo -e "${YELLOW}Test 4: Services Database Server${NC}"
echo "  MariaDB..."
ansible database -i inventory -m shell -a "sudo systemctl is-active mariadb" 2>/dev/null | grep -q "active"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ MariaDB est actif${NC}"
else
    echo -e "  ${RED}✗ MariaDB n'est pas actif${NC}"
fi

echo "  Docker..."
ansible database -i inventory -m shell -a "sudo systemctl is-active docker" 2>/dev/null | grep -q "active"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Docker est actif${NC}"
else
    echo -e "  ${RED}✗ Docker n'est pas actif${NC}"
fi

echo "  phpMyAdmin..."
ansible database -i inventory -m shell -a "sudo docker ps | grep myadmin" 2>/dev/null | grep -q "myadmin"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ phpMyAdmin container est actif${NC}"
else
    echo -e "  ${RED}✗ phpMyAdmin container n'est pas actif${NC}"
fi

# Test 5 : Vérifier les fichiers PHP
echo ""
echo -e "${YELLOW}Test 5: Fichiers Web Server${NC}"
for file in index.html info.php dump.table.php; do
    ansible webserver -i inventory -m shell -a "test -f /var/www/html/$file && echo OK" 2>/dev/null | grep -q "OK"
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ $file existe${NC}"
    else
        echo -e "  ${RED}✗ $file manquant${NC}"
    fi
done

# Test 6 : Vérifier la base de données
echo ""
echo -e "${YELLOW}Test 6: Base de données Test1${NC}"
ansible database -i inventory -m shell -a "mysql -u admin -pIG2IUser -e 'USE Test1; SHOW TABLES;'" 2>/dev/null | grep -q "Users"
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Base de données Test1 existe avec table Users${NC}"
else
    echo -e "  ${RED}✗ Base de données Test1 ou table Users non trouvée${NC}"
fi

# Test 7 : Vérifier les données
echo ""
echo -e "${YELLOW}Test 7: Données dans Test1.Users${NC}"
USER_COUNT=$(ansible database -i inventory -m shell -a "mysql -u admin -pIG2IUser -e 'SELECT COUNT(*) FROM Test1.Users;'" 2>/dev/null | grep -E "^[0-9]+" | head -1 | tr -d ' ')
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
echo "  3. Accédez à phpMyAdmin : http://<DBSERVER_PUBLIC_IP>/"
echo "     Identifiants: admin / IG2IUser"