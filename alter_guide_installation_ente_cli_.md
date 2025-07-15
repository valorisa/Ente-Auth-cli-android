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

## Sécurité

- Ne partagez jamais publiquement votre fichier `secrets.txt`
- Supprimez-le après usage si besoin :

    ```shell
    shred -u secrets.txt
    ```

- Ne le versionnez jamais (ajoutez-le à `.gitignore` si dans un dépôt Git)

---

*Fin du guide `alter_guide_installation_ente_cli.md`*
