#!/bin/bash

# Liste des conteneurs à créer
containers=("switchL3" "switchL2-1" "switchL2-2" "switchL2-3")
ports=(2222 2223 2224 2225)

# Créer et configurer les conteneurs
for i in "${!containers[@]}"; do
    container=${containers[$i]}
    port=${ports[$i]}

    # Vérifier si le conteneur existe déjà
    if [ "$(docker ps -aq -f name=^/${container}$)" ]; then
        echo "Container ${container} already exists. Skipping creation."
    else
        echo "Creating and starting container: ${container} on port ${port}..."
        docker run -d -p ${port}:22 --name ${container} --privileged frrouting/frr /bin/sh -c "while :; do sleep 10; done"
    fi

    # Configurer SSH et FRRouting dans chaque conteneur
    echo "Configuring SSH and FRRouting for container: ${container}..."
    docker exec ${container} sh -c "
        # Mettre à jour et installer OpenSSH
        apk update &&
        apk add --no-cache openssh &&
        
        # Créer les répertoires nécessaires pour SSH
        mkdir -p /var/run/sshd &&
        
        # Ajouter un utilisateur 'ansible'
        if ! id -u ansible >/dev/null 2>&1; then
            adduser -D -s /bin/sh ansible &&
            echo 'ansible:password' | chpasswd &&
            mkdir -p /home/ansible/.ssh &&
            chmod 700 /home/ansible/.ssh &&
            chown -R ansible:ansible /home/ansible/.ssh
        fi &&
        
        # Générer les clés hôtes SSH
        ssh-keygen -A &&
        
        # Modifier la configuration SSH pour activer les connexions par mot de passe
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config &&
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config &&
        
        # Démarrer le serveur SSH
        /usr/sbin/sshd &&

        # Activer FRRouting
        /etc/init.d/frr start
    "
done

echo "All containers are configured and running."

