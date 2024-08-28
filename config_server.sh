#!/bin/bash

# Ajout d'un nouvel utilisateur
echo -n "Entrez le nom du nouvel utilisateur: "
read username
adduser --disabled-password --gecos "" $username
usermod -aG users $username

# Changement du port SSH
echo -n "Entrez le nouveau port SSH (par défaut: 2222): "
read ssh_port
ssh_port=${ssh_port:-2222}

# Vérification si le fichier de configuration SSH existe
if [ -f /etc/ssh/sshd_config ]; then
    sed -i "s/^#Port 22/Port $ssh_port/" /etc/ssh/sshd_config
    systemctl restart ssh 2>/dev/null || echo "Erreur lors du redémarrage du service SSH. Vérifiez le nom du service."
else
    echo "Le fichier de configuration SSH n'existe pas."
fi

# Mise à jour du système et installation des paquets nécessaires
apt update && apt upgrade -y

# Installation de Rsync
apt install -y rsync

# Installation de Fail2Ban
apt install -y fail2ban

# Installation de cron-apt
apt install -y cron-apt

# Installation de Portsentry
echo -n "Souhaitez-vous installer Portsentry pour la détection des intrusions ? (o/n): "
read install_portsentry
if [ "$install_portsentry" = "o" ]; then
    apt install -y portsentry
fi

# Vérification et installation de Postfix
if [ ! -f /etc/postfix/main.cf ]; then
    apt install -y postfix
    cp /usr/share/postfix/main.cf.debian /etc/postfix/main.cf
    echo "Postfix a été configuré avec le fichier par défaut."
else
    echo "Postfix est déjà configuré."
fi

# Vérification et démarrage du service Postfix
if systemctl list-units --type=service | grep -q postfix.service; then
    if ! systemctl is-active --quiet postfix; then
        systemctl start postfix
    fi
    systemctl reload postfix
else
    echo "Le service Postfix n'est pas installé ou configuré correctement."
fi

# Fin de la configuration
echo "Configuration terminée. N'oubliez pas de tester les accès SSH et les autres services."
