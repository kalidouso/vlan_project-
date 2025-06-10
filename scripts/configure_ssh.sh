#!/bin/bash

# Déclaration des conteneurs et ports SSH
containers=("switchL3" "switchL2-1" "switchL2-2" "switchL2-3")
ports=(2221 2222 2223 2224)

# Création ou configuration de chaque conteneur
for i in "${!containers[@]}"; do
    container=${containers[$i]}
    port=${ports[$i]}

    echo "➡️  Traitement du conteneur : ${container}"

    # Vérifie si le conteneur existe
    if [ "$(docker ps -aq -f name=^/${container}$)" ]; then
        if [ "$(docker ps -q -f name=^/${container}$)" ]; then
            echo "✅ ${container} est déjà en cours d'exécution."
        else
            echo "🔄 ${container} existe mais est arrêté. Démarrage..."
            docker start "$container"
            sleep 2
        fi
    else
        echo "🚀 Création du conteneur ${container} (SSH sur port ${port})..."
        docker run -d \
            -p ${port}:22 \
            --name "$container" \
            --privileged \
            frrouting/frr \
            /bin/sh -c "while :; do sleep 10; done"
        sleep 2
    fi

    echo "⚙️  Configuration de SSH + FRRouting sur ${container}..."

    docker exec "$container" sh -c '
        apk update &&
        apk add --no-cache openssh frr &&
        mkdir -p /var/run/sshd /etc/frr &&

        # Nettoyage PID pour éviter les conflits
        rm -rf /var/tmp/frr/* /var/run/frr/*.pid

        # Ajout utilisateur ansible si absent
        if ! id -u ansible >/dev/null 2>&1; then
            adduser -D -s /bin/sh ansible &&
            echo "ansible:password" | chpasswd &&
            mkdir -p /home/ansible/.ssh &&
            chmod 700 /home/ansible/.ssh &&
            chown -R ansible:ansible /home/ansible/.ssh
        fi

        # Configuration SSH
        ssh-keygen -A
        sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config
        sed -i "s/#PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config
        /usr/sbin/sshd

        # Configuration FRR / vtysh
        echo "service integrated-vtysh-config" > /etc/frr/vtysh.conf
        chown frr:frr /etc/frr/vtysh.conf

        echo "zebra=yes" > /etc/frr/daemons
        echo "ospfd=yes" >> /etc/frr/daemons

        # Lancement manuel des démons nécessaires
        /usr/lib/frr/zebra -d
        /usr/lib/frr/ospfd -d
    '

    echo "✅ ${container} configuré avec succès."
    echo "--------------------------------------------"
done

echo "🎉 Tous les conteneurs sont prêts à l’usage."

