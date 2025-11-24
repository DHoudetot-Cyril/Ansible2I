# 🚀 Projet IG2I - Architecture 3-Tiers Automatisée (Ansible)

Ce projet déploie une architecture web 3-tiers complète et automatisée sur AWS utilisant **Ansible**. Il met en œuvre des pratiques DevOps modernes pour orchestrer trois serveurs distincts assurant la sécurité, la distribution de charge et la persistance des données.

## 🏗️ Architecture

L'infrastructure est composée de trois instances Debian 12 interconnectées :

1.  **🛡️ Bastion (Reverse Proxy)**
    *   **Rôle** : Point d'entrée unique pour les utilisateurs.
    *   **Service** : Nginx.
    *   **Fonction** : Redirige le trafic HTTP vers le serveur Web ou l'interface d'administration de la base de données (phpMyAdmin).

2.  **🌐 Web Server (Application)**
    *   **Rôle** : Hébergement de l'application web.
    *   **Services** : Apache2, PHP 8.4.
    *   **Fonction** : Exécute le code PHP et communique avec le serveur de base de données.

3.  **🗄️ Database Server (Données)**
    *   **Rôle** : Stockage des données et administration.
    *   **Services** : MariaDB, Docker (pour phpMyAdmin).
    *   **Fonction** : Stocke les données utilisateurs et fournit une interface de gestion via phpMyAdmin.

---

## 📋 Prérequis

Avant de lancer le déploiement, assurez-vous de disposer des éléments suivants :

*   **3 Instances AWS** (Debian 12, t3.micro recommandées) avec le Security Group `IG2I-SG-1`.
*   **Clé SSH** : `vockey.pem` placée dans `~/.ssh/` avec les permissions strictes (`chmod 600`).
*   **Ansible** installé sur votre machine de contrôle.
*   **Configuration de l'inventaire** : Mettez à jour le fichier `inventory` avec les IPs publiques et privées de vos instances.

---

## 🚀 Déploiement Rapide

Le déploiement est entièrement scripté.

1.  **Cloner et préparer** :
    ```bash
    cd roles_labs/advanced
    chmod +x deploy.sh test.sh clean_and_redeploy.sh
    ```

2.  **Lancer le déploiement** :
    ```bash
    ./deploy.sh
    ```
    *Ce script vérifie les clés SSH, la connectivité Ansible, et lance le playbook principal.*

---

## 🔗 Accès aux Services

Une fois le déploiement terminé, tout est accessible via l'IP publique du **Bastion**.

| Service                | URL                                  | Description                           |
| ---------------------- | ------------------------------------ | ------------------------------------- |
| **Site Web**           | `http://<BASTION_IP>/`               | Page d'accueil du site.               |
| **Liste Utilisateurs** | `http://<BASTION_IP>/dump.table.php` | Test de connexion Web <-> DB.         |
| **Info PHP**           | `http://<BASTION_IP>/info.php`       | Configuration PHP du serveur Web.     |
| **phpMyAdmin**         | `http://<BASTION_IP>/pma/`           | Interface d'administration de la BDD. |

> **Note** : Pour phpMyAdmin, utilisez les identifiants suivants :
> *   **Utilisateur** : `admin`
> *   **Mot de passe** : `IG2IUser`

---

## 🧪 Vérification et Tests

### Tests Automatisés
Un script de test est fourni pour valider l'état de l'infrastructure :
```bash
./test.sh
```

### Tests Manuels
Vous pouvez vérifier manuellement la connexion entre les serveurs :

1.  **Connexion SSH au Web Server** :
    ```bash
    ssh -i ~/.ssh/vockey.pem admin@<WEBSERVER_IP>
    ```
2.  **Test de connexion MySQL distant** :
    ```bash
    mysql -h <DBSERVER_PRIVATE_IP> -u admin -p
    # Mot de passe : IG2IUser
    ```

---

## 📂 Structure du Projet

```text
roles_labs/advanced/
├── inventory                     # Inventaire des serveurs (IPs, utilisateurs)
├── deploy.sh                     # Script de lancement automatique
├── deploy-site.yml               # Playbook Ansible principal
├── roles/                        # Rôles Ansible modulaires
│   ├── bastion/                  # Configuration Nginx
│   ├── webserver/                # Configuration Apache + PHP
│   └── database/                 # Configuration MariaDB + Docker
└── README.md                     # Documentation du projet
```

---

## 🛠️ Dépannage

*   **Erreur SSH** : Vérifiez que votre clé `vockey.pem` a bien les droits `600` et que le chemin est correct dans le fichier `inventory`.
*   **Erreur de connexion DB** : Assurez-vous que l'IP privée du serveur de base de données est correctement configurée dans `roles/webserver/vars/main.yml` et `roles/bastion/vars/main.yml`.
*   **Service indisponible** : Connectez-vous en SSH sur la machine concernée et vérifiez le statut du service (ex: `systemctl status nginx`).


