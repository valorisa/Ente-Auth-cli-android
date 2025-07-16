Voici comment lancer et utiliser `ente-cli` avec la méthode **Docker via Alpine Linux émulé en QEMU**, totalement depuis Termux sous Android, selon la documentation et les scripts open source adaptés à ce cas d’usage[1][2][3][6][8].

## Installer et utiliser ente-cli via Alpine Linux QEMU-isé et Docker dans Termux Android

### 1. Prérequis

- **Termux** installé depuis F-Droid
- **Bon espace de stockage** (prévoir >4 Go pour l’image QEMU + conteneurs)
- **Connexion internet rapide**  
- Matériel : plus le téléphone est puissant (RAM/CPU), plus l’expérience sera fluide (mais, attendez-vous à des lenteurs)

### 2. Installer les outils dans Termux

```bash
pkg update && pkg upgrade -y
pkg install git wget curl tar qemu-system-x86_64-headless qemu-utils proot -y
```

### 3. Récupérer un script d’installation clé en main (option recommandée)

Exemple : [docker-qemu-arm/termux-setup.sh](https://github.com/egandro/docker-qemu-arm)[6][8]

```bash
curl -o termux-setup.sh https://raw.githubusercontent.com/egandro/docker-qemu-arm/master/termux-setup.sh
chmod +x termux-setup.sh
./termux-setup.sh
```
- Ce script va configurer une image Alpine x86-64, QEMU, ZRAM, et Docker côté Alpine.

**Alternative manuelle** :  
- Télécharge l’ISO Alpine virtuel [2] :  
  ```bash
  mkdir $HOME/alpine-qemu
  cd $HOME/alpine-qemu
  wget https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-virt-3.19.1-x86_64.iso
  ```

- Crée le disque pour la VM et lance l'installation avec QEMU (voir [2][6][8] pour un script détaillé).

### 4. Démarrer Alpine Linux dans QEMU

```bash
cd $HOME/alpine-qemu
qemu-system-x86_64 -smp 2 -m 2048 \
  -boot d \
  -cdrom alpine-virt-3.19.1-x86_64.iso \
  -drive file=alpine.qcow2,if=virtio \
  -netdev user,id=n1,hostfwd=tcp::2222-:22 \
  -device virtio-net,netdev=n1 \
  -nographic
```
(Adapte la RAM et le port selon la puissance de ton appareil.)

- **Astuce** : tu peux aussi utiliser [start-qemu.sh](https://github.com/P1N2O/qemu-termux-alpine/blob/main/start-qemu.sh)[6] fourni avec certains dépôts.

### 5. Installer Docker dans Alpine Linux

Dans la VM Alpine, installe Docker :

```sh
apk update
apk add docker curl tar shadow
addgroup docker
rc-update add docker boot
service docker start
```

Optionnel : change le mot de passe root (par défaut, root sans mot de passe sur install live).

### 6. Télécharger et lancer ente-cli via Docker

Toujours dans Alpine (avec Docker fonctionnel) :

- Crée un Dockerfile pour `ente-cli` dans `/root` (ou lance avec `docker run` direct si une image existe).

**Exemple Dockerfile à placer dans Alpine VM** :

```Dockerfile
FROM alpine:3.22

RUN apk add --no-cache curl tar oathtool ca-certificates

WORKDIR /app

RUN curl -LO https://github.com/ente-io/tools/releases/download/cli-v0.2.3/ente-cli-v0.2.3-linux-amd64.tar.gz \
    && tar -xvzf ente-cli-v0.2.3-linux-amd64.tar.gz \
    && mv ente ente-cli \
    && chmod +x ente-cli

ENTRYPOINT [ "/app/ente-cli" ]
```

- Build et lance :
  ```sh
  docker build -t ente-cli /app
  docker run --rm -it -v /root/data:/data ente-cli auth decrypt /data/ente-auth-codes-xxxx.txt /data/secrets.txt
  ```

*(Montez le dossier `/data` avec vos fichiers à déchiffrer depuis Termux ou un partage réseau)*

### 7. Récupérer les résultats

- Les fichiers déchiffrés sont accessibles dans le volume bindé (`/data` ci-dessus).  
- Vous pouvez alors générer vos codes TOTP depuis Alpine (avec oathtool) ou rapatrier le fichier `secrets.txt` dans Termux.

### 8. Documentation et ressources

- Script clé en main (install, démarrage, ssh, maintenance) :
  - https://github.com/P1N2O/qemu-termux-alpine[6]
  - https://github.com/egandro/docker-qemu-arm[8]
  - https://github.com/diogok/termux-qemu-alpine-docker[3][7]

*Astuce : ces scripts proposent souvent des helpers pour SSH dans la VM, démarrage/arrêt rapide, gestion de la mémoire (zram), etc.*

### Points importants

- **Performance** : cette solution est fun, hacky, mais très lente sur la plupart des appareils mobiles.
- **Sécurité** : change le mot de passe root Alpine, configure SSH si ouverture réseau.
- **Alternatives simples** : sur Android non-rooté, le workflow proot-distro/Ubuntu reste plus rapide et léger en ressources.

En résumé, **on peut exécuter Docker, donc n’importe quel outil CLI comme ente-cli, dans Alpine Linux lancé via QEMU depuis Termux sur Android**, à condition d'accepter les temps d’exécution importants et quelques bidouilles réseau/stockage pour récupérer les fichiers[1][2][3][6][8].

Citations :
[1] Running Docker using QEMU on an Android Device - MoToots https://www.motoots.com/2021/03/running-docker-using-qemu-on-android.html
[2] Install Alpine Linux on Termux using QEMU https://github.com/eapolinariov/alpine-linux-on-termux
[3] diogok/termux-qemu-alpine-docker https://github.com/diogok/termux-qemu-alpine-docker
[4] Install Alpine Linux with Qemu on Android | Termux https://www.youtube.com/watch?v=UKaN9sBBB-Y
[5] Running Docker using QEMU on an Android Device https://www.youtube.com/watch?v=RL96VSKzAQo
[6] GitHub - P1N2O/qemu-termux-alpine https://github.com/P1N2O/qemu-termux-alpine
[7] termux-qemu-alpine-docker/README.md at master · diogok/termux-qemu-alpine-docker https://github.com/diogok/termux-qemu-alpine-docker/blob/master/README.md
[8] GitHub - Bitsonwheels/qemu-alpine-docker_on_termux https://github.com/Bitsonwheels/qemu-alpine-docker_on_termux
[9] How can I bridge Termux with Alpine Linux QEMU? https://www.reddit.com/r/termux/comments/16ntaun/how_can_i_bridge_termux_with_alpine_linux_qemu/
[10] How can I optimize QEMU for Termux? https://www.reddit.com/r/termux/comments/1d9dbpl/how_can_i_optimize_qemu_for_termux/
