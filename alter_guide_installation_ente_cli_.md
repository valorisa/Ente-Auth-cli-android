# Guide alternatif d'installation et d'utilisation de `ente-cli` sur Termux (Android)

Ce guide décrit de manière complète comment:

- Exporter vos codes 2FA chiffrés depuis l'application **Ente Auth** sur smartphone
- Installer et utiliser `ente-cli` dans un environnement Ubuntu sous **Termux via `proot-distro`**
- Déchiffrer vos tokens depuis la ligne de commande
- Générer vos codes TOTP manuellement

## Prérequis

- Application **Termux** installée (via [F-Droid](https://f-droid.org))
- Disposer d’une **connexion Internet**
- Avoir installé `proot-distro` sur Termux :
  
  ```shell
  pkg install proot-distro
  ```

- Télécharger et installer **Ubuntu** dans Termux :

  ```shell
  proot-distro install ubuntu
  ```

## Étape 1 - Export depuis l’application Ente Auth (smartphone)

1. **Ouvrez l’application Ente Auth sur votre smartphone**.
2. Appuyez sur les trois points (menu) > Sélectionnez **Exporter**.
3. Cochez **Exporter de façon sécurisée (chiffrée)**.
4. Choisissez un **mot de passe fort** (vous en aurez besoin plus tard).
5. Cela génère un fichier `.txt` chiffré (ex : `ente-auth-codes-2025-07-03.txt`).
6. Transférez ce fichier dans votre environnement Termux ou Ubuntu (via `scp`, `termux-storage`, `adb`, etc.).

## Étape 2 - Démarrer Ubuntu dans Termux

```shell
proot-distro login ubuntu
```

Cela vous place dans un environnement Ubuntu isolé.

## Étape 3 - Installation de `ente-cli` dans Ubuntu

1. **Mettre à jour l’environnement** :

    ```shell
    apt update && apt upgrade -y
    ```

2. **Installer les outils nécessaires** :

    ```shell
    apt install -y curl tar gnupg oathtool coreutils
    ```

3. **Télécharger et installer `ente-cli`** (ex. pour l’architecture `linux-arm64`) :

    ```shell
    curl -LO https://github.com/ente-io/tools/releases/download/cli-v0.2.3/ente-cli-v0.2.3-linux-arm64.tar.gz
    tar -xvzf ente-cli-v0.2.3-linux-arm64.tar.gz
    mv ente ente-cli
    chmod +x ente-cli
    ```

4. **Vérifiez que cela fonctionne** :

    ```shell
    ./ente-cli version
    ```

## Étape 4 - Déchiffrement des secrets Ente Auth

Placez le fichier exporté (`ente-auth-codes-XXXX.txt`) dans le même répertoire que `ente-cli`, puis exécutez :

```shell
./ente-cli auth decrypt ente-auth-codes-2025-07-03.txt secrets.txt
```

Vous serez invité à entrer le **mot de passe utilisé lors de l’export** dans l’application.

- En cas de succès, le fichier `secrets.txt` sera créé, contenant vos tokens au format `otpauth://`.

## Étape 5 - Génération manuelle de codes TOTP

1. **Lister vos secrets** :

    ```shell
    cat secrets.txt
    ```

2. **Exemple de ligne otpauth** :

    ```text
    otpauth://totp/Yahoo:username@yahoo.com?secret=XXXXXXXX&issuer=Yahoo
    ```

3. **Générer un code** :

    ```shell
    oathtool --totp -b XXXXXXXXX
    ```

    Cela retourne le code 2FA actuel (valide 30 secondes).

## Optionnel - Script Bash pour TOTP

Crée un fichier `totp.sh` contenant :

```shell
#!/bin/bash
grep -i "$1" secrets.txt | grep -o 'secret=[^&]*' | cut -d= -f2 | while read secret
do
  echo -n "$1: "
  oathtool --totp -b "$secret"
done
```

Rendez-le exécutable :

```shell
chmod +x totp.sh
```

Utilisation :

```shell
./totp.sh GitHub
./totp.sh all  # (si vous adaptez le script pour tout lister)
```

Ou encore : 

Présence de **plusieurs secrets TOTP** dans `secrets.txt`, chacun au format `otpauth://...`.

Voici un moyen simple de les exploiter efficacement avec un script bash qui :

- Liste tous les services disponibles
- Te permet de **générer un TOTP pour un service donné**
- Ou tous d’un coup

### **Script : `totp.sh`**

```bash
#!/bin/bash

SECRETS_FILE="secrets.txt"

if [ ! -f "$SECRETS_FILE" ]; then
  echo "Fichier $SECRETS_FILE introuvable."
  exit 1
fi

if [ -z "$1" ]; then
  echo "Utilisation : $0 <NomDuService> ou 'all' pour tous"
  exit 1
fi

if [ "$1" == "all" ]; then
  grep -o 'otpauth://[^ ]*' "$SECRETS_FILE" | while read -r line; do
    NAME=$(echo "$line" | cut -d ':' -f 3 | cut -d '?' -f 1)
    SECRET=$(echo "$line" | grep -o 'secret=[^&]*' | cut -d= -f2)
    CODE=$(oathtool --totp -b "$SECRET")
    echo "$NAME: $CODE"
  done
else
  MATCHES=$(grep -i "$1" "$SECRETS_FILE" | grep -o 'otpauth://[^ ]*')
  if [ -z "$MATCHES" ]; then
    echo "Aucun secret trouvé pour $1"
    exit 1
  fi

  echo "$MATCHES" | while read -r line; do
    NAME=$(echo "$line" | cut -d ':' -f 3 | cut -d '?' -f 1)
    SECRET=$(echo "$line" | grep -o 'secret=[^&]*' | cut -d= -f2)
    CODE=$(oathtool --totp -b "$SECRET")
    echo "$NAME: $CODE"
  done
fi
```

### **Utilisation :**

```bash
chmod +x totp.sh

# Pour un service donné (ex: "GitHub")
./totp.sh GitHub

# Pour tous les comptes 2FA
./totp.sh all
```

### **Résultat attendu :**

```text
GitHub: 839201
Google: 120398
Yahoo: 997722
```

## Sécurité

- Ne partagez jamais publiquement votre fichier `secrets.txt`
- Supprimez-le après usage si besoin :

    ```shell
    shred -u secrets.txt
    ```

- Ne le versionnez jamais (ajoutez-le à `.gitignore` si dans un dépôt Git)

## Conclusion 

Comparer les codes générés par un script `Totp.sh` et ceux de l’application mobile Ente Auth est la meilleure méthode rigoureuse pour vérifier la justesse de la génération TOTP.

Ce que l’on constate confirme ce que détaillent les ressources :  
Ente Auth (mobile ou CLI) est une application conforme au standard **TOTP** (*Time-based One-Time Password*).

Le code à 6 chiffres est calculé à partir du **secret partagé** et de l’heure courante, renouvelé toutes les 30 secondes.

Tant que l’heure du système Android et celle de l’environnement Ubuntu sous Termux restent bien synchronisées (il suffit que les appareils soient réglés automatiquement), les codes générés seront toujours identiques : ils se basent strictement sur la même clé et le même timestamp.

Cela montre ainsi que :

- **L’interopérabilité** entre Ente Auth mobile et les outils CLI est parfaite pour le TOTP : on peut générer les mêmes codes sur son smartphone et sur son environnement Ubuntu/Termux, en toute sécurité.
- La restitution depuis un **backup chiffré Ente Auth**, puis l’usage de `oathtool` (ou équivalent), reproduit exactement ce que fait l’application mobile.
- Cette **vérification de cohérence entre plateformes** est en phase avec les recommandations de sécurité modernes : on peut restaurer ou migrer ses secrets 2FA tout en gardant la maîtrise totale sur ses accès, même en cas de perte ou changement d’appareil.

---

*Fin du guide `alter_guide_installation_ente_cli.md`*
