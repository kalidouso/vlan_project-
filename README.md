# README du Projet de Configuration de Réseau

Ce projet vise à déployer et configurer une infrastructure réseau basée sur Docker et Ansible, tout en intégrant la gestion des VLANs.

---

## Prérequis

Avant de démarrer, assurez-vous que les éléments suivants sont disponibles et configurés :

1. **Docker** installé sur l'hôte.
2. **Ansible** installé pour l'exécution des playbooks.
3. Les fichiers essentiels présents dans votre environnement de travail :
   - `configuration_initiale.sh`
   - `inventory.ini`
   - `playbooks/configuration_vlans.yml`
   - `vars/vlans.yml`
4. Un accès administrateur (root) ou des privilèges sudo adéquats.

---

## Étape 1 : Exécution du Script Initial

Le script `configuration_ssh.sh` a pour objectif :

- La création et la configuration de conteneurs Docker dédiés aux fonctions de routage et de commutation.
- La mise en place des démons FRRouting (« zebra » et « ospfd »).
- La configuration de l’accès SSH et d’un utilisateur Ansible doté des privilèges requis.
- Configurer tous ce qu'il y a à configurer pour empêcher les bugs ou erreurs.

### Instructions pour l’exécution

Pour exécuter ce script, saisissez la commande suivante dans le terminal :

```bash
bash configuration_initiale.sh
```

Ce script assure la création des conteneurs, la configuration des services SSH et sudo, ainsi que l'activation des démons, ce qui est souvent problématique car le version initiale téléchargée de ffrouting ne l'assure pas.

---

## Étape 2 : Configuration des VLANs

Après la mise en place des conteneurs, Ansible est utilisé pour configurer les VLANs conformément aux spécifications définies.

### Contenu du fichier `vars/vlans.yml`

Le fichier `vars/vlans.yml` décrit les détails des VLANs à configurer :

```yaml
vlans:
  - id: 10
    ip: "192.168.1.10/24"
    name: "Administration"
    subnet: "192.168.1.0/24"
  - id: 20
    ip: "192.168.2.10/24"
    name: "Production"
    subnet: "192.168.2.0/24"
  - id: 30
    ip: "192.168.3.10/24"
    name: "Developpement"
    subnet: "192.168.3.0/24"
  - id: 40
    ip: "192.168.4.10/24"
    name: "Invites"
    subnet: "192.168.4.0/24"
```

### Exécution du Playbook Ansible

Pour appliquer les configurations définies :

```bash
ansible-playbook -i inventory.ini playbooks/configuration_vlans.yml
```

Ce playbook permet :

1. La configuration des interfaces réseau des conteneurs.
2. L’association des ports aux VLANs spécifiés dans `vars/vlans.yml`.
3. Le routage inter-vlan.

---

## Étape 3 : Validation

Une fois les configurations déployées, procédez aux vérifications suivantes :

1. Assurez-vous que tous les conteneurs sont en cours d’exécution :
   ```bash
   docker ps
   ```
2. Testez la connectivité SSH avec les commandes suivantes :
   ```bash
   ssh ansible@<adresse_ip> -p <port>
   ```
3. Vérifiez que les VLANs sont correctement configurés en exécutant les commandes appropriées dans les conteneurs concernés avec vtysh ( qui est très compliqué à configurer, donc autant en profiter !! ).

4. ```vtysh
   show running-config
   ou show ip-route
   ``
---






Pour modifier la structure réseau existante, suivez ces étapes :

1. Mettre à jour le fichier inventory.ini :
-  Ajoutez les nouveaux hôtes (conteneurs) dans le fichier inventory.ini.
-  Assurez-vous d'inclure les noms des conteneurs et les numéros de ports associés.

2. Modifier le script configuration_initiale.sh :
-  Incluez les noms des nouveaux conteneurs et les ports correspondants dans la liste des conteneurs et des ports du script.
-  Cela garantit que les nouveaux conteneurs seront pris en charge lors de l’exécution du script.

3. Ajuster les VLANs dans vars/vlans.yml :
-  Ajoutez ou supprimez des VLANs en veillant à ce que leurs adresses IP restent accessibles.

Les adresses doivent être conformes au réseau Docker configuré pour éviter tout conflit ou problème de connectivité.

## Conclusion

L’infrastructure réseau est désormais opérationnelle et conforme aux spécifications. 

