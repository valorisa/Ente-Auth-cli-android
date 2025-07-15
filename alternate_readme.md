# Script Bash de génération de codes TOTP depuis une exportation Ente Auth


Ce document explique pas à pas comment exporter, décrypter, nettoyer et générer à la demande vos codes TOTP en ligne de commande à partir d'une exportation Ente Auth.


---


## Sommaire

- [Prérequis](#prérequis)

- [1. Export de vos codes depuis Ente Auth](#1-export-de-vos-codes-depuis-ente-auth)

- [2. Déchiffrement du fichier exporté](#2-déchiffrement-du-fichier-exporté)

- [3. Utilisation et personnalisation du script Bash](#3-utilisation-et-personnalisation-du-script-bash)

- [4. Affichage des codes à la demande](#4-affichage-des-codes-à-la-demande)

- [5. Astuces : affichage en temps réel & sécurité](#5-astuces--affichage-en-temps-réel--sécurité)

- [6. Pour aller plus loin](#6-pour-aller-plus-loin)


---


## Prérequis


- [x] `ente-cli` installé  

- [x] `oathtool` (GNU oathtool)  

- [x] `python3`  

- [x] Bash


---


## 1. Export de vos codes depuis Ente Auth


### Depuis l'application mobile


Exporter dans :  

**Settings → Data → Export Codes → Ente Encrypted Export**


### Ou depuis un terminal


```

ente auth export --output ente-export.json

```


---


## 2. Déchiffrement du fichier exporté


Pour extraire les secrets lisibles :


```

ente auth decrypt ente-export.json export.txt

```


Vous obtenez un fichier contenant des lignes `otpauth://totp/...`.


---


## 3. Utilisation et personnalisation du script Bash


### Exemple de script : `script_clean.sh`


```

#!/bin/bash


INPUT="export.txt"


while IFS= read -r line; do

    label=$(echo "$line" | sed -n 's|.*totp/$$[^?]*$$?.*|\1|p' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))")

    label=$(echo "$label" | sed 's/^[[:space:]:]*//;s/[[:space:]:]*$//')

    secret=$(echo "$line" | grep -oP 'secret=\K[^&]*')

    if [[ -z "$label" ]] || [[ -z "$secret" ]]; then

        continue

    fi

    secret=$(echo "$secret" | tr -d ' ' | tr 'a-z' 'A-Z')

    if [[ ! "$secret" =~ ^[A-Z2-7]+=*$ ]]; then

        printf "%-35s : [secret Base32 invalide]\n" "$label"

        continue

    fi

    code=$(oathtool --totp -b "$secret" 2>/dev/null)

    if [[ "$code" =~ ^[0-9]{6}$ ]]; then

        printf "%-35s : %s\n" "$label" "$code"

    else

        printf "%-35s : [secret invalide]\n" "$label"

    fi

done < "$INPUT"

```


Rends le script exécutable :


```

chmod +x script_clean.sh

```


---


## 4. Affichage des codes à la demande


Pour obtenir tous les codes TOTP actuels :


```

clear && bash script_clean.sh && cat resultats_clean.txt

```


**Exemple de sortie :**


```

GitHub: username                    : 693174

Microsoft: username@hotmail.com     : 421703

SFTPGo:Admin "admin"                : 759021

Yahoo: username@yahoo.com           : 002398

```


---


## 5. Astuces : affichage en temps réel & sécurité


### Affichage automatique toutes les 30 secondes


```

watch -n 30 ./script_clean.sh

```


### Sécuriser votre export


Chiffrer le fichier exporté :


```

gpg -c export.txt

```


---


## 6. Pour aller plus loin


- **Import dans un gestionnaire de mots de passe** : convertir en CSV (nom, secret)

- **Recréation de QR codes** : utilitaires comme `qrencode` ou scripts Python

- **Stockage dans une YubiKey** : possible via outils de programmation et CSV adapté


---


## Liens utiles


- [Ente Auth CLI](https://github.com/ente-io/cli)

- [oathtool (GNU)](https://www.nongnu.org/oath-toolkit/)

- [RFC 6238 - TOTP](https://datatracker.ietf.org/doc/html/rfc6238)


---


*Réalisé pour sécuriser et automatiser la récupération de vos codes 2FA depuis les exports de l’application Ente Auth.*

```
