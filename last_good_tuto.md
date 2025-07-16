# Générer et Consulter ses Codes TOTP depuis un Export Ente : Procédure pas à pas

> **Contexte :**
>
> Ce tutoriel détaille la manière d’extraire puis de générer dynamiquement, depuis un environnement Ubuntu 24.04, les codes TOTP pour tous tes comptes à partir d’un fichier exporté et déchiffré provenant d’Ente (fichier d’URLs otpauth). Il respecte les bonnes pratiques de sécurité Terminal et fonctionne sur tout système compatible bash et oathtool.

---

## Pré-requis

- **Ubuntu 24.04** (ou tout système compatible Bash)
- **Ente CLI** utilisé pour exporter et déchiffrer les authentificateurs (TOTP)
- **oathtool** installé (`sudo apt install oathtool`)
- Un fichier `codes-dechiffres.txt` contenant tes liens otpauth déchiffrés

---

## 1. Installer oathtool (si besoin)

```
sudo apt update
sudo apt install oathtool
```

---

## 2. Structure attendue du fichier exporté

Le fichier `codes-dechiffres.txt` issu d’Ente contient une ligne par compte, de la forme :
```
otpauth://totp/PROVIDER:LOGIN?secret=BASE32SECRET&issuer=PROVIDER...
```
Exemple :
```
otpauth://totp/GitHub:monlogin?secret=JBSWY3DPEHPK3PXP&issuer=GitHub
```

---

## 3. Générer et afficher tous les codes TOTP en ligne de commande

Crée ce script `generate-totps.sh` :

```
#!/bin/bash
grep 'otpauth://' codes-dechiffres.txt | while read -r line; do
  label=$(echo "$line" | sed -n 's|.*totp/$$[^?]*$$?secret=.*|\1|p' | \
    sed -e 's/%20/ /g' -e 's/%5B/[/g' -e 's/%5D/]/g' -e 's/%22/"/g' -e 's/%3A/:/g')
  secret=$(echo "$line" | sed -n 's/.*secret=$$[^&]*$$.*/\1/p' | sed 's/%3D/=/g')
  if echo "$secret" | grep -Eq '^[A-Z2-7]+=*$'; then
    code=$(oathtool -b --totp "$secret")
    printf "%-40s %s\n" "$label" "$code"
  else
    printf "%-40s %s\n" "$label" "[INVALID SECRET]"
  fi
done
```

Sauvegarde-le, rends-le exécutable :
```
chmod +x generate-totps.sh
```

---

## 4. Utilisation

Pour voir tous tes codes TOTP actuels, depuis le dossier où se trouve `codes-dechiffres.txt` & `generate-totps.sh` :

```
./generate-totps.sh
```

Chaque ligne “service : identifiant” → code temporaire (valide 30s).

---

## 5. Bonus : Afficher seulement un compte précis

Pour n’afficher que le token TOTP de GitHub par exemple :
```
grep -i 'otpauth://totp/GitHub' codes-dechiffres.txt | sed -n 's/.*secret=$$[^&]*$$.*/\1/p' | xargs -I{} oathtool -b --totp {}
```

---

## 6. Sécurité

- **Jamais de mot de passe en clair sur la ligne de commande** : Ente CLI propose un prompt invisible lors du déchiffrement.
- **Tes secrets TOTP ne doivent jamais être partagés ni exposés accidentellement.**
- N’oublie pas de supprimer ou chiffrer les fichiers temporaires après usage.

---

## 7. Notes

- Pour exporter dans un autre format (KeePassXC, Aegis...), consulte la documentation officielle de l’application cible ou demande une conversion automatique (scripts disponibles sur demande).
- Le script est conçu pour des fichiers “otpauth://” standards, générés par Ente ou des apps compatibles.

---

*Fichier généré : last_good_tuto.md – Documentation pratique Ente CLI TOTP, version du 16/07/2025*
