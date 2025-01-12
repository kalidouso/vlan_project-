#!/bin/bash

# Liste des conteneurs à créer
containers=("switchL3" "switchL2-1" "switchL2-2" "switchL2-3")
ports=(2222 2223 2224 2225)

# Créer et démarrer les conteneurs
for i in ${!containers[@]}; do
    container=${containers[$i]}
    port=${ports[$i]}

    # Vérifier si le conteneur existe déjà
    if [ "$(docker ps -aq -f name=^/${container}$)" ]; then
        echo "Container ${container} already exists. Skipping creation."
    else
        echo "Creating and starting container: ${container} on port ${port}..."
        docker run -d -p ${port}:22 --name ${container} alpine sh -c "while :; do sleep 10; done"
    fi
done

# Configurer SSH et les fonctions réseau dans chaque conteneur
for container in "${containers[@]}"; do
    echo "Configuring SSH and network for container: ${container}"
    docker exec ${container} sh -c "
        # Installer OpenSSH
        apk update &&
        apk add --no-cache openssh &&
        
        # Configurer les répertoires nécessaires
        mkdir -p /var/run/sshd &&
        
        # Créer un utilisateur 'ansible'
        if ! id -u ansible >/dev/null 2>&1; then
            adduser -D -s /bin/sh ansible &&
            echo 'ansible:password' | chpasswd &&
            mkdir -p /home/ansible/.ssh &&
            chmod 700 /home/ansible/.ssh &&
            chown -R ansible:ansible /home/ansible/.ssh
        fi &&
        
        # Générer les clés hôtes SSH
        ssh-keygen -A &&
        
        # Modifier la configuration SSH
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config &&
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config &&
        
        # Activer le routage IP (uniquement pour le switch L3)
        if [ \"${container}\" = \"switchL3\" ]; then
            echo 1 > /proc/sys/net/ipv4/ip_forward &&
            iptables -P FORWARD ACCEPT &&
            echo 'Enabled IP routing on switchL3.'
        fi &&
        
        # Démarrer le serveur SSH
        /usr/sbin/sshd
    "
done

echo "Infrastructure setup completed!"

